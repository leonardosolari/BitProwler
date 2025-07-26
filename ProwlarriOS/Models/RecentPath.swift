// File: /ProwlarriOS/Models/RecentPath.swift

import Foundation

struct RecentPath: Codable, Identifiable, Hashable { // Aggiungi Hashable per ForEach
    let id: UUID
    let path: String
    var lastUsed: Date // Rendi 'var' per poterla aggiornare
    
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
    
    private let maxPaths = 15 // Aumentiamo un po' il limite
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "recentPaths"),
           let decoded = try? JSONDecoder().decode([RecentPath].self, from: data) {
            // Ordina i percorsi per data di ultimo utilizzo, dal più recente al più vecchio
            self.paths = decoded.sorted { $0.lastUsed > $1.lastUsed }
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
        // Se il percorso esiste già, aggiorna la sua data e spostalo in cima
        if let index = paths.firstIndex(where: { $0.path == path }) {
            paths[index].lastUsed = Date()
        } else {
            // Altrimenti, aggiungi un nuovo percorso
            let newPath = RecentPath(path: path)
            paths.insert(newPath, at: 0)
        }
        
        // Riordina sempre per data per essere sicuri
        paths.sort { $0.lastUsed > $1.lastUsed }
        
        // Mantieni solo gli ultimi maxPaths percorsi
        if paths.count > maxPaths {
            paths = Array(paths.prefix(maxPaths))
        }
    }
    
    // NUOVO METODO PER ELIMINARE
    func deletePath(at offsets: IndexSet) {
        paths.remove(atOffsets: offsets)
    }
}