import Foundation

struct ProwlarrServer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var apiKey: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
    }
    
    init(id: UUID = UUID(), name: String, url: String, apiKey: String) {
        self.id = id
        self.name = name
        self.url = url
        self.apiKey = apiKey
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(String.self, forKey: .url)
        // Inizializziamo apiKey come stringa vuota. Verrà popolata dal Keychain in un secondo momento.
        self.apiKey = ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
    }
}