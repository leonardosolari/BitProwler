// File: /ProwlarriOS/Views/Components/TorrentRow.swift

import SwiftUI

struct TorrentRow: View {
    let torrent: QBittorrentTorrent
    @State private var showingActionSheet = false
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Livello 1: Titolo e Stato
            HStack {
                Text(torrent.name)
                    .font(.subheadline) // Font più compatto
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Spacer()
                StatusBadge(state: torrent.state)
            }
            
            // Livello 2: Progresso e Statistiche
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: torrent.progress)
                    .tint(StatusBadge.getBackgroundColor(for: torrent.state))
                
                HStack {
                    // Percentuale e Dimensione
                    Text("\(Int(torrent.progress * 100))% di \(formatSize(torrent.size))")
                    
                    Spacer()
                    
                    // Velocità
                    if torrent.downloadSpeed > 0 {
                        StatItem(icon: "arrow.down", value: formatSpeed(torrent.downloadSpeed), color: .green)
                    }
                    if torrent.uploadSpeed > 0 {
                        StatItem(icon: "arrow.up", value: formatSpeed(torrent.uploadSpeed), color: .blue)
                    }
                    
                    // Seeders e Leechers
                    StatItem(icon: "person.2.fill", value: "\(torrent.numSeeds)", color: .green)
                    StatItem(icon: "person.2", value: "\(torrent.numLeechs)", color: .orange)
                }
                .font(.caption) // Unico font per tutta la riga di statistiche
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            showingActionSheet = true
        }
        .sheet(isPresented: $showingActionSheet) {
            TorrentDetailActionSheet(torrent: torrent, manager: qbittorrentManager)
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatSpeed(_ speed: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .decimal
        return "\(formatter.string(fromByteCount: speed))/s"
    }
}

// Componente riutilizzabile per le statistiche
private struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) { // Spacing ridotto
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// StatusBadge rimane invariato
struct StatusBadge: View {
    let state: String
    
    var body: some View {
        Text(TorrentState(from: state).displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Self.getBackgroundColor(for: state).opacity(0.2))
            .foregroundColor(Self.getBackgroundColor(for: state))
            .clipShape(Capsule())
    }
    
    static func getBackgroundColor(for state: String) -> Color {
        let torrentState = TorrentState(from: state)
        switch torrentState {
        case .downloading: return .blue
        case .uploading, .stoppedUP: return .green
        case .pausedDL, .pausedUP: return .gray
        case .stalledDL, .stalledUP: return .orange
        case .error, .missingFiles: return .red
        case .queuedDL, .queuedUP: return .indigo
        default: return .purple
        }
    }
}