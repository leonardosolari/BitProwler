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
        
        // Verify path is saved to recent history
        #expect(pathsManager.paths.contains { $0.path == "/custom/path" })
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