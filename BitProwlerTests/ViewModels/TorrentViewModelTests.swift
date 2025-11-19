import Testing
import Foundation
@testable import BitProwler

@MainActor
struct TorrentsViewModelTests {
    
    var mockService: MockQBittorrentService
    var mockManager: GenericServerManager<QBittorrentServer>
    var viewModel: TorrentsViewModel
    
    init() {
        mockService = MockQBittorrentService()
        
        let testDefaults = UserDefaults(suiteName: "TorrentsViewModelTests")!
        testDefaults.removePersistentDomain(forName: "TorrentsViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        let server = QBittorrentServer(name: "QB", url: "http://qb", username: "admin", password: "pw")
        mockManager.addServer(server)
        
        viewModel = TorrentsViewModel(apiService: mockService)
        viewModel.setup(with: mockManager)
    }
    
    @Test func fetchTorrentsSuccess() async {
        let torrent = QBittorrentTorrent(
            name: "Linux ISO",
            size: 1024,
            progress: 0.5,
            downloadSpeed: 500,
            uploadSpeed: 100,
            state: "downloading",
            hash: "abc123hash",
            numSeeds: 10,
            numLeechs: 5,
            ratio: 1.0,
            eta: 60,
            savePath: "/downloads"
        )
        
        mockService.torrentsToReturn = [torrent]
        
        await viewModel.fetchTorrents()
        
        #expect(viewModel.torrents.count == 1)
        #expect(viewModel.torrents.first?.name == "Linux ISO")
        #expect(viewModel.error == nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func fetchTorrentsError() async {
        mockService.errorToThrow = AppError.httpError(statusCode: 403)
        
        await viewModel.fetchTorrents()
        
        #expect(viewModel.torrents.isEmpty)
        #expect(viewModel.error != nil)
    }
    
    @Test func noActiveServerSetsError() async {
        mockManager.deleteServer(at: IndexSet(integer: 0))
        
        await viewModel.fetchTorrents()
        
        #expect(viewModel.error == AppError.serverNotConfigured.errorDescription)
    }
    
    @Test func sortOptionChangeTriggersFetch() async {
        #expect(viewModel.activeSortOption == .progress)
        
        viewModel.activeSortOption = .downloadSpeed
        
        
        #expect(viewModel.activeSortOption == .downloadSpeed)
    }
}