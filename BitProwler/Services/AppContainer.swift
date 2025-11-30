import Foundation

#if UITESTING
enum UITestScenario: String {
    case coldStart
    case searchSuccessWithResults
    case searchWithNoResults
    case searchError
    case torrentsSuccess
    case torrentsEmpty
    case torrentsError
    
    init(from arguments: [String]) {
        let scenarioValue = arguments.first { $0.starts(with: "-testScenario") }?
            .split(separator: "=")
            .last
            .map(String.init)
        
        self = UITestScenario(rawValue: scenarioValue ?? "coldStart") ?? .coldStart
    }
}
#endif

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
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-UITesting")
        
        if isUITesting {
            self.userDefaults = UserDefaults(suiteName: "UITestParams")!
            self.userDefaults.removePersistentDomain(forName: "UITestParams")
            self.keychainService = StubKeychain()
            
            #if UITESTING
            let scenario = UITestScenario(from: arguments)
            (self.prowlarrService, self.qbittorrentService) = AppContainer.createMockServices(for: scenario)
            #else
            fatalError("UITesting flag is set but not in a UITESTING build configuration.")
            #endif
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
    
    #if UITESTING
    private static func createMockServices(for scenario: UITestScenario) -> (ProwlarrAPIService, QBittorrentAPIService) {
        let prowlarrStub = StubProwlarrService()
        let qbittorrentStub = StubQBittorrentService()
        
        switch scenario {
        case .coldStart:
            break
            
        case .searchSuccessWithResults:
            let results: [TorrentResult] = MockDataLoader.load("search-success")
            prowlarrStub.searchResult = .success(results)
            
        case .searchWithNoResults:
            prowlarrStub.searchResult = .success([])
            
        case .searchError:
            prowlarrStub.searchResult = .failure(.networkError(underlyingError: URLError(.notConnectedToInternet)))
            
        case .torrentsSuccess:
            let torrents: [QBittorrentTorrent] = MockDataLoader.load("torrents-success")
            qbittorrentStub.torrentsResult = .success(torrents)
            
        case .torrentsEmpty:
            qbittorrentStub.torrentsResult = .success([])
            
        case .torrentsError:
            qbittorrentStub.torrentsResult = .failure(.httpError(statusCode: 500))
        }
        
        return (prowlarrStub, qbittorrentStub)
    }
    #endif
}