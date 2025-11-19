import Foundation
@testable import BitProwler

final class MockQBittorrentService: QBittorrentAPIService {
    var torrentsToReturn: [QBittorrentTorrent] = []
    var filesToReturn: [TorrentFile] = []
    var errorToThrow: Error?
    var connectionTestResult = true
    
    var lastAddedTorrentSource: TorrentSource?
    var lastAddedSavePath: String?
    var lastAction: TorrentActionsViewModel.TorrentAction?
    var lastActionHash: String?
    
    func getTorrents(on server: QBittorrentServer, filter: String?, sort: String?) async throws -> [QBittorrentTorrent] {
        if let error = errorToThrow {
            throw error
        }
        return torrentsToReturn
    }
    
    func addTorrent(url: String, on server: QBittorrentServer) async throws {
        if let error = errorToThrow {
            throw error
        }
        lastAddedTorrentSource = .url(url)
        lastAddedSavePath = ""
    }
    
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws {
        if let error = errorToThrow {
            throw error
        }
        lastAddedTorrentSource = source
        lastAddedSavePath = savePath
    }
    
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool, forceStart: Bool?) async throws {
        if let error = errorToThrow {
            throw error
        }
        lastAction = action
        lastActionHash = torrent.hash
    }
    
    func setFilePriority(for torrent: QBittorrentTorrent, on server: QBittorrentServer, fileIds: [String], priority: Int) async throws {
        if let error = errorToThrow {
            throw error
        }
    }
    
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile] {
        if let error = errorToThrow {
            throw error
        }
        return filesToReturn
    }
    
    func testConnection(to server: QBittorrentServer) async -> Bool {
        return connectionTestResult
    }
}