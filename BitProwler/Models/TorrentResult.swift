import Foundation

struct TorrentResult: Identifiable, Codable {
    let id: String
    let title: String
    let size: Int64
    let seeders: Int
    let leechers: Int
    let downloadUrl: String?
    let magnetUrl: String?
    let infoUrl: String?
    let indexer: String
    let publishDate: String
    
    // MARK: - Computed Properties for UI Logic
    
    var isDownloadable: Bool {
        return primaryDownloadLink != nil
    }
    
    var primaryDownloadLink: String? {
        return effectiveMagnetUrl ?? downloadUrl
    }
    
    var releaseUrl: String? {
        if let info = infoUrl, !info.isEmpty {
            return info
        }
        if id.starts(with: "http://") || id.starts(with: "https://") {
            return id
        }
        return nil
    }
    
    var effectiveMagnetUrl: String? {
        if let magnet = magnetUrl, magnet.starts(with: "magnet:") {
            return magnet
        }
        if id.starts(with: "magnet:") {
            return id
        }
        return nil
    }

    init(id: String, title: String, size: Int64, seeders: Int, leechers: Int, downloadUrl: String?, magnetUrl: String?, infoUrl: String?, indexer: String, publishDate: String) {
        self.id = id
        self.title = title
        self.size = size
        self.seeders = seeders
        self.leechers = leechers
        self.downloadUrl = downloadUrl
        self.magnetUrl = magnetUrl
        self.infoUrl = infoUrl
        self.indexer = indexer
        self.publishDate = publishDate
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "guid"
        case title
        case size
        case seeders
        case leechers
        case downloadUrl
        case magnetUrl
        case infoUrl
        case indexer
        case publishDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        if let sizeInt = try? container.decode(Int64.self, forKey: .size) {
            size = sizeInt
        } else if let sizeString = try? container.decode(String.self, forKey: .size),
                  let sizeValue = Int64(sizeString) {
            size = sizeValue
        } else {
            size = 0
        }
        
        if let seedersInt = try? container.decode(Int.self, forKey: .seeders) {
            seeders = seedersInt
        } else if let seedersString = try? container.decode(String.self, forKey: .seeders),
                  let seedersValue = Int(seedersString) {
            seeders = seedersValue
        } else {
            seeders = 0
        }
        
        if let leechersInt = try? container.decode(Int.self, forKey: .leechers) {
            leechers = leechersInt
        } else if let leechersString = try? container.decode(String.self, forKey: .leechers),
                  let leechersValue = Int(leechersString) {
            leechers = leechersValue
        } else {
            leechers = 0
        }
        
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        magnetUrl = try container.decodeIfPresent(String.self, forKey: .magnetUrl)
        infoUrl = try container.decodeIfPresent(String.self, forKey: .infoUrl)
        indexer = try container.decode(String.self, forKey: .indexer)
        publishDate = try container.decode(String.self, forKey: .publishDate)
    }
}