import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let prowlarrService: ProwlarrAPIService = ProwlarrService()
    let qbittorrentService: QBittorrentAPIService = QBittorrentService()

    let prowlarrManager: GenericServerManager<ProwlarrServer>
    let qbittorrentManager: GenericServerManager<QBittorrentServer>
    let recentPathsManager = RecentPathsManager()
    let searchHistoryManager = SearchHistoryManager()
    
    let filterViewModel = FilterViewModel()
    
    init() {
        self.prowlarrManager = GenericServerManager<ProwlarrServer>()
        self.qbittorrentManager = GenericServerManager<QBittorrentServer>()
    }
}