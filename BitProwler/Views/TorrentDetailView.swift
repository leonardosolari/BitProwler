import SwiftUI

struct TorrentDetailView: View {
    @StateObject private var viewModel: TorrentDetailViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var showingCopiedAlert = false
    
    private let result: TorrentResult
    
    init(result: TorrentResult, viewModel: TorrentDetailViewModel) {
        self.result = result
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
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
            .alert("Download Avviato", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Il torrent è stato aggiunto con successo a qBittorrent.")
            }
            .alert("Errore", isPresented: .constant(viewModel.error != nil), actions: {
                Button("OK", role: .cancel) { viewModel.error = nil }
            }, message: {
                Text(viewModel.error?.errorDescription ?? "Si è verificato un errore sconosciuto.")
            })
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.title)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if result.downloadUrl != nil {
                Button(action: {
                    Task { await viewModel.downloadTorrent() }
                }) {
                    HStack {
                        if viewModel.isDownloading {
                            ProgressView().tint(.white)
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
                .disabled(viewModel.isDownloading)
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
    
    private func formatSize(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .long, time: .shortened)
        }
        return dateString
    }
}

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