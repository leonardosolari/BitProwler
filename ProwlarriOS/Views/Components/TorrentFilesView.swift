import SwiftUI

struct TorrentFilesView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @State private var files: [TorrentFile] = []
    @State private var isLoading = false
    private let apiService: QBittorrentAPIService = NetworkManager()
    
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
        guard let server = qbittorrentManager.activeQBittorrentServer else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedFiles = try await apiService.getFiles(for: torrent, on: server)
            await MainActor.run { self.files = fetchedFiles }
        } catch {
            print("Error fetching files: \(error.localizedDescription)")
        }
    }

}