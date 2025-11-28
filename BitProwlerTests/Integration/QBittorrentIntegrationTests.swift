import Testing
import Foundation
@testable import BitProwler

@MainActor
@Suite(.serialized)
struct QBittorrentIntegrationTests {
    
    let qbittorrentService: QBittorrentService
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [QBittorrentMockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        self.qbittorrentService = QBittorrentService(urlSession: mockSession)
    }
    
    @Test func getTorrentsParsing() async throws {
        let jsonResponse = """
        [
            {
                "hash": "abc123hash",
                "name": "Big Buck Bunny",
                "size": 104857600,
                "progress": 0.45,
                "dlspeed": 500000,
                "upspeed": 10000,
                "state": "downloading",
                "num_seeds": 10,
                "num_leechs": 20,
                "ratio": 0.5,
                "eta": 300,
                "save_path": "/downloads"
            }
        ]
        """.data(using: .utf8)!
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, jsonResponse)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        let torrents = try await qbittorrentService.getTorrents(on: server)
        
        #expect(torrents.count == 1)
        #expect(torrents.first?.name == "Big Buck Bunny")
    }
    
    @Test func authRetryFlow() async throws {
        class Counter { var value = 0 }
        let requestCount = Counter()
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            requestCount.value += 1
            let url = request.url!
            
            if url.absoluteString.contains("/auth/login") {
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Set-Cookie": "SID=123"])!
                return (response, "Ok.".data(using: .utf8)!)
            }
            
            if url.absoluteString.contains("/torrents/info") {
                if requestCount.value == 1 {
                    let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!
                    return (response, Data())
                } else {
                    let json = "[]".data(using: .utf8)!
                    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    return (response, json)
                }
            }
            
            throw URLError(.badURL)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        let torrents = try await qbittorrentService.getTorrents(on: server)
        
        #expect(torrents.isEmpty)
        #expect(requestCount.value >= 3)
    }
    
    @Test func networkError() async {
        QBittorrentMockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        
        await #expect {
            try await qbittorrentService.getTorrents(on: server)
        } throws: { error in
            guard let appError = error as? AppError else { return false }
            if case .networkError = appError { return true }
            return false
        }
    }
    
    @Test func decodingError() async {
        let invalidJson = "{ \"invalid\": ".data(using: .utf8)!
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, invalidJson)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        
        await #expect {
            try await qbittorrentService.getTorrents(on: server)
        } throws: { error in
            guard let appError = error as? AppError else { return false }
            if case .decodingError = appError { return true }
            return false
        }
    }
    
    @Test func addTorrentMagnetRequestConstruction() async throws {
        let magnetLink = "magnet:?xt=urn:btih:test"
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v2/torrents/add") else {
                throw URLError(.badURL)
            }
            
            guard let bodyData = request.getBodyData(), let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw URLError(.zeroByteResource)
            }
            
            if !bodyString.contains("Content-Disposition: form-data; name=\"urls\"") ||
               !bodyString.contains(magnetLink) {
                throw URLError(.cannotParseResponse)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "Ok.".data(using: .utf8)!)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        try await qbittorrentService.addTorrent(url: magnetLink, on: server)
    }
    
    @Test func addTorrentFileRequestConstruction() async throws {
        let fileData = "dummy_file_content".data(using: .utf8)!
        let fileName = "test.torrent"
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v2/torrents/add") else {
                throw URLError(.badURL)
            }
            
            guard let bodyData = request.getBodyData(), let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw URLError(.zeroByteResource)
            }
            
            if !bodyString.contains("Content-Disposition: form-data; name=\"torrents\"; filename=\"\(fileName)\"") ||
               !bodyString.contains("Content-Type: application/x-bittorrent") ||
               !bodyString.contains("dummy_file_content") {
                throw URLError(.cannotParseResponse)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "Ok.".data(using: .utf8)!)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        
        let source = TorrentSource.file(data: fileData, filename: fileName)
        try await qbittorrentService.addTorrent(from: source, savePath: "/downloads", on: server)
    }
    
    @Test func deleteActionRequestConstruction() async throws {
        let torrent = QBittorrentTorrent(name: "Test", size: 0, progress: 0, downloadSpeed: 0, uploadSpeed: 0, state: "dl", hash: "hash123", numSeeds: 0, numLeechs: 0, ratio: 0, eta: 0, savePath: "")
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v2/torrents/delete") else {
                throw URLError(.badURL)
            }
            
            guard let bodyData = request.getBodyData(), let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw URLError(.zeroByteResource)
            }
            
            var components = URLComponents()
            components.percentEncodedQuery = bodyString
            let queryItems = components.queryItems ?? []
            
            let hashes = queryItems.first(where: { $0.name == "hashes" })?.value
            let deleteFiles = queryItems.first(where: { $0.name == "deleteFiles" })?.value
            
            if hashes != "hash123" || deleteFiles != "true" {
                throw URLError(.cannotParseResponse)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        try await qbittorrentService.performAction(.delete, for: torrent, on: server, location: nil, deleteFiles: true, forceStart: nil)
    }
    
    @Test func togglePauseRequestConstruction() async throws {
        let torrent = QBittorrentTorrent(name: "Test", size: 0, progress: 0, downloadSpeed: 0, uploadSpeed: 0, state: "downloading", hash: "hash123", numSeeds: 0, numLeechs: 0, ratio: 0, eta: 0, savePath: "")
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v2/torrents/stop") else {
                throw URLError(.badURL)
            }
            
            guard let bodyData = request.getBodyData(), let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw URLError(.zeroByteResource)
            }
            
            var components = URLComponents()
            components.percentEncodedQuery = bodyString
            let hashes = components.queryItems?.first(where: { $0.name == "hashes" })?.value
            
            if hashes != "hash123" {
                throw URLError(.cannotParseResponse)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        try await qbittorrentService.performAction(.togglePauseResume, for: torrent, on: server, location: nil, deleteFiles: false, forceStart: nil)
    }
    
    @Test func setLocationRequestConstruction() async throws {
        let torrent = QBittorrentTorrent(name: "Test", size: 0, progress: 0, downloadSpeed: 0, uploadSpeed: 0, state: "dl", hash: "hash123", numSeeds: 0, numLeechs: 0, ratio: 0, eta: 0, savePath: "")
        let newLocation = "/new/path"
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v2/torrents/setLocation") else {
                throw URLError(.badURL)
            }
            
            guard let bodyData = request.getBodyData(), let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw URLError(.zeroByteResource)
            }
            
            var components = URLComponents()
            components.percentEncodedQuery = bodyString
            let queryItems = components.queryItems ?? []
            
            let hashes = queryItems.first(where: { $0.name == "hashes" })?.value
            let location = queryItems.first(where: { $0.name == "location" })?.value
            
            if hashes != "hash123" || location != "/new/path" {
                throw URLError(.cannotParseResponse)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        try await qbittorrentService.performAction(.move, for: torrent, on: server, location: newLocation, deleteFiles: false, forceStart: nil)
    }
    
    @Test func setFilePriorityRequestConstruction() async throws {
        let torrent = QBittorrentTorrent(name: "Test", size: 0, progress: 0, downloadSpeed: 0, uploadSpeed: 0, state: "dl", hash: "hash123", numSeeds: 0, numLeechs: 0, ratio: 0, eta: 0, savePath: "")
        let fileIds = ["1", "2", "5"]
        let priority = 7
        
        QBittorrentMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v2/torrents/filePrio") else {
                throw URLError(.badURL)
            }
            
            guard let bodyData = request.getBodyData(), let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw URLError(.zeroByteResource)
            }
            
            var components = URLComponents()
            components.percentEncodedQuery = bodyString
            let queryItems = components.queryItems ?? []
            
            let hash = queryItems.first(where: { $0.name == "hash" })?.value
            let id = queryItems.first(where: { $0.name == "id" })?.value
            let prio = queryItems.first(where: { $0.name == "priority" })?.value
            
            if hash != "hash123" || id != "1|2|5" || prio != "7" {
                throw URLError(.cannotParseResponse)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        try await qbittorrentService.setFilePriority(for: torrent, on: server, fileIds: fileIds, priority: priority)
    }
}