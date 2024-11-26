import SwiftUI
import Foundation

struct TorrentRow: View {
    let torrent: QBittorrentTorrent
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nome e stato
            HStack {
                Text(torrent.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                StatusBadge(state: torrent.state)
            }
            
            // Barra di progresso
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: torrent.progress)
                    .tint(progressColor(for: torrent.state))
                Text("\(Int(torrent.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Informazioni dettagliate
            HStack {
                // Dimensione
                Text(formatSize(torrent.size))
                    .font(.caption)
                
                Spacer()
                
                // Seeders/Leechers
                HStack(spacing: 12) {
                    Label("\(torrent.numSeeds)", systemImage: "person.2.fill")
                        .foregroundColor(.green)
                    Label("\(torrent.numLeechs)", systemImage: "person.2")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
            
            // Velocità
            if torrent.downloadSpeed > 0 || torrent.uploadSpeed > 0 {
                HStack {
                    if torrent.downloadSpeed > 0 {
                        Label(formatSpeed(torrent.downloadSpeed), systemImage: "arrow.down")
                            .foregroundColor(.green)
                    }
                    if torrent.uploadSpeed > 0 {
                        Label(formatSpeed(torrent.uploadSpeed), systemImage: "arrow.up")
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingActionSheet = true
        }
        .sheet(isPresented: $showingActionSheet) {
            TorrentDetailActionSheet(torrent: torrent)
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatSpeed(_ speed: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: speed))/s"
    }
    
    private func progressColor(for state: String) -> Color {
        switch state.lowercased() {
        case "downloading": return .blue
        case "uploading", "seeding": return .green
        case let s where s.contains("paused"): return .gray
        case let s where s.contains("stalled"): return .orange
        case "error": return .red
        default: return .gray
        }
    }
}

struct StatusBadge: View {
    let state: String
    
    var body: some View {
        Text(stateText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var stateText: String {
        switch state.lowercased() {
        case "downloading": return "Download"
        case "uploading", "seeding": return "Upload"
        case let s where s.contains("pauseddl"): return "In Pausa (DL)"
        case let s where s.contains("pausedup"): return "In Pausa (UP)"
        case let s where s.contains("stalleddl"): return "Stalled (DL)"
        case let s where s.contains("stalledup"): return "Stalled (UP)"
        case "error": return "Errore"
        case "missingfiles": return "File Mancanti"
        default: return state.capitalized
        }
    }
    
    private var backgroundColor: Color {
        switch state.lowercased() {
        case "downloading": return .blue
        case "uploading", "seeding": return .green
        case let s where s.contains("paused"): return .gray
        case let s where s.contains("stalled"): return .orange
        case "error", "missingfiles": return .red
        default: return .gray
        }
    }
} 