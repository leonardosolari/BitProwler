import SwiftUI

struct TorrentFilesView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var container: AppContainer
    
    @State private var files: [TorrentFile] = []
    @State private var isLoading = false
    
    @State private var expandedFile: TorrentFile?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Caricamento file...")
                } else if files.isEmpty {
                    ContentUnavailableView("Nessun File", systemImage: "doc.questionmark", description: Text("Non è stato possibile trovare i file per questo torrent."))
                } else {
                    List {
                        ForEach(files) { file in
                            TorrentFileRow(file: file, expandedFile: $expandedFile)
                        }
                    }
                }
            }
            .navigationTitle("File del Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .task {
                await fetchFiles()
            }
        }
    }
    
    private func fetchFiles() async {
        guard let server = container.qbittorrentManager.activeQBittorrentServer else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedFiles = try await container.qbittorrentService.getFiles(for: torrent, on: server)
            self.files = fetchedFiles
        } catch {
            print("Error fetching files: \(error.localizedDescription)")
        }
    }
}


struct TorrentFileRow: View {
    let file: TorrentFile
    @Binding var expandedFile: TorrentFile?
    
    private var isExpanded: Bool {
        expandedFile == file
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                FileIconView(filename: file.name)
                
                Text(file.name)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 1) // Logica di espansione
                
                Spacer()
                
                Text(formatSize(file.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            ProgressView(value: file.progress)
                .tint(file.progress >= 1.0 ? .green : .blue)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                expandedFile = isExpanded ? nil : file
            }
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = file.name
            }) {
                Label("Copia Nome File", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}