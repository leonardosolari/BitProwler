// File: /ProwlarriOS/Views/Components/TorrentResultRow.swift

import SwiftUI

struct TorrentResultRow: View {
    let result: TorrentResult
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sezione Titolo
            Text(result.title)
                .font(.subheadline) // Font leggermente più piccolo per compattezza
                .fontWeight(.semibold)
                .lineLimit(2)
            
            // Sezione Statistiche e Indexer su un'unica riga
            HStack(spacing: 12) {
                // Gruppo Seeders & Leechers
                HStack(spacing: 10) {
                    StatItem(icon: "arrow.up.circle.fill", value: "\(result.seeders)", color: .green)
                    StatItem(icon: "arrow.down.circle.fill", value: "\(result.leechers)", color: .orange)
                }
                
                Spacer()
                
                // Gruppo Dimensione & Indexer
                VStack(alignment: .trailing, spacing: 4) {
                    StatItem(icon: "tray.full.fill", value: formatSize(result.size), color: .secondary)
                    
                    Text(result.indexer)
                        .font(.caption2) // Ancora più piccolo per non essere invadente
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }
            .font(.footnote) // Font di base per le statistiche
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
            TorrentDetailView(result: result)
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// La vista di supporto "StatItem" rimane invariata
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