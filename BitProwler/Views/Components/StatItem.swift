import SwiftUI

struct StatItem: View {
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