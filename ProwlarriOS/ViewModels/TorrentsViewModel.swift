import Foundation
import Combine

@MainActor
class TorrentsViewModel: ObservableObject {
    @Published var filteredTorrents: [QBittorrentTorrent] = []
    @Published var isLoading = false
    @Published var error: String?
    
    @Published var searchText = "" {
        didSet { applyFiltersAndSorting() }
    }
    @Published var activeSortOption: TorrentSortOption = .progress {
        didSet { applyFiltersAndSorting() }
    }
    
    private var allTorrents: [QBittorrentTorrent] = []
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 2.0
    private var qbittorrentManager: QBittorrentServerManager?
    
    private let apiService: QBittorrentAPIService
    
    init(apiService: QBittorrentAPIService = NetworkManager()) {
        self.apiService = apiService
    }
    
    func setup(with manager: QBittorrentServerManager) {
        self.qbittorrentManager = manager
        Task { await fetchTorrents() }
        startTimer()
    }
    
    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { await self?.fetchTorrents(silent: true) }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchTorrents(silent: Bool = false) async {
        guard let server = qbittorrentManager?.activeQBittorrentServer else {
            self.error = AppError.serverNotConfigured.errorDescription
            return
        }
        
        if !silent && allTorrents.isEmpty { isLoading = true }
        
        do {
            let fetchedTorrents = try await apiService.getTorrents(on: server)
            self.allTorrents = fetchedTorrents
            self.applyFiltersAndSorting()
            self.error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        
        if !silent { isLoading = false }
    }
    
    private func applyFiltersAndSorting() {
        var processedTorrents = allTorrents
        
        if !searchText.isEmpty {
            processedTorrents = processedTorrents.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch activeSortOption {
        case .name:
            processedTorrents.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .progress:
            processedTorrents.sort { $0.progress > $1.progress }
        case .downloadSpeed:
            processedTorrents.sort { $0.downloadSpeed > $1.downloadSpeed }
        case .uploadSpeed:
            processedTorrents.sort { $0.uploadSpeed > $1.uploadSpeed }
        case .size:
            processedTorrents.sort { $0.size > $1.size }
        case .state:
            processedTorrents.sort { $0.state < $1.state }
        }
        
        self.filteredTorrents = processedTorrents
    }
}