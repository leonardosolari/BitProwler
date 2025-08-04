import Foundation

class ProwlarrService: BaseNetworkService, ProwlarrAPIService {
    
    func search(query: String, on server: ProwlarrServer) async throws -> [TorrentResult] {
        let url = try buildURL(from: server.url, path: "api/v1/search", queryItems: [
            URLQueryItem(name: "query", value: query)
        ])
        
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
        do {
            let url = try buildURL(from: server.url, path: "api/v1/system/status")
            var request = URLRequest(url: url)
            request.setValue(server.apiKey, forHTTPHeaderField: "X-Api-Key")
            _ = try await performRequest(request)
            return true
        } catch {
            return false
        }
    }
}