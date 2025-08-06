import SwiftUI

struct TorrentActionsHeaderView: View {
    let torrent: QBittorrentTorrent
    
    var body: some View {
        VStack(spacing: 20) {
            Text(torrent.name)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 15) {
                GridRow {
                    VStack(alignment: .leading) {
                        Label("State", systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        StatusBadge(state: torrent.state)
                    }
                    
                    VStack(alignment: .leading) {
                        let torrentState = TorrentState(from: torrent.state)
                        if torrent.downloadSpeed > 0 && (torrentState == .downloading || torrentState == .stalledDL || torrentState == .forcedDL || torrentState == .metaDL) {
                            Label("Download Speed", systemImage: "arrow.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(Formatters.formatSpeed(torrent.downloadSpeed))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        } else if torrent.uploadSpeed > 0 && (torrentState == .uploading || torrentState == .stalledUP || torrentState == .forcedUP) {
                            Label("Upload Speed", systemImage: "arrow.up")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(Formatters.formatSpeed(torrent.uploadSpeed))
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Label("Speed", systemImage: "speedometer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("—")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                GridRow {
                    VStack(alignment: .leading) {
                        Label("Size", systemImage: "tray.full.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Formatters.formatSize(torrent.size))
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading) {
                        Label("Time Remaining", systemImage: "hourglass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if torrent.downloadSpeed > 0 {
                            Text(Formatters.formatETA(torrent.eta))
                                .fontWeight(.semibold)
                        } else {
                            Text("—")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ProgressView(value: torrent.progress)
                    .tint(StatusBadge.getBackgroundColor(for: torrent.state))
                
                HStack {
                    Text(String(format: "%.1f%% downloaded", torrent.progress * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.regularMaterial)
    }
}