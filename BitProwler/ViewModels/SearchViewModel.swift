import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [TorrentResult] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    @Published var activeSortOption: SortOption {
        didSet {
            applyFiltersAndSorting()
            saveSortOption()
        }
    }
    
    @Published var allIndexers: [String] = []
    @Published var selectedIndexerIDs: Set<String> = [] {
        didSet {
            applyFiltersAndSorting()
        }
    }
    
    private let apiService: ProwlarrAPIService
    private let prowlarrManager: GenericServerManager<ProwlarrServer>
    let searchHistoryManager: SearchHistoryManager
    
    private var originalResults: [TorrentResult] = []
    private let sortOptionKey = "searchViewSortOption"
    
    init(
        apiService: ProwlarrAPIService,
        prowlarrManager: GenericServerManager<ProwlarrServer>,
        searchHistoryManager: SearchHistoryManager
    ) {
        self.apiService = apiService
        self.prowlarrManager = prowlarrManager
        self.searchHistoryManager = searchHistoryManager
        
        if let savedSortOptionRaw = UserDefaults.standard.string(forKey: sortOptionKey),
           let savedSortOption = SortOption(rawValue: savedSortOptionRaw) {
            self.activeSortOption = savedSortOption
        } else {
            self.activeSortOption = .default
        }
    }
    
    func search(query: String) async {
        guard let prowlarrServer = prowlarrManager.activeServer else {
            handleError(AppError.serverNotConfigured)
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            self.originalResults = []
            self.allIndexers = []
            self.selectedIndexerIDs = []
            self.applyFiltersAndSorting()
            self.hasSearched = false
            return
        }
        
        isLoading = true
        hasSearched = true
        
        do {
            let results = try await apiService.search(query: trimmedQuery, on: prowlarrServer)
            self.originalResults = results
            self.allIndexers = Array(Set(results.map { $0.indexer })).sorted()
            self.selectedIndexerIDs = []
            self.applyFiltersAndSorting()
            self.searchHistoryManager.addSearch(trimmedQuery)
            self.isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func applyFiltersAndSorting() {
        var processedResults = originalResults
        
        switch activeSortOption {
        case .default:
            break
        case .seeders:
            processedResults.sort { $0.seeders > $1.seeders }
        case .size:
            processedResults.sort { $0.size > $1.size }
        case .recent:
            let formatter = ISO8601DateFormatter()
            processedResults.sort {
                let date1 = formatter.date(from: $0.publishDate) ?? .distantPast
                let date2 = formatter.date(from: $1.publishDate) ?? .distantPast
                return date1 > date2
            }
        }
        
        if !selectedIndexerIDs.isEmpty {
            processedResults = processedResults.filter { selectedIndexerIDs.contains($0.indexer) }
        }
        
        searchResults = processedResults
    }
    
    private func handleError(_ error: Error) {
        self.originalResults = []
        self.allIndexers = []
        self.selectedIndexerIDs = []
        self.applyFiltersAndSorting()
        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.showError = true
        self.isLoading = false
    }
    
    private func saveSortOption() {
        UserDefaults.standard.set(activeSortOption.rawValue, forKey: sortOptionKey)
    }
}