import Foundation

struct RecentPath: Codable, Identifiable {
    let id: UUID
    let path: String
    let lastUsed: Date
    
    init(path: String) {
        self.id = UUID()
        self.path = path
        self.lastUsed = Date()
    }
}

class RecentPathsManager: ObservableObject {
    @Published var paths: [RecentPath] {
        didSet {
            savePaths()
        }
    }
    
    private let maxPaths = 10
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "recentPaths"),
           let decoded = try? JSONDecoder().decode([RecentPath].self, from: data) {
            self.paths = decoded
        } else {
            self.paths = []
        }
    }
    
    private func savePaths() {
        if let encoded = try? JSONEncoder().encode(paths) {
            UserDefaults.standard.set(encoded, forKey: "recentPaths")
        }
    }
    
    func addPath(_ path: String) {
        // Rimuovi il percorso esistente se presente
        paths.removeAll { $0.path == path }
        
        // Aggiungi il nuovo percorso all'inizio
        paths.insert(RecentPath(path: path), at: 0)
        
        // Mantieni solo gli ultimi maxPaths percorsi
        if paths.count > maxPaths {
            paths = Array(paths.prefix(maxPaths))
        }
    }
}