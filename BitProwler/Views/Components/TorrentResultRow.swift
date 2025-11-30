import SwiftUI

struct TorrentResultRow: View {
    let result: TorrentResult
    @State private var showingDetail = false
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatItem(icon: "arrow.up.circle.fill", value: "\(result.seeders)", color: .green)
                    StatItem(icon: "arrow.down.circle.fill", value: "\(result.leechers)", color: .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatItem(icon: "tray.full.fill", value: formatSize(result.size), color: .secondary)
                    
                    Text(result.indexer)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }
            .font(.footnote)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            let viewModel = TorrentDetailViewModel(
                result: result,
                qbittorrentManager: container.qbittorrentManager,
                apiService: container.qbittorrentService
            )
            TorrentDetailView(result: result, viewModel: viewModel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("torrent_result_row_\(result.id)")
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}