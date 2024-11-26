import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchResults: [TorrentResult] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    func search(query: String, settings: ProwlarrSettings) async {
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.isLoading = false
                self.hasSearched = false
            }
            return
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(settings.serverUrl)api/v1/search?query=\(encodedQuery)") else {
            await MainActor.run {
                self.errorMessage = "URL non valido"
                self.showError = true
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        var request = URLRequest(url: url)
        request.setValue(settings.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 401:
                    throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key non valida"])
                case 404:
                    throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Server non trovato"])
                case 200: break
                default:
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Errore del server (\(httpResponse.statusCode))"])
                }
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Risposta JSON ricevuta:", jsonString)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            
            do {
                let results = try decoder.decode([TorrentResult].self, from: data)
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                    self.hasSearched = true
                }
            } catch {
                print("Errore di decodifica:", error)
                throw error
            }
            
        } catch {
            await MainActor.run {
                self.searchResults = []
                self.errorMessage = "Errore: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
                self.hasSearched = true
            }
        }
    }
}