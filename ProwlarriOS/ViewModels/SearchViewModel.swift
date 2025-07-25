import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [TorrentResult] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    private let apiService: ProwlarrAPIService
    
    init(apiService: ProwlarrAPIService = NetworkManager()) {
        self.apiService = apiService
    }
    
    func search(query: String, prowlarrManager: ProwlarrServerManager) async {
        guard let prowlarrServer = prowlarrManager.activeServer else {
            handleError(AppError.serverNotConfigured)
            return
        }
        
        guard !query.isEmpty else {
            self.searchResults = []
            self.hasSearched = false
            return
        }
        
        isLoading = true
        hasSearched = true
        
        do {
            let results = try await apiService.search(query: query, on: prowlarrServer)
            self.searchResults = results
            self.isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        self.searchResults = []
        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.showError = true
        self.isLoading = false
    }
}