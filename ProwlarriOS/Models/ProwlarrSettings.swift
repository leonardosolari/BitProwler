import Foundation
import KeychainAccess

class ProwlarrSettings: ObservableObject {
    private let keychainService = KeychainService()
    
    @Published var prowlarrServers: [ProwlarrServer] {
        didSet {
            if let encoded = try? JSONEncoder().encode(prowlarrServers) {
                UserDefaults.standard.set(encoded, forKey: "prowlarrServers")
            }
        }
    }
    
    @Published var qbittorrentServers: [QBittorrentServer] {
        didSet {
            if let encoded = try? JSONEncoder().encode(qbittorrentServers) {
                UserDefaults.standard.set(encoded, forKey: "qbittorrentServers")
            }
        }
    }
    
    @Published var activeProwlarrServerId: UUID? {
        didSet {
            UserDefaults.standard.set(activeProwlarrServerId?.uuidString, forKey: "activeProwlarrServerId")
        }
    }
    
    @Published var activeQBittorrentServerId: UUID? {
        didSet {
            UserDefaults.standard.set(activeQBittorrentServerId?.uuidString, forKey: "activeQBittorrentServerId")
        }
    }
    
    @Published var recentPaths: RecentPathsManager
    
    var activeServer: ProwlarrServer? {
        prowlarrServers.first { $0.id == activeProwlarrServerId }
    }
    
    var activeQBittorrentServer: QBittorrentServer? {
        qbittorrentServers.first { $0.id == activeQBittorrentServerId }
    }
    
    init() {
        // Carica i server Prowlarr da UserDefaults
        if let data = UserDefaults.standard.data(forKey: "prowlarrServers"),
        var servers = try? JSONDecoder().decode([ProwlarrServer].self, from: data) {
            // Ora, per ogni server, carica la sua API key dal Keychain
            for i in 0..<servers.count {
                if let apiKey = keychainService.get(key: servers[i].id.uuidString) {
                    servers[i].apiKey = apiKey
                }
            }
            self.prowlarrServers = servers
        } else {
            self.prowlarrServers = []
        }
        
        // Carica i server qBittorrent da UserDefaults
        if let data = UserDefaults.standard.data(forKey: "qbittorrentServers"),
        var servers = try? JSONDecoder().decode([QBittorrentServer].self, from: data) {
            // Ora, per ogni server, carica la sua password dal Keychain
            for i in 0..<servers.count {
                if let password = keychainService.get(key: servers[i].id.uuidString) {
                    servers[i].password = password
                }
            }
            self.qbittorrentServers = servers
        } else {
            self.qbittorrentServers = []
        }
        
        // Il resto rimane invariato
        if let idString = UserDefaults.standard.string(forKey: "activeProwlarrServerId") {
            self.activeProwlarrServerId = UUID(uuidString: idString)
        } else {
            self.activeProwlarrServerId = nil
        }
        
        if let idString = UserDefaults.standard.string(forKey: "activeQBittorrentServerId") {
            self.activeQBittorrentServerId = UUID(uuidString: idString)
        } else {
            self.activeQBittorrentServerId = nil
        }
        
        self.recentPaths = RecentPathsManager()
    }
    
    // Metodi di utilità per la gestione dei server
    func addProwlarrServer(_ server: ProwlarrServer) {
        do {
            // Salva l'API key nel Keychain prima di aggiungere il server all'array
            try keychainService.save(key: server.id.uuidString, value: server.apiKey)
            prowlarrServers.append(server)
            if prowlarrServers.count == 1 {
                activeProwlarrServerId = server.id
            }
        } catch {
            print("Errore nel salvataggio della API key nel Keychain: \(error)")
            // Qui potresti voler gestire l'errore, magari mostrando un alert all'utente
        }
    }
    
    func addQBittorrentServer(_ server: QBittorrentServer) {
        do {
            // Salva la password nel Keychain prima di aggiungere il server all'array
            try keychainService.save(key: server.id.uuidString, value: server.password)
            qbittorrentServers.append(server)
            if qbittorrentServers.count == 1 {
                activeQBittorrentServerId = server.id
            }
        } catch {
            print("Errore nel salvataggio della password nel Keychain: \(error)")
        }
    }
    
    func deleteProwlarrServer(_ server: ProwlarrServer) {
        do {
            // Elimina l'API key dal Keychain prima di rimuovere il server
            try keychainService.delete(key: server.id.uuidString)
            prowlarrServers.removeAll { $0.id == server.id }
            if activeProwlarrServerId == server.id {
                activeProwlarrServerId = prowlarrServers.first?.id
            }
        } catch {
            print("Errore nell'eliminazione della API key dal Keychain: \(error)")
        }
    }
    
    func deleteQBittorrentServer(_ server: QBittorrentServer) {
        do {
            // Elimina la password dal Keychain prima di rimuovere il server
            try keychainService.delete(key: server.id.uuidString)
            qbittorrentServers.removeAll { $0.id == server.id }
            if activeQBittorrentServerId == server.id {
                activeQBittorrentServerId = qbittorrentServers.first?.id
            }
        } catch {
            print("Errore nell'eliminazione della password dal Keychain: \(error)")
        }
    }
}
