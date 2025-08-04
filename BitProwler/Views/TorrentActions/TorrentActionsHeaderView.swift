import SwiftUI

struct TorrentActionsHeaderView: View {
    let torrent: QBittorrentTorrent
    
    var body: some View {
        VStack(spacing: 16) {
            Text(torrent.name)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            HStack {
                StatItem(icon: "tray.full.fill", value: formatSize(torrent.size), color: .secondary)
                Spacer()
                StatusBadge(state: torrent.state)
                Spacer()
                // CORREZIONE QUI: Aggiunto il parametro 'color'
                StatItem(icon: "arrow.up.arrow.down.circle.fill", value: String(format: "%.2f", torrent.ratio), color: .secondary)
            }
            
            ProgressView(value: torrent.progress)
                .tint(StatusBadge.getBackgroundColor(for: torrent.state))
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}