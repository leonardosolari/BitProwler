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
            applySorting()
            saveSortOption()
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
            self.applySorting()
            self.hasSearched = false
            return
        }
        
        isLoading = true
        hasSearched = true
        
        do {
            let results = try await apiService.search(query: trimmedQuery, on: prowlarrServer)
            self.originalResults = results
            self.applySorting()
            self.searchHistoryManager.addSearch(trimmedQuery)
            self.isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func applySorting() {
        switch activeSortOption {
        case .default:
            searchResults = originalResults
        case .seeders:
            searchResults = originalResults.sorted { $0.seeders > $1.seeders }
        case .size:
            searchResults = originalResults.sorted { $0.size > $1.size }
        case .recent:
            let formatter = ISO8601DateFormatter()
            searchResults = originalResults.sorted {
                let date1 = formatter.date(from: $0.publishDate) ?? .distantPast
                let date2 = formatter.date(from: $1.publishDate) ?? .distantPast
                return date1 > date2
            }
        }
    }
    
    private func handleError(_ error: Error) {
        self.originalResults = []
        self.applySorting()
        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.showError = true
        self.isLoading = false
    }
    
    private func saveSortOption() {
        UserDefaults.standard.set(activeSortOption.rawValue, forKey: sortOptionKey)
    }
}