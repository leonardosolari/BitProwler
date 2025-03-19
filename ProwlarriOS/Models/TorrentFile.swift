import Foundation

struct TorrentFile: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let progress: Double
    
    init(from dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.size = dictionary["size"] as? Int64 ?? 0
        self.progress = dictionary["progress"] as? Double ?? 0.0
    }
}