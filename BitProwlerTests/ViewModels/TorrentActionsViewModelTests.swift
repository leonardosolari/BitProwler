import Testing
import Foundation
@testable import BitProwler

@MainActor
struct TorrentActionsViewModelTests {
    
    var mockService: MockQBittorrentService
    var mockManager: GenericServerManager<QBittorrentServer>
    var viewModel: TorrentActionsViewModel
    var torrent: QBittorrentTorrent
    
    init() {
        mockService = MockQBittorrentService()
        
        let testDefaults = UserDefaults(suiteName: "TorrentActionsViewModelTests")!
        testDefaults.removePersistentDomain(forName: "TorrentActionsViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        let server = QBittorrentServer(name: "QB", url: "http://qb", username: "admin", password: "pw")
        mockManager.addServer(server)
        
        torrent = QBittorrentTorrent(
            name: "Test Torrent",
            size: 1000,
            progress: 0.5,
            downloadSpeed: 0,
            uploadSpeed: 0,
            state: "downloading",
            hash: "hash123",
            numSeeds: 0,
            numLeechs: 0,
            ratio: 0,
            eta: 0,
            savePath: "/downloads"
        )
        
        viewModel = TorrentActionsViewModel(
            torrent: torrent,
            manager: mockManager,
            apiService: mockService
        )
    }
    
    @Test func pauseTorrent() async {
        await viewModel.performAction(.togglePauseResume) { }
        
        #expect(mockService.lastAction == .togglePauseResume)
        #expect(mockService.lastActionHash == "hash123")
        #expect(viewModel.showError == false)
    }
    
    @Test func deleteTorrentWithData() async {
        await viewModel.performAction(.delete, deleteFiles: true) { }
        
        #expect(mockService.lastAction == .delete)
        #expect(mockService.lastActionHash == "hash123")
    }
    
    @Test func computedPropertiesState() {
        #expect(viewModel.isPaused == false)
        #expect(viewModel.isForced == false)
        
        let pausedTorrent = QBittorrentTorrent(
            name: "Paused", size: 0, progress: 0, downloadSpeed: 0, uploadSpeed: 0,
            state: "pausedDL", hash: "h2", numSeeds: 0, numLeechs: 0, ratio: 0, eta: 0, savePath: ""
        )
        
        let pausedVM = TorrentActionsViewModel(
            torrent: pausedTorrent,
            manager: mockManager,
            apiService: mockService
        )
        
        #expect(pausedVM.isPaused == true)
    }
    
    @Test func actionFailsWithNetworkError() async {
        mockService.errorToThrow = AppError.httpError(statusCode: 500)
        
        await viewModel.performAction(.recheck) { }
        
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage != nil)
    }
}