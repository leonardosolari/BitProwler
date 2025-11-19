import Foundation

struct RecentPath: Codable, Identifiable, Hashable { 
    let id: UUID
    let path: String
    var lastUsed: Date
    
    init(path: String) {
        self.id = UUID()
        self.path = path
        self.lastUsed = Date()
    }
}

final class RecentPathsManager: ObservableObject {
    @Published var paths: [RecentPath] {
        didSet {
            savePaths()
        }
    }
    
    private let maxPaths = 15
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: "recentPaths"),
           let decoded = try? JSONDecoder().decode([RecentPath].self, from: data) {
            self.paths = decoded.sorted { $0.lastUsed > $1.lastUsed }
        } else {
            self.paths = []
        }
    }
    
    private func savePaths() {
        if let encoded = try? JSONEncoder().encode(paths) {
            userDefaults.set(encoded, forKey: "recentPaths")
        }
    }
    
    func addPath(_ path: String) {
        if let index = paths.firstIndex(where: { $0.path == path }) {
            paths[index].lastUsed = Date()
        } else {
            let newPath = RecentPath(path: path)
            paths.insert(newPath, at: 0)
        }
        
        paths.sort { $0.lastUsed > $1.lastUsed }
        
        if paths.count > maxPaths {
            paths = Array(paths.prefix(maxPaths))
        }
    }
    
    func deletePath(at offsets: IndexSet) {
        paths.remove(atOffsets: offsets)
    }
}