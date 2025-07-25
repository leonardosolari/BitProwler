import SwiftUI

struct TorrentDetailView: View {
    let result: TorrentResult
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @State private var showingCopiedAlert = false
    @State private var showingDownloadAlert = false
    @State private var downloadError: String?
    @State private var isDownloading = false
    
    var body: some View {
        NavigationView {
            List {
                // Sezione Informazioni
                TorrentInfoSection(result: result)
                
                // Sezione Link Indexer
                IndexerLinkSection(
                    id: result.id,
                    showingCopiedAlert: $showingCopiedAlert
                )
                
                // Sezione Download (se disponibile)
                                if let downloadUrl = result.downloadUrl {
                    DownloadSection(
                        downloadUrl: downloadUrl,
                        isDownloading: $isDownloading,
                        showingCopiedAlert: $showingCopiedAlert,
                        onDownload: { await downloadTorrent(url: downloadUrl) },
                        showQBittorrentButton: qbittorrentManager.activeQBittorrentServer != nil
                    )
                }
            }
            .navigationTitle("Dettagli Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .alert("Link Copiato!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert(downloadError == nil ? "Download Avviato" : "Errore", isPresented: $showingDownloadAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(downloadError ?? "Il torrent è stato aggiunto con successo a qBittorrent")
            }
        }
    }
    
    private func downloadTorrent(url: String) async {
        guard let qbittorrentServer = qbittorrentManager.activeQBittorrentServer else {
            handleDownloadError("Nessun server qBittorrent configurato")
            return
        }
        
        isDownloading = true
        
        // Prima effettua il login
        guard let loginSuccess = await login(server: qbittorrentServer) else {
            handleDownloadError("Errore di connessione al server")
            return
        }
        
        if !loginSuccess {
            handleDownloadError("Login fallito")
            return
        }
        
        // Poi aggiunge il torrent
        guard let downloadUrl = URL(string: "\(qbittorrentServer.url)api/v2/torrents/add") else {
            handleDownloadError("URL non valido")
            return
        }
        
        var request = URLRequest(url: downloadUrl)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"urls\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(url)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    downloadError = nil
                } else {
                    downloadError = "Errore nell'aggiunta del torrent"
                }
                showingDownloadAlert = true
                isDownloading = false
            }
        } catch {
            handleDownloadError(error.localizedDescription)
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
    
    private func handleDownloadError(_ message: String) {
        Task { @MainActor in
            downloadError = message
            showingDownloadAlert = true
            isDownloading = false
        }
    }
}

// MARK: - Componenti Ausiliari

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
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "it_IT")
            return formatter.string(from: date)
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
                    
                    Button(action: {
                        if let url = URL(string: id) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Apri nel Browser", systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
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
            VStack(alignment: .leading, spacing: 8) {
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
                            Label("Aggiungi a qBittorrent", systemImage: "arrow.down.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isDownloading)
                    }
                }
                
                if isDownloading {
                    ProgressView()
                        .padding(.top)
                }
            }
        }
    }
}
