import Testing
import Foundation
@testable import BitProwler

struct TorrentResultTests {

    @Test func decodeValidJSON() throws {
        let json = """
        [
            {
                "guid": "magnet:?xt=urn:btih:12345",
                "title": "Ubuntu 24.04 ISO",
                "size": 4500000000,
                "seeders": 150,
                "leechers": 10,
                "indexer": "LinuxTracker",
                "publishDate": "2025-10-01T12:00:00Z"
            }
        ]
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let results = try decoder.decode([TorrentResult].self, from: json)
        
        #expect(results.count == 1)
        let result = results.first!
        
        #expect(result.title == "Ubuntu 24.04 ISO")
        #expect(result.size == 4500000000)
        #expect(result.seeders == 150)
        #expect(result.isDownloadable == true)
    }

    @Test func decodeJSONWithStringNumbers() throws {
        let json = """
        [
            {
                "guid": "http://torrent.file",
                "title": "Debian ISO",
                "size": "2048",
                "seeders": "50",
                "leechers": "5",
                "indexer": "Test",
                "publishDate": "2025-01-01"
            }
        ]
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let results = try decoder.decode([TorrentResult].self, from: json)
        let result = results.first!
        
        #expect(result.size == 2048)
        #expect(result.seeders == 50)
    }
}