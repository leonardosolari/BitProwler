import Foundation

final class StubKeychain: KeychainProtocol {
    private var storage: [String: String] = [:]
    
    func save(key: String, value: String) throws {
        storage[key] = value
    }
    
    func get(key: String) -> String? {
        return storage[key]
    }
    
    func delete(key: String) throws {
        storage.removeValue(forKey: key)
    }
    
    func clearAll() throws {
        storage.removeAll()
    }
}

class StubProwlarrService: ProwlarrAPIService {
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult] {
        return []
    }
    
    func testConnection(to server: ProwlarrServer) async -> Bool {
        return true
    }
}

class StubQBittorrentService: QBittorrentAPIService {
    func getTorrents(on server: QBittorrentServer, filter: String?, sort: String?) async throws -> [QBittorrentTorrent] {
        return []
    }
    
    func addTorrent(url: String, on server: QBittorrentServer) async throws {}
    
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws {}
    
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool, forceStart: Bool?) async throws {}
    
    func setFilePriority(for torrent: QBittorrentTorrent, on server: QBittorrentServer, fileIds: [String], priority: Int) async throws {}
    
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile] {
        return []
    }
    
    func testConnection(to server: QBittorrentServer) async -> Bool {
        return true
    }
}