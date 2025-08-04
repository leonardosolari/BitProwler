import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let prowlarrService: ProwlarrAPIService = ProwlarrService()
    let qbittorrentService: QBittorrentAPIService = QBittorrentService()

    let prowlarrManager: ProwlarrServerManager
    let qbittorrentManager: QBittorrentServerManager
    let recentPathsManager = RecentPathsManager()
    let searchHistoryManager = SearchHistoryManager()
    
    let filterViewModel = FilterViewModel()
    
    init() {
        self.prowlarrManager = ProwlarrServerManager()
        self.qbittorrentManager = QBittorrentServerManager()
    }
}