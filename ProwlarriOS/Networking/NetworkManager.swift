import Foundation

class NetworkManager: APIService {
    
    private let urlSession: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - ProwlarrAPIService
    
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(server.url)api/v1/search?query=\(encodedQuery)") else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(server.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await performRequest(request)
        
        do {
            return try JSONDecoder().decode([TorrentResult].self, from: data)
        } catch {
            throw AppError.decodingError(underlyingError: error)
        }
    }
    
    func testConnection(to server: ProwlarrServer) async -> Bool {
        guard let url = URL(string: "\(server.url)api/v1/system/status") else { return false }
        var request = URLRequest(url: url)
        request.setValue(server.apiKey, forHTTPHeaderField: "X-Api-Key")
        
        do {
            _ = try await performRequest(request)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - QBittorrentAPIService
    
    func getTorrents(on server: QBittorrentServer) async throws -> [QBittorrentTorrent] {
        try await login(to: server)
        guard let url = URL(string: "\(server.url)api/v2/torrents/info") else { throw AppError.invalidURL }
        
        let (data, _) = try await performRequest(URLRequest(url: url))
        
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return jsonArray.map { QBittorrentTorrent(from: $0) }
        } else {
            throw AppError.decodingError(underlyingError: NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format for torrents"]))
        }
    }
    
    func addTorrent(url torrentUrl: String, on server: QBittorrentServer) async throws {
        // Questo metodo è una versione semplificata per TorrentDetailView
        let source = TorrentSource.url(torrentUrl)
        try await addTorrent(from: source, savePath: "", on: server)
    }
    
    func addTorrent(from source: TorrentSource, savePath: String, on server: QBittorrentServer) async throws {
        try await login(to: server)
        guard let url = URL(string: "\(server.url)api/v2/torrents/add") else { throw AppError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Aggiungi il percorso di download se specificato
        if !savePath.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"savepath\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(savePath)\r\n".data(using: .utf8)!)
        }
        
        // Aggiungi la sorgente del torrent
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
        
        _ = try await performRequest(request)
    }
    
    func performAction(_ action: TorrentActionsViewModel.TorrentAction, for torrent: QBittorrentTorrent, on server: QBittorrentServer, location: String?, deleteFiles: Bool) async throws {
        try await login(to: server)
        
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
        }
        
        guard let url = URL(string: "\(server.url)api/v2/torrents/\(endpoint)") else { throw AppError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        _ = try await performRequest(request)
    }
    
    func getFiles(for torrent: QBittorrentTorrent, on server: QBittorrentServer) async throws -> [TorrentFile] {
        try await login(to: server)
        guard let url = URL(string: "\(server.url)api/v2/torrents/files?hash=\(torrent.hash)") else { throw AppError.invalidURL }
        
        let (data, _) = try await performRequest(URLRequest(url: url))
        
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return jsonArray.map { TorrentFile(from: $0) }
        } else {
            throw AppError.decodingError(underlyingError: NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format for files"]))
        }
    }
    
    func testConnection(to server: QBittorrentServer) async -> Bool {
        do {
            let testSession = URLSession(configuration: .ephemeral)
            try await login(to: server, using: testSession, rethrow: false)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func login(to server: QBittorrentServer, using session: URLSession? = nil, rethrow: Bool = true) async throws {
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else { throw AppError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let credentials = "username=\(server.username)&password=\(server.password)"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let sessionToUse = session ?? self.urlSession
            _ = try await performRequest(request, using: sessionToUse)
        } catch {
            if rethrow {
                throw AppError.authenticationFailed
            } else {
                throw error
            }
        }
    }
    
    private func performRequest(_ request: URLRequest, using session: URLSession? = nil) async throws -> (Data, HTTPURLResponse) {
        do {
            let sessionToUse = session ?? self.urlSession
            let (data, response) = try await sessionToUse.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.unknownError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.httpError(statusCode: httpResponse.statusCode)
            }
            
            return (data, httpResponse)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.networkError(underlyingError: error)
        }
    }
}