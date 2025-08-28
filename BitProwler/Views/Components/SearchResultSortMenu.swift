import SwiftUI

struct SearchResultSortMenu: View {
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    viewModel.selectSortOption(option)
                }) {
                    Label {
                        option.localizedLabel
                    } icon: {
                        if viewModel.activeSortDescriptor.option == option {
                            Image(systemName: viewModel.activeSortDescriptor.direction.systemImage)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.activeSortDescriptor.option.systemImage)
                viewModel.activeSortDescriptor.option.localizedLabel
                Image(systemName: viewModel.activeSortDescriptor.direction.systemImage)
                    .font(.caption.bold())
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
    }
}