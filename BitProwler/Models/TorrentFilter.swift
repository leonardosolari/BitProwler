import Foundation

struct TorrentFilter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var keyword: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, keyword: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.keyword = keyword
        self.isEnabled = isEnabled
    }
} 