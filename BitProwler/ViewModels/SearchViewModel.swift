import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [TorrentResult] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    @Published var activeSortDescriptor: SortDescriptor<SortOption> {
        didSet {
            applyFiltersAndSorting()
            saveSortDescriptor()
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
    private let sortDescriptorKey = "searchViewSortDescriptor"
    
    init(
        apiService: ProwlarrAPIService,
        prowlarrManager: GenericServerManager<ProwlarrServer>,
        searchHistoryManager: SearchHistoryManager
    ) {
        self.apiService = apiService
        self.prowlarrManager = prowlarrManager
        self.searchHistoryManager = searchHistoryManager
        
        if let data = UserDefaults.standard.data(forKey: sortDescriptorKey),
           let decodedDescriptor = try? JSONDecoder().decode(SortDescriptor<SortOption>.self, from: data) {
            self.activeSortDescriptor = decodedDescriptor
        } else {
            self.activeSortDescriptor = SortDescriptor(option: .seeders, direction: .descending)
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
    
    func selectSortOption(_ option: SortOption) {
        if activeSortDescriptor.option == option {
            activeSortDescriptor.direction.toggle()
        } else {
            activeSortDescriptor.option = option
            activeSortDescriptor.direction = .descending
        }
    }
    
    func applyFiltersAndSorting() {
        var processedResults = originalResults
        
        let sortDirection = activeSortDescriptor.direction
        
        switch activeSortDescriptor.option {
        case .default:
            break
        case .seeders:
            processedResults.sort {
                sortDirection == .descending ? $0.seeders > $1.seeders : $0.seeders < $1.seeders
            }
        case .size:
            processedResults.sort {
                sortDirection == .descending ? $0.size > $1.size : $0.size < $1.size
            }
        case .recent:
            let formatter = ISO8601DateFormatter()
            processedResults.sort {
                let date1 = formatter.date(from: $0.publishDate) ?? .distantPast
                let date2 = formatter.date(from: $1.publishDate) ?? .distantPast
                return sortDirection == .descending ? date1 > date2 : date1 < date2
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
    
    private func saveSortDescriptor() {
        if let data = try? JSONEncoder().encode(activeSortDescriptor) {
            UserDefaults.standard.set(data, forKey: sortDescriptorKey)
        }
    }
}