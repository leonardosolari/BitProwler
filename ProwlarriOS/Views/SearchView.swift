import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var filterViewModel = FilterViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    @FocusState private var isSearchFieldFocused: Bool
    
    private var filteredResults: [TorrentResult] {
        _ = filterViewModel.filterUpdateTrigger
        return filterViewModel.filterResults(viewModel.searchResults)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterBar
                
                mainContent
            }
            .navigationTitle("Cerca Torrent")
            .alert("Errore", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore durante la ricerca")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Ricerca in corso...")
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    // --- Componenti Estratti ---
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Cerca...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSearchFieldFocused)
                    .onSubmit(executeSearch)
                    .submitLabel(.search)
                
                Button(action: {
                    isSearchFieldFocused = false
                    executeSearch()
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(searchText.isEmpty)
                
                if !viewModel.searchResults.isEmpty {
                    Button(action: { withAnimation { showingFilters.toggle() } }) {
                        Image(systemName: "line.3.horizontal.decrease.circle\(showingFilters ? ".fill" : "")")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            
            if showingFilters && !viewModel.searchResults.isEmpty {
                filterSection
                    .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var filterSection: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(filterViewModel.filters) { filter in
                        FilterChip(filter: filter, viewModel: filterViewModel)
                    }
                    
                    NavigationLink(destination: FilterManagementView()) {
                        Image(systemName: "gear")
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
            }
            
            let activeFilterCount = filterViewModel.filters.filter({ $0.isEnabled }).count
            if activeFilterCount > 0 {
                Text("Filtri attivi: \(activeFilterCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if prowlarrManager.activeServer == nil {
            ContentUnavailableView(
                "Configurazione Necessaria",
                systemImage: "gear",
                description: Text("Vai nelle impostazioni per configurare il server Prowlarr")
            )
        } else if filteredResults.isEmpty && viewModel.hasSearched {
            ContentUnavailableView(
                "Nessun Risultato",
                systemImage: "magnifyingglass",
                description: Text(viewModel.searchResults.isEmpty ?
                               "Nessun torrent trovato per '\(searchText)'" :
                               "Nessun risultato corrisponde ai filtri attivi")
            )
        } else if !viewModel.hasSearched {
            ContentUnavailableView(
                "Cerca Torrent",
                systemImage: "magnifyingglass",
                description: Text("Inserisci un termine e premi Cerca")
            )
        } else {
            List(filteredResults) { result in
                TorrentResultRow(result: result)
            }
            .listStyle(.plain)
        }
    }
    
    // --- Funzioni ---
    
    private func executeSearch() {
        guard !searchText.isEmpty else { return }
        Task {
            // Passiamo il manager al ViewModel
            await viewModel.search(query: searchText, prowlarrManager: prowlarrManager)
        }
    }
}

// --- Viste Componente ---

struct FilterChip: View {
    let filter: TorrentFilter
    @ObservedObject var viewModel: FilterViewModel
    
    var body: some View {
        Button(action: { viewModel.toggleFilter(filter) }) {
            Text(filter.name)
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filter.isEnabled ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(filter.isEnabled ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

// La preview potrebbe aver bisogno di essere aggiornata per fornire i manager
#Preview {
    SearchView()
        .environmentObject(ProwlarrServerManager())
        .environmentObject(FilterViewModel())
}