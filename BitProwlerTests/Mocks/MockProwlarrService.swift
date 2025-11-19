import Foundation
@testable import BitProwler

final class MockProwlarrService: ProwlarrAPIService {
    var searchResultToReturn: [TorrentResult] = []
    var errorToThrow: Error?
    var connectionTestResult = true
    
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult] {
        if let error = errorToThrow {
            throw error
        }
        return searchResultToReturn
    }
    
    func testConnection(to server: ProwlarrServer) async -> Bool {
        return connectionTestResult
    }
}