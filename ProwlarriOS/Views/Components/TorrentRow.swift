// File: /ProwlarriOS/Views/Components/TorrentRow.swift

import SwiftUI

struct TorrentRow: View {
    let torrent: QBittorrentTorrent
    @State private var showingActionSheet = false
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sezione Titolo e Stato
            HStack {
                Text(torrent.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Spacer()
                StatusBadge(state: torrent.state)
            }
            
            // Sezione Progresso
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: torrent.progress)
                    .tint(StatusBadge.getBackgroundColor(for: torrent.state))
                
                HStack {
                    Text("\(Int(torrent.progress * 100))%")
                    Spacer()
                    Text(formatSize(torrent.size))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Sezione Statistiche
            HStack(spacing: 0) {
                StatItem(icon: "arrow.down", value: formatSpeed(torrent.downloadSpeed), color: .green)
                Spacer()
                StatItem(icon: "arrow.up", value: formatSpeed(torrent.uploadSpeed), color: .blue)
                Spacer()
                StatItem(icon: "person.2.fill", value: "\(torrent.numSeeds)", color: .green)
                Spacer()
                StatItem(icon: "person.2", value: "\(torrent.numLeechs)", color: .orange)
            }
            .font(.footnote)
            
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground)) // Sfondo leggermente diverso
        .cornerRadius(12)
        .listRowSeparator(.hidden) // Nasconde il separatore di default
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            showingActionSheet = true
        }
        // RIGA CORRETTA
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
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// StatusBadge rimane quasi uguale, ma possiamo migliorarla
struct StatusBadge: View {
    let state: String
    
    var body: some View {
        Text(TorrentState(from: state).displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Self.getBackgroundColor(for: state).opacity(0.2)) // Sfondo più leggero
            .foregroundColor(Self.getBackgroundColor(for: state)) // Testo con colore pieno
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