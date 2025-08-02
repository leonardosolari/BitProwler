import Foundation

struct QBittorrentTorrent: Identifiable {
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
    
    init(from dict: [String: Any]) {
        self.name = dict["name"] as? String ?? "Unknown"
        self.size = dict["size"] as? Int64 ?? 0
        self.progress = dict["progress"] as? Double ?? 0
        self.downloadSpeed = dict["dlspeed"] as? Int64 ?? 0
        self.uploadSpeed = dict["upspeed"] as? Int64 ?? 0
        self.state = dict["state"] as? String ?? "unknown"
        self.hash = dict["hash"] as? String ?? ""
        self.numSeeds = dict["num_seeds"] as? Int ?? 0
        self.numLeechs = dict["num_leechs"] as? Int ?? 0
        self.ratio = dict["ratio"] as? Double ?? 0
    }
} 