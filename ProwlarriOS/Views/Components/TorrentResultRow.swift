import SwiftUI

struct TorrentResultRow: View {
    let result: TorrentResult
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Label("\(result.seeders)", systemImage: "arrow.up.circle")
                    .foregroundColor(.green)
                Label("\(result.leechers)", systemImage: "arrow.down.circle")
                    .foregroundColor(.red)
                Spacer()
                Text(formatSize(result.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}