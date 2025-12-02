import XCTest

let uiTestUserDefaultsSuiteName = "UITestParams"

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
}

struct TestServerConfiguration: OptionSet {
    let rawValue: Int
    
    static let prowlarr = TestServerConfiguration(rawValue: 1 << 0)
    static let qbittorrent = TestServerConfiguration(rawValue: 1 << 1)
    
    static let all: TestServerConfiguration = [.prowlarr, .qbittorrent]
    static let none: TestServerConfiguration = []
}

class BitProwlerUITestsBase: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        app.launchArguments = [
            "-UITesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        try super.tearDownWithError()
    }
    
    func launch(
        scenario: UITestScenario,
        servers: TestServerConfiguration = .none,
        mockDataFile: String? = nil,
        clearUserDefaults: Bool = true
    ) {
        if clearUserDefaults {
            app.launchArguments.append("-shouldClearUserDefaults")
        }
        
        app.launchArguments.append("-testScenario=\(scenario.rawValue)")
        
        var serverConfig: [String] = []
        if servers.contains(.prowlarr) {
            serverConfig.append("prowlarr")
        }
        if servers.contains(.qbittorrent) {
            serverConfig.append("qbittorrent")
        }
        
        if !serverConfig.isEmpty {
            app.launchArguments.append("-configureServers=\(serverConfig.joined(separator: ","))")
        }
        
        if let mockDataFile = mockDataFile {
            app.launchArguments.append("-mockDataFile=\(mockDataFile)")
        }
        
        app.launch()
    }
}

extension XCUIElementQuery {
    func matching(identifier: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return self.matching(predicate)
    }
}