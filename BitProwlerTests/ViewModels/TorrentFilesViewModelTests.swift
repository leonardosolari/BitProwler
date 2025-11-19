import Testing
import Foundation
@testable import BitProwler

@MainActor
struct TorrentFilesViewModelTests {
    
    var mockService: MockQBittorrentService
    var mockManager: GenericServerManager<QBittorrentServer>
    var viewModel: TorrentFilesViewModel
    var torrent: QBittorrentTorrent
    
    init() {
        mockService = MockQBittorrentService()
        
        let testDefaults = UserDefaults(suiteName: "TorrentFilesViewModelTests")!
        testDefaults.removePersistentDomain(forName: "TorrentFilesViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        let server = QBittorrentServer(name: "QB", url: "http://qb", username: "admin", password: "pw")
        mockManager.addServer(server)
        
        torrent = QBittorrentTorrent(
            name: "Test", size: 0, progress: 0, downloadSpeed: 0, uploadSpeed: 0,
            state: "dl", hash: "hash123", numSeeds: 0, numLeechs: 0, ratio: 0, eta: 0, savePath: ""
        )
        
        viewModel = TorrentFilesViewModel(
            torrent: torrent,
            qbittorrentManager: mockManager,
            apiService: mockService
        )
    }
    
    @Test func fetchFilesBuildsTreeCorrectly() async {
        let files = [
            TorrentFile(index: 0, name: "Folder/File1.txt", size: 100, progress: 1.0, priority: 1),
            TorrentFile(index: 1, name: "Folder/File2.txt", size: 200, progress: 0.5, priority: 1),
            TorrentFile(index: 2, name: "RootFile.mkv", size: 500, progress: 0.0, priority: 0)
        ]
        
        mockService.filesToReturn = files
        
        await viewModel.fetchFiles()
        
        #expect(viewModel.fileTree.count == 2)
        
        let folderNode = viewModel.fileTree.first { $0.name == "Folder" }
        #expect(folderNode != nil)
        #expect(folderNode?.children?.count == 2)
        
        let rootFileNode = viewModel.fileTree.first { $0.name == "RootFile.mkv" }
        #expect(rootFileNode != nil)
        #expect(rootFileNode?.file?.size == 500)
    }
    
    @Test func fetchFilesError() async {
        mockService.errorToThrow = AppError.httpError(statusCode: 404)
        
        await viewModel.fetchFiles()
        
        #expect(viewModel.fileTree.isEmpty)
        #expect(viewModel.error != nil)
    }
    
    @Test func saveChangesNoChanges() async {
        let file = TorrentFile(index: 0, name: "A.txt", size: 10, progress: 0, priority: 1)
        mockService.filesToReturn = [file]
        await viewModel.fetchFiles()
        
        let success = await viewModel.saveChanges()
        
        #expect(success == true)
        // No API call should be made because priority didn't change
    }
}