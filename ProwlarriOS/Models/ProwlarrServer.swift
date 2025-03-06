import Foundation

struct ProwlarrServer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var apiKey: String
    
    init(id: UUID = UUID(), name: String, url: String, apiKey: String) {
        self.id = id
        self.name = name
        self.url = url
        self.apiKey = apiKey
    }
} 