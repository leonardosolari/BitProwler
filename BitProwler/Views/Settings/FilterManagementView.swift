import SwiftUI

struct FilterManagementView: View {
    @EnvironmentObject private var filterViewModel: FilterViewModel
    
    @State private var showingAddFilter = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddFilter = true }) {
                    Label("Add Filter", systemImage: "plus.circle")
                }
            }
            
            Section {
                Picker("Filter Logic", selection: $filterViewModel.filterLogic) {
                    Text("Match all filters")
                        .tag(FilterViewModel.FilterLogic.and)
                    Text("Match any filter")
                        .tag(FilterViewModel.FilterLogic.or)
                }
            } header: {
                Text("Filter Settings")
            } footer: {
                Text(filterViewModel.filterLogic == .and ?
                     "Results must contain all of the active filter keywords" :
                     "Results must contain at least one of the active filter keywords")
            }
            
            if !filterViewModel.filters.isEmpty {
                Section("Configured Filters") {
                    ForEach(filterViewModel.filters) { filter in
                        FilterRow(filter: filter)
                    }
                    .onDelete(perform: filterViewModel.deleteFilter)
                }
            }
        }
        .navigationTitle("Filter Management")
        .sheet(isPresented: $showingAddFilter) {
            AddFilterView(filterViewModel: filterViewModel)
        }
    }
}

struct FilterRow: View {
    let filter: TorrentFilter
    
    @EnvironmentObject var viewModel: FilterViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(filter.name)
                    .font(.headline)
                Text(filter.keyword)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            
            Toggle("", isOn: Binding(
                get: { filter.isEnabled },
                set: { _ in viewModel.toggleFilter(filter) }
            ))
        }
    }
}

#Preview {
    NavigationView {
        FilterManagementView()
    }
    .environmentObject(FilterViewModel())
}