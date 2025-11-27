import Testing
import Foundation
@testable import BitProwler

@MainActor
@Suite(.serialized)
struct NetworkIntegrationTests {
    
    let prowlarrService: ProwlarrService
    let qbittorrentService: QBittorrentService
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        self.prowlarrService = ProwlarrService(urlSession: mockSession)
        self.qbittorrentService = QBittorrentService(urlSession: mockSession)
    }
    
    @Test func prowlarrSearchParsing() async throws {
        let jsonResponse = """
        [
            {
                "guid": "magnet:?xt=urn:btih:123456",
                "title": "Ubuntu 24.04 LTS",
                "size": 4500000000,
                "seeders": 1500,
                "leechers": 50,
                "indexer": "LinuxTracker",
                "publishDate": "2025-01-01T12:00:00Z",
                "infoUrl": "https://linux.org"
            }
        ]
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v1/search") else {
                throw URLError(.badURL)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, jsonResponse)
        }
        
        let server = ProwlarrServer(name: "Test", url: "http://prowlarr.local", apiKey: "key")
        let results = try await prowlarrService.search(query: "Ubuntu", on: server)
        
        #expect(results.count == 1)
        #expect(results.first?.title == "Ubuntu 24.04 LTS")
    }
    
    @Test func prowlarrServerError() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = ProwlarrServer(name: "Test", url: "http://prowlarr.local", apiKey: "key")
        
        await #expect(throws: AppError.httpError(statusCode: 500)) {
            try await prowlarrService.search(query: "Ubuntu", on: server)
        }
    }
    
    @Test func qbittorrentGetTorrentsParsing() async throws {
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
        
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, jsonResponse)
        }
        
        let server = QBittorrentServer(name: "QB", url: "http://qb.local", username: "u", password: "p")
        let torrents = try await qbittorrentService.getTorrents(on: server)
        
        #expect(torrents.count == 1)
        #expect(torrents.first?.name == "Big Buck Bunny")
    }
    
    @Test func qbittorrentAuthRetryFlow() async throws {
        class Counter { var value = 0 }
        let requestCount = Counter()
        
        MockURLProtocol.requestHandler = { request in
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
    
    @Test func qbittorrentNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
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
    
    @Test func qbittorrentDecodingError() async {
        let invalidJson = "{ \"invalid\": ".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
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
}