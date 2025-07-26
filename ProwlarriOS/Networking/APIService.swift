// File: /ProwlarriOS/Networking/APIService.swift

import Foundation

// Protocollo per le operazioni di Prowlarr
protocol ProwlarrAPIService {
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult]
    func testConnection(to server: ProwlarrServer) async -> Bool
}

// Protocollo per le operazioni di qBittorrent
protocol QBittorrentAPIService {
    func getTorrents(on server: QBittorrentServer) async throws -> [QBittorrentTorrent]
    func addTorrent(url: String, on server: QBittorrentServer) async throws
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws
    // FIRMA AGGIORNATA
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool, forceStart: Bool?) async throws
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile]
    func testConnection(to server: QBittorrentServer) async -> Bool
}

// Un protocollo combinato per convenienza, se un oggetto li implementa entrambi
typealias APIService = ProwlarrAPIService & QBittorrentAPIService