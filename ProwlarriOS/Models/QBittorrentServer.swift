import Foundation

struct QBittorrentServer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var username: String
    var password: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case username
    }
    
    init(id: UUID = UUID(), name: String, url: String, username: String, password: String) {
        self.id = id
        self.name = name
        self.url = url
        self.username = username
        self.password = password
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(String.self, forKey: .url)
        self.username = try container.decode(String.self, forKey: .username)
        // Inizializziamo la password come stringa vuota. Verrà popolata dal Keychain.
        self.password = ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(username, forKey: .username)
    }
}