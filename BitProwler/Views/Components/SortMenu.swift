import SwiftUI

protocol SortOptionable: RawRepresentable, CaseIterable, Identifiable, Hashable where RawValue == String {
    var systemImage: String { get }
    var localized: LocalizedStringKey { get }
}

struct SortMenu<T: SortOptionable>: View {
    @Binding var activeSortOption: T
    let title: String

    var body: some View {
        Menu {
            Picker(title, selection: $activeSortOption) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Label(option.localized, systemImage: option.systemImage).tag(option)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: activeSortOption.systemImage)
                Text(activeSortOption.localized)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
    }
}