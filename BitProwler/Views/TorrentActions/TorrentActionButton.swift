import SwiftUI

struct TorrentActionButton: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                .frame(width: 56, height: 56)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}