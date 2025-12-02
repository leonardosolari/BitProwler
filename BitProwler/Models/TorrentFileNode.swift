import Foundation

final class TorrentFileNode: Identifiable, Hashable {
    let id: UUID
    let name: String
    var children: [TorrentFileNode]?
    let file: TorrentFile?

    var totalSize: Int64 {
        if let file = file {
            return file.size
        } else if let children = children {
            return children.reduce(0) { $0 + $1.totalSize }
        }
        return 0
    }
    
    var totalProgress: Double {
        if let file = file {
            return file.progress
        } else if let children = children, totalSize > 0 {
            let weightedProgressSum = children.reduce(0.0) { $0 + ($1.totalProgress * Double($1.totalSize)) }
            return weightedProgressSum / Double(totalSize)
        }
        return 0
    }
    
    var isSelected: Bool {
        if let file = file {
            return file.priority != 0
        } else if let children = children {
            return children.contains { $0.isSelected }
        }
        return false
    }

    init(name: String, children: [TorrentFileNode]) {
        self.id = UUID()
        self.name = name
        self.children = children
        self.file = nil
    }

    init(file: TorrentFile) {
        self.id = UUID()
        self.name = (file.name as NSString).lastPathComponent
        self.children = nil
        self.file = file
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TorrentFileNode, rhs: TorrentFileNode) -> Bool {
        lhs.id == rhs.id
    }
}