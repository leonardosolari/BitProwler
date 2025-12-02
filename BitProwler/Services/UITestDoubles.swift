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
    var searchResult: Result<[TorrentResult], AppError> = .success([])
    var connectionResult = true
    
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return try searchResult.get()
    }
    
    func testConnection(to server: ProwlarrServer) async -> Bool {
        return connectionResult
    }
}

class StubQBittorrentService: QBittorrentAPIService {
    var torrents: [QBittorrentTorrent] = []
    var filesResult: Result<[TorrentFile], AppError> = .success([])
    var errorToReturn: AppError?
    
    var connectionResult = true
    var actionShouldSucceed = true
    
    func getTorrents(on server: QBittorrentServer, filter: String?, sort: String?) async throws -> [QBittorrentTorrent] {
        try await Task.sleep(nanoseconds: 500_000_000)
        if let error = errorToReturn {
            throw error
        }
        return torrents
    }
    
    func addTorrent(url: String, on server: QBittorrentServer) async throws {
        if !actionShouldSucceed { throw AppError.unknownError }
    }
    
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws {
        if !actionShouldSucceed { throw AppError.unknownError }
    }
    
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool, forceStart: Bool?) async throws {
        guard actionShouldSucceed, let index = torrents.firstIndex(where: { $0.hash == torrent.hash }) else {
            if !actionShouldSucceed { throw AppError.unknownError }
            return
        }
        
        switch action {
        case .togglePauseResume:
            let currentState = TorrentState(from: torrents[index].state)
            torrents[index].state = currentState.isPaused ? "downloading" : "pausedDL"
        case .delete:
            torrents.remove(at: index)
        case .move:
            if let location = location {
                torrents[index].savePath = location
            }
        case .forceStart:
            let enable = forceStart ?? false
            torrents[index].state = enable ? "forcedDL" : "downloading"
        case .recheck:
            torrents[index].state = "checkingDL"
        }
    }
    
    func setFilePriority(for torrent: QBittorrentTorrent, on server: QBittorrentServer, fileIds: [String], priority: Int) async throws {
        if !actionShouldSucceed { throw AppError.unknownError }
    }
    
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile] {
        return try filesResult.get()
    }
    
    func testConnection(to server: QBittorrentServer) async -> Bool {
        return connectionResult
    }
}