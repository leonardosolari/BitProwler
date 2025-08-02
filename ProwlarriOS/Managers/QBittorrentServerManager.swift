import Foundation
import SwiftUI

class QBittorrentServerManager: ObservableObject {
    @Published var qbittorrentServers: [QBittorrentServer] {
        didSet {
            saveServers()
        }
    }
    
    @Published var activeQBittorrentServerId: UUID? {
        didSet {
            UserDefaults.standard.set(activeQBittorrentServerId?.uuidString, forKey: "activeQBittorrentServerId")
        }
    }
    
    var activeQBittorrentServer: QBittorrentServer? {
        guard let server = qbittorrentServers.first(where: { $0.id == activeQBittorrentServerId }) else {
            return nil
        }
        if server.password.isEmpty, let password = keychainService.get(key: server.id.uuidString) {
            var mutableServer = server
            mutableServer.password = password
            return mutableServer
        }
        return server
    }
    
    private let keychainService = KeychainService()
    private let serversKey = "qbittorrentServers"
    
    init() {
        self.qbittorrentServers = []
        loadServers()
        
        if let idString = UserDefaults.standard.string(forKey: "activeQBittorrentServerId") {
            self.activeQBittorrentServerId = UUID(uuidString: idString)
        } else {
            self.activeQBittorrentServerId = nil
        }
    }
    
    private func loadServers() {
        guard let data = UserDefaults.standard.data(forKey: serversKey),
              var servers = try? JSONDecoder().decode([QBittorrentServer].self, from: data) else {
            self.qbittorrentServers = []
            return
        }
        
        for i in 0..<servers.count {
            if let password = keychainService.get(key: servers[i].id.uuidString) {
                servers[i].password = password
            }
        }
        self.qbittorrentServers = servers
    }
    
    private func saveServers() {
        if let encoded = try? JSONEncoder().encode(qbittorrentServers) {
            UserDefaults.standard.set(encoded, forKey: serversKey)
        }
    }
    
    func addQBittorrentServer(_ server: QBittorrentServer) {
        do {
            try keychainService.save(key: server.id.uuidString, value: server.password)
            qbittorrentServers.append(server)
            if qbittorrentServers.count == 1 {
                activeQBittorrentServerId = server.id
            }
        } catch {
            print("Errore nel salvataggio della password nel Keychain: \(error)")
        }
    }
    
    func updateQBittorrentServer(_ server: QBittorrentServer) {
        guard let index = qbittorrentServers.firstIndex(where: { $0.id == server.id }) else { return }
        
        do {
            try keychainService.save(key: server.id.uuidString, value: server.password)
            qbittorrentServers[index] = server
        } catch {
            print("Errore nell'aggiornamento della password nel Keychain: \(error)")
        }
    }
    
    func deleteQBittorrentServer(_ server: QBittorrentServer) {
        do {
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