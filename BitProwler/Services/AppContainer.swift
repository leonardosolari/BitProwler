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
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        
        if isUITesting {
            self.userDefaults = UserDefaults(suiteName: "UITestParams") ?? .standard
            self.userDefaults.removePersistentDomain(forName: "UITestParams")
            
            self.keychainService = StubKeychain()
            self.prowlarrService = StubProwlarrService()
            self.qbittorrentService = StubQBittorrentService()
        } else {
            self.userDefaults = .standard
            self.keychainService = KeychainService()
            self.prowlarrService = ProwlarrService(urlSession: .shared)
            self.qbittorrentService = QBittorrentService(urlSession: .shared)
        }
        
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