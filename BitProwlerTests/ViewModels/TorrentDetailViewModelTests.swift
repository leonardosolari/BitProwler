import Testing
import Foundation
@testable import BitProwler

@MainActor
struct TorrentDetailViewModelTests {
    
    var mockService: MockQBittorrentService
    var mockManager: GenericServerManager<QBittorrentServer>
    var viewModel: TorrentDetailViewModel
    var result: TorrentResult
    
    init() {
        mockService = MockQBittorrentService()
        
        let testDefaults = UserDefaults(suiteName: "TorrentDetailViewModelTests")!
        testDefaults.removePersistentDomain(forName: "TorrentDetailViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        let server = QBittorrentServer(name: "QB", url: "http://qb", username: "admin", password: "pw")
        mockManager.addServer(server)
        
        result = TorrentResult(
            id: "magnet:?xt=urn:btih:test",
            title: "Linux ISO",
            size: 1024,
            seeders: 100,
            leechers: 5,
            downloadUrl: nil,
            magnetUrl: "magnet:?xt=urn:btih:test",
            infoUrl: nil,
            indexer: "Tracker",
            publishDate: "2025-01-01"
        )
        
        viewModel = TorrentDetailViewModel(
            result: result,
            qbittorrentManager: mockManager,
            apiService: mockService
        )
    }
    
    @Test func downloadTorrentSuccess() async {
        await viewModel.downloadTorrent()
        
        #expect(mockService.lastAddedTorrentSource != nil)
        
        if case .url(let url) = mockService.lastAddedTorrentSource {
            #expect(url == "magnet:?xt=urn:btih:test")
        } else {
            #expect(Bool(false), "Expected URL source")
        }
        
        #expect(viewModel.showSuccessAlert == true)
        #expect(viewModel.error == nil)
    }
    
    @Test func downloadTorrentFailsNoServer() async {
        mockManager.deleteServer(at: IndexSet(integer: 0))
        
        await viewModel.downloadTorrent()
        
        #expect(viewModel.error == AppError.serverNotConfigured)
        #expect(viewModel.showSuccessAlert == false)
    }
    
    @Test func downloadTorrentNetworkError() async {
        mockService.errorToThrow = AppError.invalidURL
        
        await viewModel.downloadTorrent()
        
        #expect(viewModel.error == AppError.invalidURL)
        #expect(viewModel.showSuccessAlert == false)
    }
}