import Foundation

protocol ProwlarrAPIService {
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult]
    func testConnection(to server: ProwlarrServer) async -> Bool
}

protocol QBittorrentAPIService {
    func getTorrents(on server: QBittorrentServer, filter: String?, sort: String?) async throws -> [QBittorrentTorrent]
    func addTorrent(url: String, on server: QBittorrentServer) async throws
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool, forceStart: Bool?) async throws
    func setFilePriority(for torrent: QBittorrentTorrent, on server: QBittorrentServer, fileIds: [String], priority: Int) async throws
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile]
    func testConnection(to server: QBittorrentServer) async -> Bool
}