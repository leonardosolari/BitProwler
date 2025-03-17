import Foundation

class ProwlarrSettings: ObservableObject {
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
        // Carica i server Prowlarr
        if let data = UserDefaults.standard.data(forKey: "prowlarrServers"),
           let servers = try? JSONDecoder().decode([ProwlarrServer].self, from: data) {
            self.prowlarrServers = servers
        } else {
            self.prowlarrServers = []
        }
        
        // Carica i server qBittorrent
        if let data = UserDefaults.standard.data(forKey: "qbittorrentServers"),
           let servers = try? JSONDecoder().decode([QBittorrentServer].self, from: data) {
            self.qbittorrentServers = servers
        } else {
            self.qbittorrentServers = []
        }
        
        // Carica gli ID dei server attivi
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
        prowlarrServers.append(server)
        if prowlarrServers.count == 1 {
            activeProwlarrServerId = server.id
        }
    }
    
    func addQBittorrentServer(_ server: QBittorrentServer) {
        qbittorrentServers.append(server)
        if qbittorrentServers.count == 1 {
            activeQBittorrentServerId = server.id
        }
    }
    
    func deleteProwlarrServer(_ server: ProwlarrServer) {
        prowlarrServers.removeAll { $0.id == server.id }
        if activeProwlarrServerId == server.id {
            activeProwlarrServerId = prowlarrServers.first?.id
        }
    }
    
    func deleteQBittorrentServer(_ server: QBittorrentServer) {
        qbittorrentServers.removeAll { $0.id == server.id }
        if activeQBittorrentServerId == server.id {
            activeQBittorrentServerId = qbittorrentServers.first?.id
        }
    }
}