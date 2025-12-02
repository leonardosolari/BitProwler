import Foundation

#if UITESTING
struct SearchAndAddMockPayload: Decodable {
    let searchResults: [TorrentResult]
    let torrentToAdd: QBittorrentTorrent
}

enum UITestScenario: String {
    case coldStart
    case searchSuccessWithResults
    case searchWithNoResults
    case searchError
    case torrentsSuccess
    case torrentsEmpty
    case torrentsError
    case searchAndAddSuccess
    case addTorrentFromFile
    
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
            (self.prowlarrService, self.qbittorrentService) = AppContainer.createMockServices(for: scenario, from: arguments)
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
        
        #if UITESTING
        if isUITesting {
            setupUITestServers(from: arguments)
        }
        #endif
    }
    
    func userDefaultsForTest() -> UserDefaults {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-UITesting")
        
        if isUITesting {
            return self.userDefaults
        } else {
            return .standard
        }
    }
    
    #if UITESTING
    private func setupUITestServers(from arguments: [String]) {
        guard let serverConfig = arguments.first(where: { $0.starts(with: "-configureServers") })?
            .split(separator: "=").last else {
            return
        }
        
        let servers = serverConfig.split(separator: ",")
        
        if servers.contains("prowlarr") {
            let server = ProwlarrServer(name: "Mock Prowlarr", url: "http://prowlarr.test", apiKey: "123")
            prowlarrManager.addServer(server)
        }
        
        if servers.contains("qbittorrent") {
            let server = QBittorrentServer(name: "Mock qBittorrent", url: "http://qb.test", username: "admin", password: "password")
            qbittorrentManager.addServer(server)
        }
    }
    
    private static func createMockServices(for scenario: UITestScenario, from arguments: [String]) -> (ProwlarrAPIService, QBittorrentAPIService) {
        let prowlarrStub = StubProwlarrService()
        let qbittorrentStub = StubQBittorrentService()
        
        let mockDataFile = arguments.first { $0.starts(with: "-mockDataFile") }?
            .split(separator: "=")
            .last
            .map(String.init)
        
        switch scenario {
        case .coldStart:
            break
            
        case .searchSuccessWithResults:
            guard let mockDataFile = mockDataFile else {
                fatalError("-mockDataFile launch argument is required for this scenario.")
            }
            let results: [TorrentResult] = MockDataLoader.load(mockDataFile)
            prowlarrStub.searchResult = .success(results)
            
        case .searchWithNoResults:
            prowlarrStub.searchResult = .success([])
            
        case .searchError:
            prowlarrStub.searchResult = .failure(.networkError(underlyingError: URLError(.notConnectedToInternet)))
            
        case .torrentsSuccess:
            guard let mockDataFile = mockDataFile else {
                fatalError("-mockDataFile launch argument is required for this scenario.")
            }
            let torrents: [QBittorrentTorrent] = MockDataLoader.load(mockDataFile)
            qbittorrentStub.torrents = torrents
            
            let files: [TorrentFile] = MockDataLoader.load("torrent-files")
            qbittorrentStub.files = files
            
        case .torrentsEmpty:
            qbittorrentStub.torrents = []
            
        case .torrentsError:
            qbittorrentStub.errorToReturn = .httpError(statusCode: 500)
            
        case .searchAndAddSuccess:
            guard let mockDataFile = mockDataFile else {
                fatalError("-mockDataFile launch argument is required for this scenario.")
            }
            let payload: SearchAndAddMockPayload = MockDataLoader.load(mockDataFile)
            prowlarrStub.searchResult = .success(payload.searchResults)
            
            if let torrentUrl = payload.searchResults.first?.primaryDownloadLink {
                qbittorrentStub.addableTorrents[torrentUrl] = payload.torrentToAdd
            }
            qbittorrentStub.torrents = []
            
        case .addTorrentFromFile:
            guard let mockDataFile = mockDataFile else {
                fatalError("-mockDataFile launch argument is required for this scenario.")
            }
            let torrentToAdd: QBittorrentTorrent = MockDataLoader.load(mockDataFile)
            qbittorrentStub.torrentFromFile = torrentToAdd
            qbittorrentStub.torrents = []
        }
        
        return (prowlarrStub, qbittorrentStub)
    }
    #endif
}