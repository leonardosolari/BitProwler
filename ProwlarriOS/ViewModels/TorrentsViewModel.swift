import Foundation
import Combine

@MainActor
class TorrentsViewModel: ObservableObject {
    @Published var torrents: [QBittorrentTorrent] = []
    @Published var isLoading = false
    @Published var error: String?
    
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
        
        if !silent { isLoading = true }
        
        do {
            let fetchedTorrents = try await apiService.getTorrents(on: server)
            self.torrents = fetchedTorrents
            self.error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        
        if !silent { isLoading = false }
    }
}