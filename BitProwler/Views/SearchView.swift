import SwiftUI

struct SearchViewContainer: View {
    @EnvironmentObject private var container: AppContainer
    
    var body: some View {
        SearchView(
            prowlarrManager: container.prowlarrManager,
            searchHistoryManager: container.searchHistoryManager,
            apiService: container.prowlarrService
        )
    }
}

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject private var filterViewModel: FilterViewModel
    
    @ObservedObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    @ObservedObject var searchHistoryManager: SearchHistoryManager
    
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var isNavigatingToFilterManagement = false
    
    private var finalResults: [TorrentResult] {
        return filterViewModel.filterResults(viewModel.searchResults)
    }
    
    init(prowlarrManager: GenericServerManager<ProwlarrServer>, searchHistoryManager: SearchHistoryManager, apiService: ProwlarrAPIService) {
        self.prowlarrManager = prowlarrManager
        self.searchHistoryManager = searchHistoryManager
        _viewModel = StateObject(wrappedValue: SearchViewModel(
            apiService: apiService,
            prowlarrManager: prowlarrManager,
            searchHistoryManager: searchHistoryManager
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterBar
                mainContent
            }
            .navigationDestination(isPresented: $isNavigatingToFilterManagement) {
                FilterManagementView()
            }
            .navigationTitle("Search Torrents")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore durante la ricerca")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
        
    @ViewBuilder
    private var mainContent: some View {
        if prowlarrManager.activeServer == nil {
            ContentUnavailableView {
                Label("Configuration Required", systemImage: "gear")
            } description: {
                Text("Go to settings to configure a Prowlarr server")
            }
        } else if viewModel.showError {
            ContentUnavailableView {
                Label("Search Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore sconosciuto.")
            } actions: {
                Button("Try Again") { executeSearch() }.buttonStyle(.borderedProminent)
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
                        Text("Recent Searches")
                        Spacer()
                        Button("Clear") {
                            searchHistoryManager.clearHistory()
                        }
                        .font(.caption)
                    }
                }
            }
        } else if finalResults.isEmpty && viewModel.hasSearched {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text(viewModel.searchResults.isEmpty ?
                               "No torrents found for '\(searchText)'" :
                               "No results match the active filters")
            )
        } else if !viewModel.hasSearched {
            ContentUnavailableView(
                "Search Torrents",
                systemImage: "magnifyingglass",
                description: Text("Enter a term and press Search")
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


private struct FilterMenuWrapper: View {
    @EnvironmentObject var filterViewModel: FilterViewModel
    @Binding var isNavigating: Bool

    var body: some View {
        Menu {
            if filterViewModel.filters.isEmpty {
                Label("No filter configured", systemImage: "xmark.circle")
                    .disabled(true)
            } else {
                Section("Quick Filters") {
                    ForEach(filterViewModel.filters) { filter in
                        Toggle(isOn: Binding(
                            get: { filter.isEnabled },
                            set: { _ in filterViewModel.toggleFilter(filter) }
                        )) {
                            Text(filter.name)
                        }
                    }
                }
            }
            
            Divider()
            
            Button(action: { isNavigating = true }) {
                Label("Manage Filters", systemImage: "slider.horizontal.3")
            }
            
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filters")
                let activeFilterCount = filterViewModel.filters.filter({ $0.isEnabled }).count
                if activeFilterCount > 0 {
                    Text("(\(activeFilterCount))")
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.accentColor)
        }
    }
}

private struct IndexerFilterMenu: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        Menu {
            Button("Select All") {
                viewModel.selectedIndexerIDs = Set(viewModel.allIndexers)
            }
            Button("Deselect All") {
                viewModel.selectedIndexerIDs.removeAll()
            }
            
            Divider()
            
            ForEach(viewModel.allIndexers, id: \.self) { indexer in
                Button(action: {
                    if viewModel.selectedIndexerIDs.contains(indexer) {
                        viewModel.selectedIndexerIDs.remove(indexer)
                    } else {
                        viewModel.selectedIndexerIDs.insert(indexer)
                    }
                }) {
                    HStack {
                        if viewModel.selectedIndexerIDs.contains(indexer) {
                            Image(systemName: "checkmark")
                        }
                        Text(indexer)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "square.stack.3d.up")
                Text("Indexer")
                if !viewModel.selectedIndexerIDs.isEmpty {
                    Text("(\(viewModel.selectedIndexerIDs.count))")
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.accentColor)
        }
    }
}

extension SearchView {
    var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search...", text: $searchText)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterMenuWrapper(isNavigating: $isNavigatingToFilterManagement)
                        
                        if !viewModel.allIndexers.isEmpty {
                            IndexerFilterMenu(viewModel: viewModel)
                        }
                        
                        Spacer()
                        SearchResultSortMenu(viewModel: viewModel)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color.systemGroupedBackground)
    }
}

#Preview {
    ContentView()
}