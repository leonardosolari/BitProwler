// File: /ProwlarriOS/ViewModels/SearchViewModel.swift

import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [TorrentResult] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    // NUOVA PROPRIETÀ PER L'ORDINAMENTO
    @Published var activeSortOption: SortOption = .default
    
    private let apiService: ProwlarrAPIService
    
    // Proprietà per memorizzare i risultati originali non ordinati
    private var originalResults: [TorrentResult] = []
    
    init(apiService: ProwlarrAPIService = NetworkManager()) {
        self.apiService = apiService
    }
    
    func search(query: String, prowlarrManager: ProwlarrServerManager) async {
        guard let prowlarrServer = prowlarrManager.activeServer else {
            handleError(AppError.serverNotConfigured)
            return
        }
        
        guard !query.isEmpty else {
            self.originalResults = []
            self.applySorting() // Applica l'ordinamento (che risulterà in una lista vuota)
            self.hasSearched = false
            return
        }
        
        isLoading = true
        hasSearched = true
        
        do {
            let results = try await apiService.search(query: query, on: prowlarrServer)
            self.originalResults = results
            self.applySorting() // Applica l'ordinamento ai nuovi risultati
            self.isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    // NUOVO METODO PER APPLICARE L'ORDINAMENTO
    func applySorting() {
        switch activeSortOption {
        case .default:
            // L'ordinamento di default è quello restituito dall'API
            searchResults = originalResults
        case .seeders:
            // Ordina per seeders, dal più alto al più basso
            searchResults = originalResults.sorted { $0.seeders > $1.seeders }
        case .size:
            // Ordina per dimensione, dalla più grande alla più piccola
            searchResults = originalResults.sorted { $0.size > $1.size }
        case .recent:
            // Ordina per data, dalla più recente alla più vecchia
            // Usiamo un ISO8601 formatter per convertire la stringa in data
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