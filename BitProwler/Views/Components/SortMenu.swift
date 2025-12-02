import SwiftUI

protocol SortOptionable: RawRepresentable, CaseIterable, Identifiable, Hashable where RawValue == String {
    var systemImage: String { get }
    var localizedLabel: Text { get }
}

struct SortMenu<T: SortOptionable>: View {
    @Binding var activeSortOption: T
    let title: String

    var body: some View {
        Menu {
            Picker(title, selection: $activeSortOption) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Label {
                        option.localizedLabel
                    } icon: {
                        Image(systemName: option.systemImage)
                    }
                    .tag(option)
                    .accessibilityIdentifier("sort_option_\(option.rawValue)")
                }
            }
        } label: {
            Label {
                activeSortOption.localizedLabel
            } icon: {
                Image(systemName: activeSortOption.systemImage)
            }
        }
    }
}