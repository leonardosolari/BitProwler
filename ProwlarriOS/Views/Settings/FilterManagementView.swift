import SwiftUI

struct FilterManagementView: View {
    @StateObject private var filterViewModel = FilterViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingAddFilter = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddFilter = true }) {
                    Label("Aggiungi Filtro", systemImage: "plus.circle")
                }
            }
            
            Section {
                Picker("Logica Filtri", selection: $filterViewModel.filterLogic) {
                    Text("Tutti i filtri devono corrispondere")
                        .tag(FilterViewModel.FilterLogic.and)
                    Text("Basta che corrisponda un filtro")
                        .tag(FilterViewModel.FilterLogic.or)
                }
            } header: {
                Text("Impostazioni Filtri")
            } footer: {
                Text(filterViewModel.filterLogic == .and ? 
                    "I risultati devono contenere tutte le parole chiave dei filtri attivi" :
                    "I risultati devono contenere almeno una delle parole chiave dei filtri attivi")
            }
            
            if !filterViewModel.filters.isEmpty {
                Section("Filtri Configurati") {
                    ForEach(filterViewModel.filters) { filter in
                        FilterRow(filter: filter, viewModel: filterViewModel)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            filterViewModel.deleteFilter(filterViewModel.filters[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Gestione Filtri")
        .sheet(isPresented: $showingAddFilter) {
            AddFilterView(filterViewModel: filterViewModel)
        }
    }
}

struct FilterRow: View {
    let filter: TorrentFilter
    let viewModel: FilterViewModel
    
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