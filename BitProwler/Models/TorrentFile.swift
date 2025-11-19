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
    
    init(index: Int, name: String, size: Int64, progress: Double, priority: Int) {
        self.index = index
        self.name = name
        self.size = size
        self.progress = progress
        self.priority = priority
    }
}