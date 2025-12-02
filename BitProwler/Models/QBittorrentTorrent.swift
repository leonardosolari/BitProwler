import Foundation

struct QBittorrentTorrent: Identifiable, Codable {
    var name: String
    var size: Int64
    var progress: Double
    var downloadSpeed: Int64
    var uploadSpeed: Int64
    var state: String
    var hash: String
    var numSeeds: Int
    var numLeechs: Int
    var ratio: Double
    var eta: Int
    var savePath: String
    
    var id: String { hash }
    
    enum CodingKeys: String, CodingKey {
        case name, size, progress, state, hash, ratio, eta
        case downloadSpeed = "dlspeed"
        case uploadSpeed = "upspeed"
        case numSeeds = "num_seeds"
        case numLeechs = "num_leechs"
        case savePath = "save_path"
    }
    
    init(name: String, size: Int64, progress: Double, downloadSpeed: Int64, uploadSpeed: Int64, state: String, hash: String, numSeeds: Int, numLeechs: Int, ratio: Double, eta: Int, savePath: String) {
        self.name = name
        self.size = size
        self.progress = progress
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.state = state
        self.hash = hash
        self.numSeeds = numSeeds
        self.numLeechs = numLeechs
        self.ratio = ratio
        self.eta = eta
        self.savePath = savePath
    }
}