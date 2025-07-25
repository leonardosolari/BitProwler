import SwiftUI

struct TorrentDetailView: View {
    let result: TorrentResult
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    @State private var showingCopiedAlert = false
    @State private var showingDownloadAlert = false
    @State private var downloadError: String?
    @State private var isDownloading = false
    
    // Inietta un'istanza del servizio di rete.
    // Per ora usiamo l'implementazione di default, ma questo rende la vista testabile.
    private let apiService: QBittorrentAPIService = NetworkManager()
    
    var body: some View {
        NavigationView {
            List {
                TorrentInfoSection(result: result)
                
                IndexerLinkSection(
                    id: result.id,
                    showingCopiedAlert: $showingCopiedAlert
                )
                
                if let downloadUrl = result.downloadUrl {
                    DownloadSection(
                        downloadUrl: downloadUrl,
                        isDownloading: $isDownloading,
                        showingCopiedAlert: $showingCopiedAlert,
                        onDownload: {
                            await downloadTorrent(url: downloadUrl)
                        },
                        showQBittorrentButton: qbittorrentManager.activeQBittorrentServer != nil
                    )
                }
            }
            .navigationTitle("Dettagli Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .alert("Link Copiato!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert(downloadError == nil ? "Download Avviato" : "Errore", isPresented: $showingDownloadAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(downloadError ?? "Il torrent è stato aggiunto con successo a qBittorrent.")
            }
        }
    }
    
    private func downloadTorrent(url: String) async {
        guard let server = qbittorrentManager.activeQBittorrentServer else {
            handleDownloadError(AppError.serverNotConfigured)
            return
        }
        
        isDownloading = true
        defer { isDownloading = false }
        
        do {
            try await apiService.addTorrent(url: url, on: server)
            handleDownloadSuccess()
        } catch {
            handleDownloadError(error)
        }
    }
    
    private func handleDownloadSuccess() {
        self.downloadError = nil
        self.showingDownloadAlert = true
    }
    
    private func handleDownloadError(_ error: Error) {
        self.downloadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.showingDownloadAlert = true
    }
}

// MARK: - Componenti Ausiliari (invariati)

private struct TorrentInfoSection: View {
    let result: TorrentResult
    
    var body: some View {
        Section(header: Text("Informazioni")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(result.title)
                    .font(.headline)
                Text("Dimensione: \(formatSize(result.size))")
                Text("Indexer: \(result.indexer)")
                Text("Data: \(formatDate(result.publishDate))")
                HStack {
                    Image(systemName: "arrow.up.circle")
                        .foregroundColor(.green)
                    Text("\(result.seeders)")
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.red)
                    Text("\(result.leechers)")
                }
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

private struct IndexerLinkSection: View {
    let id: String
    @Binding var showingCopiedAlert: Bool
    
    var body: some View {
        Section(header: Text("Pagina Indexer")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(id)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                
                HStack {
                    Button(action: {
                        UIPasteboard.general.string = id
                        showingCopiedAlert = true
                    }) {
                        Label("Copia Link", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    
                    if let url = URL(string: id), UIApplication.shared.canOpenURL(url) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Label("Apri nel Browser", systemImage: "safari")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}

private struct DownloadSection: View {
    let downloadUrl: String
    @Binding var isDownloading: Bool
    @Binding var showingCopiedAlert: Bool
    let onDownload: () async -> Void
    let showQBittorrentButton: Bool
    
    var body: some View {
        Section(header: Text("Download")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(downloadUrl)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                
                HStack {
                    Button(action: {
                        UIPasteboard.general.string = downloadUrl
                        showingCopiedAlert = true
                    }) {
                        Label("Copia Link", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    
                    if showQBittorrentButton {
                        Button(action: {
                            Task {
                                await onDownload()
                            }
                        }) {
                            if isDownloading {
                                ProgressView()
                                    .frame(height: 14) // Allinea l'altezza con il testo
                            } else {
                                Label("Aggiungi a qBittorrent", systemImage: "arrow.down.circle")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isDownloading)
                    }
                }
            }
        }
    }
}