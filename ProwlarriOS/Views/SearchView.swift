// File: /ProwlarriOS/Views/SearchView.swift

import SwiftUI

// 1. IL CONTAINER VIEW
struct SearchViewContainer: View {
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    @EnvironmentObject var searchHistoryManager: SearchHistoryManager
    
    var body: some View {
        SearchView(
            prowlarrManager: prowlarrManager,
            searchHistoryManager: searchHistoryManager
        )
    }
}

// 2. LA VISTA PRINCIPALE (MODIFICATA)
struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @StateObject private var filterViewModel = FilterViewModel()
    @State private var searchText = ""
    
    // CORREZIONE QUI: ProwlarrServerManager invece di ProwlarrManager
    @ObservedObject var prowlarrManager: ProwlarrServerManager
    @ObservedObject var searchHistoryManager: SearchHistoryManager
    
    @FocusState private var isSearchFieldFocused: Bool
    
    private var finalResults: [TorrentResult] {
        _ = filterViewModel.filterUpdateTrigger
        return filterViewModel.filterResults(viewModel.searchResults)
    }
    
    // CORREZIONE QUI: ProwlarrServerManager invece di ProwlarrManager
    init(prowlarrManager: ProwlarrServerManager, searchHistoryManager: SearchHistoryManager) {
        self.prowlarrManager = prowlarrManager
        self.searchHistoryManager = searchHistoryManager
        _viewModel = StateObject(wrappedValue: SearchViewModel(
            prowlarrManager: prowlarrManager,
            searchHistoryManager: searchHistoryManager
        ))
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
            .onChange(of: viewModel.activeSortOption) { _ in
                viewModel.applySorting()
            }
        }
    }
    
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
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .disabled(searchText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top)
            
            if !viewModel.searchResults.isEmpty {
                HStack {
                    FilterButton(viewModel: filterViewModel)
                    Spacer()
                    SortMenu(viewModel: viewModel)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if prowlarrManager.activeServer == nil {
            ContentUnavailableView {
                Label("Configurazione Necessaria", systemImage: "gear")
            } description: {
                Text("Vai nelle impostazioni per configurare il server Prowlarr.")
            }
        } else if viewModel.showError {
            ContentUnavailableView {
                Label("Errore di Ricerca", systemImage: "exclamationmark.triangle")
            } description: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore sconosciuto.")
            } actions: {
                Button("Riprova") { executeSearch() }.buttonStyle(.borderedProminent)
            }
        } else if !viewModel.hasSearched && !searchHistoryManager.searches.isEmpty {
            List {
                Section {
                    ForEach(searchHistoryManager.searches, id: \.self) { term in
                        Button(action: {
                            searchText = term
                            executeSearch()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text(term)
                                Spacer()
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    HStack {
                        Text("Ricerche Recenti")
                        Spacer()
                        Button("Cancella") {
                            searchHistoryManager.clearHistory()
                        }
                        .font(.caption)
                    }
                }
            }
        } else if finalResults.isEmpty && viewModel.hasSearched {
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
            List(finalResults) { result in
                TorrentResultRow(result: result)
            }
            .listStyle(.plain)
        }
    }
    
    private func executeSearch() {
        guard !searchText.isEmpty else { return }
        Task {
            await viewModel.search(query: searchText)
        }
    }
}

// --- Viste Componente (invariate) ---
private struct FilterButton: View {
    @ObservedObject var viewModel: FilterViewModel
    
    var body: some View {
        NavigationLink(destination: FilterManagementView()) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filtri")
                if viewModel.filters.filter({ $0.isEnabled }).count > 0 {
                    Text("(\(viewModel.filters.filter({ $0.isEnabled }).count))")
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

private struct SortMenu: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        Menu {
            Picker("Ordina per", selection: $viewModel.activeSortOption) {
                ForEach(SortOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.systemImage).tag(option)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.activeSortOption.systemImage)
                Text(viewModel.activeSortOption.rawValue)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    SearchViewContainer()
        .environmentObject(ProwlarrServerManager())
        .environmentObject(SearchHistoryManager())
}