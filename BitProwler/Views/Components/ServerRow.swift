import SwiftUI

struct ServerRow: View {
    let name: String
    let isActive: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
} 