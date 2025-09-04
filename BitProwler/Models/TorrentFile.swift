import Foundation

struct TorrentFile: Identifiable, Codable, Equatable {
    let index: Int
    let name: String
    let size: Int64
    let progress: Double
    var priority: Int
    
    var id: Int { index }
    
    enum CodingKeys: String, CodingKey {
        case index, name, size, progress, priority
    }
}