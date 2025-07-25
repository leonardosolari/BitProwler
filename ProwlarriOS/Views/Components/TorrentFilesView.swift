import SwiftUI

struct TorrentFilesView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @State private var files: [TorrentFile] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                } else if files.isEmpty {
                    Text("Nessun file disponibile")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(files) { file in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(file.name)
                                .lineLimit(1)
                            HStack {
                                ProgressView(value: file.progress)
                                    .tint(.blue)
                                Text(formatSize(file.size))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .task {
                await fetchFiles()
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func fetchFiles() async {
        guard let server = qbittorrentManager.activeQBittorrentServer else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        guard let loginSuccess = await login(server: server) else {
            return
        }
        
        if !loginSuccess {
            return
        }
        
        guard let url = URL(string: "\(server.url)api/v2/torrents/files?hash=\(torrent.hash)") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                await MainActor.run {
                    self.files = jsonArray.map { TorrentFile(from: $0) }
                }
            }
        } catch {
            print("Error fetching files: \(error)")
        }
    }
    
    private func login(server: QBittorrentServer) async -> Bool? {
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(server.username)&password=\(server.password)"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}