import Foundation
import Combine

@MainActor
class TorrentsViewModel: ObservableObject {
    @Published var torrents: [QBittorrentTorrent] = []
    @Published var isLoading = false
    @Published var error: String?
    
    @Published var searchText = ""
    
    @Published var activeSortOption: TorrentSortOption {
        didSet {
            saveSortOption()
            Task { await fetchTorrents() }
        }
    }
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 2.0
    private var qbittorrentManager: GenericServerManager<QBittorrentServer>?
    
    private let apiService: QBittorrentAPIService
    private let userDefaults: UserDefaults
    private let sortOptionKey = "torrentsViewSortOption"
    
    private var searchDebounceTimer: AnyCancellable?
    
    init(apiService: QBittorrentAPIService, userDefaults: UserDefaults = .standard) {
        self.apiService = apiService
        self.userDefaults = userDefaults
        
        if let savedSortOptionRaw = userDefaults.string(forKey: sortOptionKey),
           let savedSortOption = TorrentSortOption(rawValue: savedSortOptionRaw) {
            self.activeSortOption = savedSortOption
        } else {
            self.activeSortOption = .progress
        }
        
        searchDebounceTimer = $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.fetchTorrents() }
            }
    }
    
    func setup(with manager: GenericServerManager<QBittorrentServer>) {
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
        guard let server = qbittorrentManager?.activeServer else {
            self.error = AppError.serverNotConfigured.errorDescription
            return
        }
        
        if !silent && torrents.isEmpty { isLoading = true }
        
        do {
            let fetchedTorrents = try await apiService.getTorrents(
                on: server,
                filter: searchText,
                sort: activeSortOption.apiKey
            )
            self.torrents = fetchedTorrents
            self.error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        
        if !silent { isLoading = false }
    }
    
    private func saveSortOption() {
        userDefaults.set(activeSortOption.rawValue, forKey: sortOptionKey)
    }
}