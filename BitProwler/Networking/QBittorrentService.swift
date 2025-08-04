import Foundation

class QBittorrentService: BaseNetworkService, QBittorrentAPIService {
    
    func getTorrents(on server: QBittorrentServer) async throws -> [QBittorrentTorrent] {
        let url = try buildURL(from: server.url, path: "api/v2/torrents/info")
        let (data, _) = try await performQBittorrentRequest(URLRequest(url: url), on: server)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([QBittorrentTorrent].self, from: data)
        } catch {
            throw AppError.decodingError(underlyingError: error)
        }
    }
    
    func addTorrent(url torrentUrl: String, on server: QBittorrentServer) async throws {
        let source = TorrentSource.url(torrentUrl)
        try await addTorrent(from: source, savePath: "", on: server)
    }
    
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws {
        let url = try buildURL(from: server.url, path: "api/v2/torrents/add")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if !savePath.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"savepath\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(savePath)\r\n".data(using: .utf8)!)
        }
        
        switch source {
        case .url(let magnetUrl):
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"urls\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(magnetUrl)\r\n".data(using: .utf8)!)
        case .file(let data, let filename):
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"torrents\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/x-bittorrent\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        _ = try await performQBittorrentRequest(request, on: server)
    }
    
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool, forceStart: Bool?) async throws {
        var endpoint: String
        var bodyParams: [String: String] = ["hashes": torrent.hash]
        
        switch action {
        case .togglePauseResume:
            let state = TorrentState(from: torrent.state)
            endpoint = state.isPaused ? "resume" : "pause"
        case .delete:
            endpoint = "delete"
            bodyParams["deleteFiles"] = String(deleteFiles)
        case .move:
            guard let location = location else { throw AppError.unknownError }
            endpoint = "setLocation"
            bodyParams["location"] = location
        case .forceStart:
            guard let enable = forceStart else { throw AppError.unknownError }
            endpoint = "setForceStart"
            bodyParams["value"] = String(enable)
        case .recheck:
            endpoint = "recheck"
        }
        
        let url = try buildURL(from: server.url, path: "api/v2/torrents/\(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        _ = try await performQBittorrentRequest(request, on: server)
    }
    
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile] {
        let url = try buildURL(from: server.url, path: "api/v2/torrents/files", queryItems: [
            URLQueryItem(name: "hash", value: torrent.hash)
        ])
        
        let (data, _) = try await performQBittorrentRequest(URLRequest(url: url), on: server)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([TorrentFile].self, from: data)
        } catch {
            throw AppError.decodingError(underlyingError: error)
        }
    }
    
    func testConnection(to server: QBittorrentServer) async -> Bool {
        do {
            let testSession = URLSession(configuration: .ephemeral)
            try await login(to: server, using: testSession)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private QBittorrent Helpers
    
    private func login(to server: QBittorrentServer, using session: URLSession? = nil) async throws {
        let url = try buildURL(from: server.url, path: "api/v2/auth/login")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let credentials = "username=\(server.username)&password=\(server.password)"
        request.httpBody = credentials.data(using: .utf8)
        
        let sessionToUse = session ?? self.urlSession
        
        do {
            _ = try await performRequest(request, using: sessionToUse)
        } catch {
            throw AppError.authenticationFailed
        }
    }
    
    private func performQBittorrentRequest(_ request: URLRequest, on server: QBittorrentServer, isRetry: Bool = false) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await performRequest(request)
        } catch let error as AppError {
            if case .httpError(let statusCode) = error, statusCode == 403, !isRetry {
                try await login(to: server)
                return try await performQBittorrentRequest(request, on: server, isRetry: true)
            }
            throw error
        }
    }
}