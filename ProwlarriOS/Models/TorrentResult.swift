import Foundation

struct TorrentResult: Identifiable, Codable {
    let id: String
    let title: String
    let size: Int64
    let seeders: Int
    let leechers: Int
    let downloadUrl: String?
    let indexer: String
    let publishDate: String
    
    enum CodingKeys: String, CodingKey {
        case id = "guid"
        case title
        case size
        case seeders
        case leechers
        case downloadUrl
        case indexer
        case publishDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        // Gestione flessibile della size che potrebbe arrivare in formati diversi
        if let sizeInt = try? container.decode(Int64.self, forKey: .size) {
            size = sizeInt
        } else if let sizeString = try? container.decode(String.self, forKey: .size),
                  let sizeValue = Int64(sizeString) {
            size = sizeValue
        } else {
            size = 0
        }
        
        // Gestione flessibile di seeders e leechers
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
        
        downloadUrl = try? container.decode(String.self, forKey: .downloadUrl)
        indexer = try container.decode(String.self, forKey: .indexer)
        publishDate = try container.decode(String.self, forKey: .publishDate)
    }
}