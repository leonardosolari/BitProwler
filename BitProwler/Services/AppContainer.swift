import Foundation

@MainActor
final class AppContainer: ObservableObject {

    static let shared = AppContainer()

    let prowlarrService: ProwlarrAPIService
    let qbittorrentService: QBittorrentAPIService

    let prowlarrManager: GenericServerManager<ProwlarrServer>
    let qbittorrentManager: GenericServerManager<QBittorrentServer>
    let recentPathsManager: RecentPathsManager
    let searchHistoryManager: SearchHistoryManager
    
    let filterViewModel: FilterViewModel
    
    private let keychainService: KeychainProtocol
    private let userDefaults: UserDefaults
    
    init() {
        self.keychainService = KeychainService()
        self.userDefaults = .standard
        
        self.prowlarrService = ProwlarrService(urlSession: .shared)
        self.qbittorrentService = QBittorrentService(urlSession: .shared)
        
        self.prowlarrManager = GenericServerManager<ProwlarrServer>(
            keychainService: keychainService,
            userDefaults: userDefaults
        )
        
        self.qbittorrentManager = GenericServerManager<QBittorrentServer>(
            keychainService: keychainService,
            userDefaults: userDefaults
        )
        
        self.recentPathsManager = RecentPathsManager(userDefaults: userDefaults)
        self.searchHistoryManager = SearchHistoryManager(userDefaults: userDefaults)
        
        self.filterViewModel = FilterViewModel(userDefaults: userDefaults)
    }
}