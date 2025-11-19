import Testing
import Foundation
@testable import BitProwler

@MainActor
struct TorrentsViewModelTests {
    
    var mockService: MockQBittorrentService
    var mockManager: GenericServerManager<QBittorrentServer>
    var viewModel: TorrentsViewModel
    var testDefaults: UserDefaults // Teniamo un riferimento per verifica extra se necessario
    
    init() {
        mockService = MockQBittorrentService()
        
        // Creiamo UserDefaults isolati per questo test suite
        testDefaults = UserDefaults(suiteName: "TorrentsViewModelTests")!
        testDefaults.removePersistentDomain(forName: "TorrentsViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        let server = QBittorrentServer(name: "QB", url: "http://qb", username: "admin", password: "pw")
        mockManager.addServer(server)
        
        // INIEZIONE IMPORTANTE: passiamo testDefaults qui
        viewModel = TorrentsViewModel(apiService: mockService, userDefaults: testDefaults)
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
        // Verify default (Dovrebbe essere .progress perché testDefaults è vuoto all'avvio)
        #expect(viewModel.activeSortOption == .progress)
        
        // Change sort
        viewModel.activeSortOption = .downloadSpeed
        
        // Verify persistence
        #expect(viewModel.activeSortOption == .downloadSpeed)
        #expect(testDefaults.string(forKey: "torrentsViewSortOption") == "Download Speed")
    }
}