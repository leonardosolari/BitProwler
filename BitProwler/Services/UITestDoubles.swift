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
        try await Task.sleep(nanoseconds: 3_500_000_000)
        return try searchResult.get()
    }
    
    func testConnection(to server: ProwlarrServer) async -> Bool {
        return connectionResult
    }
}

class StubQBittorrentService: QBittorrentAPIService {
    var torrents: [QBittorrentTorrent] = []
    var files: [TorrentFile] = []
    var errorToReturn: AppError?
    
    var connectionResult = true
    var actionShouldSucceed = true
    
    var lastPriorityUpdate: (hash: String, ids: [String], priority: Int)?
    
    var addableTorrents: [String: QBittorrentTorrent] = [:]
    var torrentFromFile: QBittorrentTorrent?
    
    func getTorrents(on server: QBittorrentServer, filter: String?, sort: String?) async throws -> [QBittorrentTorrent] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        if let error = errorToReturn {
            throw error
        }
        
        var processedTorrents = self.torrents
        
        if let filter = filter, !filter.isEmpty {
            processedTorrents = processedTorrents.filter {
                $0.name.localizedCaseInsensitiveContains(filter)
            }
        }
        
        if let sortKey = sort {
            switch sortKey {
            case "name":
                processedTorrents.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case "progress":
                processedTorrents.sort { $0.progress < $1.progress }
            case "dlspeed":
                processedTorrents.sort { $0.downloadSpeed < $1.downloadSpeed }
            case "upspeed":
                processedTorrents.sort { $0.uploadSpeed < $1.uploadSpeed }
            case "size":
                processedTorrents.sort { $0.size < $1.size }
            case "state":
                processedTorrents.sort { $0.state.localizedCaseInsensitiveCompare($1.state) == .orderedAscending }
            default:
                break
            }
        }
        
        return processedTorrents
    }
    
    func addTorrent(url: String, on server: QBittorrentServer) async throws {
        if !actionShouldSucceed { throw AppError.unknownError }
        
        if let torrentToAdd = addableTorrents[url] {
            if !self.torrents.contains(where: { $0.hash == torrentToAdd.hash }) {
                self.torrents.append(torrentToAdd)
            }
        }
    }
    
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws {
        if !actionShouldSucceed { throw AppError.unknownError }
        
        switch source {
        case .url(let urlString):
            if let torrentToAdd = addableTorrents[urlString] {
                if !self.torrents.contains(where: { $0.hash == torrentToAdd.hash }) {
                    self.torrents.append(torrentToAdd)
                }
            }
        case .file:
            if let torrentToAdd = torrentFromFile {
                if !self.torrents.contains(where: { $0.hash == torrentToAdd.hash }) {
                    self.torrents.append(torrentToAdd)
                }
            }
        }
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
        lastPriorityUpdate = (hash: torrent.hash, ids: fileIds, priority: priority)
    }
    
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile] {
        if let error = errorToReturn {
            throw error
        }
        return files
    }
    
    func testConnection(to server: QBittorrentServer) async -> Bool {
        return connectionResult
    }
}