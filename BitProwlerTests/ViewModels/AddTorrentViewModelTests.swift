import Testing
import Foundation
@testable import BitProwler

@MainActor
struct AddTorrentViewModelTests {
    
    var mockService: MockQBittorrentService
    var mockManager: GenericServerManager<QBittorrentServer>
    var pathsManager: RecentPathsManager
    var viewModel: AddTorrentViewModel
    
    init() {
        mockService = MockQBittorrentService()
        
        let testDefaults = UserDefaults(suiteName: "AddTorrentViewModelTests")!
        testDefaults.removePersistentDomain(forName: "AddTorrentViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        pathsManager = RecentPathsManager(userDefaults: testDefaults)
        
        viewModel = AddTorrentViewModel(
            qbittorrentManager: mockManager,
            recentPathsManager: pathsManager,
            apiService: mockService
        )
    }
    
    @Test func validationFailsWithoutServer() {
        #expect(viewModel.canAddTorrent == false)
    }
    
    @Test func validationFailsWithEmptyMagnet() {
        let server = QBittorrentServer(name: "S", url: "u", username: "u", password: "p")
        mockManager.addServer(server)
        
        viewModel.isMagnetLink = true
        viewModel.magnetUrl = ""
        
        #expect(viewModel.canAddTorrent == false)
    }
    
    @Test func validationSuccess() {
        let server = QBittorrentServer(name: "S", url: "u", username: "u", password: "p")
        mockManager.addServer(server)
        
        viewModel.isMagnetLink = true
        viewModel.magnetUrl = "magnet:?xt=urn:btih:123"
        viewModel.downloadPath = "/downloads"
        
        #expect(viewModel.canAddTorrent == true)
    }
    
    @Test func addMagnetLinkSuccess() async {
        let server = QBittorrentServer(name: "S", url: "u", username: "u", password: "p")
        mockManager.addServer(server)
        
        viewModel.magnetUrl = "magnet:?xt=urn:btih:test"
        viewModel.downloadPath = "/custom/path"
        
        await viewModel.addTorrent()
        
        #expect(mockService.lastAddedTorrentSource != nil)
        #expect(mockService.lastAddedSavePath == "/custom/path")
        #expect(viewModel.shouldDismiss == true)
        
        #expect(pathsManager.paths.contains { $0.path == "/custom/path" })
    }
    
    @Test func addTorrentFileSuccess() async {
        let server = QBittorrentServer(name: "S", url: "u", username: "u", password: "p")
        mockManager.addServer(server)
        
        viewModel.isMagnetLink = false
        viewModel.torrentFile = "dummy_data".data(using: .utf8)
        viewModel.selectedFileName = "test.torrent"
        viewModel.downloadPath = "/downloads"
        
        await viewModel.addTorrent()
        
        if case .file(let data, let filename) = mockService.lastAddedTorrentSource {
            #expect(filename == "test.torrent")
            #expect(data == "dummy_data".data(using: .utf8))
        } else {
            #expect(Bool(false), "Expected file source")
        }
        
        #expect(viewModel.shouldDismiss == true)
    }
    
    @Test func addTorrentFails() async {
        let server = QBittorrentServer(name: "S", url: "u", username: "u", password: "p")
        mockManager.addServer(server)
        
        mockService.errorToThrow = AppError.unknownError
        viewModel.magnetUrl = "magnet:..."
        
        await viewModel.addTorrent()
        
        #expect(viewModel.showError == true)
        #expect(viewModel.shouldDismiss == false)
    }
}