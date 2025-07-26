// File: /ProwlarriOS/Views/Settings/FilterManagementView.swift

import SwiftUI

struct FilterManagementView: View {
    // <-- MODIFICA QUI: Usa l'oggetto condiviso dall'ambiente
    @EnvironmentObject private var filterViewModel: FilterViewModel
    
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
                        FilterRow(filter: filter) // Non ha più bisogno del viewModel
                    }
                    // <-- MODIFICA QUI: Usa la nuova funzione di cancellazione
                    .onDelete(perform: filterViewModel.deleteFilter)
                }
            }
        }
        .navigationTitle("Gestione Filtri")
        .sheet(isPresented: $showingAddFilter) {
            // Passiamo l'istanza condivisa alla vista di aggiunta
            AddFilterView(filterViewModel: filterViewModel)
        }
    }
}

struct FilterRow: View {
    let filter: TorrentFilter
    
    // <-- MODIFICA QUI: Usa l'oggetto condiviso dall'ambiente anche qui
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
            
            // Il binding ora funziona correttamente perché stiamo modificando
            // l'oggetto condiviso, che farà ri-renderizzare la vista.
            Toggle("", isOn: Binding(
                get: { filter.isEnabled },
                set: { _ in viewModel.toggleFilter(filter) }
            ))
        }
    }
}

#Preview {
    // Aggiorna la preview per fornire l'environment object
    NavigationView {
        FilterManagementView()
    }
    .environmentObject(FilterViewModel())
}