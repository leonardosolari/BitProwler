import Foundation

struct QBittorrentTorrent: Identifiable, Codable {
    let name: String
    let size: Int64
    let progress: Double
    let downloadSpeed: Int64
    let uploadSpeed: Int64
    let state: String
    let hash: String
    let numSeeds: Int
    let numLeechs: Int
    let ratio: Double
    
    var id: String { hash }
    
    enum CodingKeys: String, CodingKey {
        case name, size, progress, state, hash, ratio
        case downloadSpeed = "dlspeed"
        case uploadSpeed = "upspeed"
        case numSeeds = "num_seeds"
        case numLeechs = "num_leechs"
    }
}