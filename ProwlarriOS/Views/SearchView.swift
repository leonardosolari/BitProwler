import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var filterViewModel = FilterViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    @FocusState private var isSearchFieldFocused: Bool
    
    var filteredResults: [TorrentResult] {
        _ = filterViewModel.filterUpdateTrigger
        return filterViewModel.filterResults(viewModel.searchResults)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Barra di ricerca personalizzata
                    HStack {
                        TextField("Cerca...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isSearchFieldFocused)
                            .onSubmit {
                                executeSearch()
                            }
                            .submitLabel(.search)
                        
                        Button(action: {
                            isSearchFieldFocused = false
                            executeSearch()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(searchText.isEmpty)
                        
                        if !viewModel.searchResults.isEmpty {
                            Button(action: { showingFilters.toggle() }) {
                                Image(systemName: "line.3.horizontal.decrease.circle\(showingFilters ? ".fill" : "")")
                                    .foregroundColor(.blue)
                                    .padding(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if showingFilters && !viewModel.searchResults.isEmpty {
                        VStack(spacing: 8) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(filterViewModel.filters) { filter in
                                        FilterChip(filter: filter, viewModel: filterViewModel)
                                    }
                                    
                                    NavigationLink(destination: FilterManagementView()) {
                                        Image(systemName: "gear")
                                            .foregroundColor(.blue)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            if !filterViewModel.filters.filter({ $0.isEnabled }).isEmpty {
                                Text("Filtri attivi: \(filterViewModel.filters.filter { $0.isEnabled }.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Contenuto principale
                    if prowlarrManager.activeServer == nil {
                        ContentUnavailableView(
                            "Configurazione Necessaria",
                            systemImage: "gear",
                            description: Text("Vai nelle impostazioni per configurare il server Prowlarr")
                        )
                    } else if filteredResults.isEmpty && !searchText.isEmpty && !viewModel.isLoading && viewModel.hasSearched {
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
                            description: Text("Inserisci il termine di ricerca e premi invio o il pulsante cerca")
                        )
                    } else {
                        List(filteredResults) { result in
                            TorrentResultRow(result: result)
                        }
                    }
                }
                
                // Overlay di caricamento
                if viewModel.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Ricerca in corso...")
                        .padding()
                        .background(Color.systemBackground)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("Cerca Torrent")
            // Alert per gli errori
            .alert("Errore", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore durante la ricerca")
            }
        }
    }
    
    private func executeSearch() {
        guard !searchText.isEmpty else { return }
        Task {
            await viewModel.search(query: searchText, prowlarrManager: prowlarrManager)
        }
    }
}

struct FilterChip: View {
    let filter: TorrentFilter
    let viewModel: FilterViewModel
    
    var body: some View {
        Button(action: { viewModel.toggleFilter(filter) }) {
            Text(filter.name)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filter.isEnabled ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(filter.isEnabled ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

extension Color {
    static let systemBackground = Color(UIColor.systemBackground)
}

#Preview {
    SearchView()
        .environmentObject(ProwlarrServerManager())
}