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
                StatItem(icon: "tray.full.fill", value: Formatters.formatSize(torrent.size), color: .secondary)
                Spacer()
                
                if torrent.downloadSpeed > 0 {
                    StatItem(icon: "hourglass", value: Formatters.formatETA(torrent.eta), color: .cyan)
                    Spacer()
                }
                
                StatusBadge(state: torrent.state)
                Spacer()
                StatItem(icon: "arrow.up.arrow.down.circle.fill", value: String(format: "%.2f", torrent.ratio), color: .secondary)
            }
            
            ProgressView(value: torrent.progress)
                .tint(StatusBadge.getBackgroundColor(for: torrent.state))
        }
        .padding()
        .background(.regularMaterial)
    }
}