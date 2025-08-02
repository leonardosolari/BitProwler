import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [TorrentResult] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    @Published var activeSortOption: SortOption = .default
    
    private let apiService: ProwlarrAPIService
    private let prowlarrManager: ProwlarrServerManager
    let searchHistoryManager: SearchHistoryManager
    
    private var originalResults: [TorrentResult] = []
    
    
    init(
        apiService: ProwlarrAPIService = NetworkManager(),
        prowlarrManager: ProwlarrServerManager,
        searchHistoryManager: SearchHistoryManager
    ) {
        self.apiService = apiService
        self.prowlarrManager = prowlarrManager
        self.searchHistoryManager = searchHistoryManager
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
}