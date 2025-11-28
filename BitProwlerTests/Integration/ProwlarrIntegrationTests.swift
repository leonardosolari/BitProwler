import Testing
import Foundation
@testable import BitProwler

@MainActor
@Suite(.serialized)
struct ProwlarrIntegrationTests {
    
    let prowlarrService: ProwlarrService
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ProwlarrMockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        self.prowlarrService = ProwlarrService(urlSession: mockSession)
    }
    
    @Test func searchParsing() async throws {
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
        
        ProwlarrMockURLProtocol.requestHandler = { request in
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
    
    @Test func serverError() async {
        ProwlarrMockURLProtocol.requestHandler = { request in
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = ProwlarrServer(name: "Test", url: "http://prowlarr.local", apiKey: "key")
        
        await #expect(throws: AppError.httpError(statusCode: 500)) {
            try await prowlarrService.search(query: "Ubuntu", on: server)
        }
    }
    
    @Test func connectionTestSuccess() async {
        ProwlarrMockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString.contains("/api/v1/system/status") else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = ProwlarrServer(name: "Test", url: "http://prowlarr.local", apiKey: "key")
        let result = await prowlarrService.testConnection(to: server)
        
        #expect(result == true)
    }
    
    @Test func connectionTestFailure() async {
        ProwlarrMockURLProtocol.requestHandler = { request in
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let server = ProwlarrServer(name: "Test", url: "http://prowlarr.local", apiKey: "wrong_key")
        let result = await prowlarrService.testConnection(to: server)
        
        #expect(result == false)
    }
}