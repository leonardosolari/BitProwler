import SwiftUI

struct TorrentDetailView: View {
    let result: TorrentResult
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    @State private var showingCopiedAlert = false
    @State private var downloadError: String?
    @State private var isDownloading = false
    
    private let apiService: QBittorrentAPIService = NetworkManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                contentScrollView
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dettagli Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .alert("Link Copiato!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert(downloadError == nil ? "Download Avviato" : "Errore", isPresented: Binding(
                get: { downloadError != nil || isDownloading },
                set: { if !$0 { downloadError = nil; isDownloading = false } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(downloadError ?? "Il torrent è stato aggiunto con successo a qBittorrent.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.title)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if result.downloadUrl != nil {
                Button(action: {
                    Task { await downloadTorrent() }
                }) {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Aggiungi a qBittorrent")
                        }
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)
                .disabled(isDownloading || qbittorrentManager.activeQBittorrentServer == nil)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statsSection
                detailsSection
                linksSection
            }
            .padding()
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading) {
            Text("Statistiche")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                StatItem(icon: "arrow.up.circle.fill", value: "\(result.seeders)", color: .green)
                Spacer()
                StatItem(icon: "arrow.down.circle.fill", value: "\(result.leechers)", color: .orange)
                Spacer()
                StatItem(icon: "tray.full.fill", value: formatSize(result.size), color: .secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading) {
            Text("Informazioni")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                LabeledContent("Indexer", value: result.indexer)
                Divider()
                LabeledContent("Data Pubblicazione", value: formatDate(result.publishDate))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    private var linksSection: some View {
        VStack(alignment: .leading) {
            Text("Link")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 0) {
                LinkRow(label: "GUID", value: result.id, canOpen: true)
                if result.downloadUrl != nil {
                    Divider()
                    LinkRow(label: "Download Link", value: result.downloadUrl!, canOpen: false)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Logic
    
    private func downloadTorrent() async {
        guard let server = qbittorrentManager.activeQBittorrentServer, let url = result.downloadUrl else {
            handleDownloadError(AppError.serverNotConfigured)
            return
        }
        
        isDownloading = true
        
        do {
            try await apiService.addTorrent(url: url, on: server)
            handleDownloadSuccess()
        } catch {
            handleDownloadError(error)
        }
    }
    
    private func handleDownloadSuccess() {
        self.downloadError = nil
    }
    
    private func handleDownloadError(_ error: Error) {
        self.downloadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.isDownloading = false
    }
    
    // MARK: - Helpers
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .long, time: .shortened)
        }
        return dateString
    }
}

// MARK: - Reusable Subviews

private struct LinkRow: View {
    let label: String
    let value: String
    let canOpen: Bool
    
    @State private var showingCopiedAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = value
                showingCopiedAlert = true
            }) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .alert("Copiato!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
            
            if canOpen, let url = URL(string: value), UIApplication.shared.canOpenURL(url) {
                Button(action: {
                    UIApplication.shared.open(url)
                }) {
                    Image(systemName: "safari")
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}