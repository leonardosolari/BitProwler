import Foundation
import SwiftUI

class GenericServerManager<T: Server>: ObservableObject {
    @Published var servers: [T] {
        didSet { saveServers() }
    }
    
    @Published var activeServerId: UUID? {
        didSet {
            UserDefaults.standard.set(activeServerId?.uuidString, forKey: activeServerKey)
        }
    }
    
    var activeServer: T? {
        guard let serverId = activeServerId,
              let server = servers.first(where: { $0.id == serverId }) else {
            return servers.first
        }
        
        if server.secret.isEmpty, let secret = keychainService.get(key: server.id.uuidString) {
            var mutableServer = server
            mutableServer.secret = secret
            return mutableServer
        }
        return server
    }
    
    private let keychainService = KeychainService()
    private let activeServerKey: String
    
    init() {
        self.activeServerKey = "active_\(T.serversKey)_id"
        self.servers = []
        loadServers()
        
        if let idString = UserDefaults.standard.string(forKey: activeServerKey),
           let id = UUID(uuidString: idString),
           servers.contains(where: { $0.id == id }) {
            self.activeServerId = id
        } else {
            self.activeServerId = self.servers.first?.id
        }
    }
    
    private func loadServers() {
        guard let data = UserDefaults.standard.data(forKey: T.serversKey),
              var loadedServers = try? JSONDecoder().decode([T].self, from: data) else {
            self.servers = []
            return
        }
        
        for i in 0..<loadedServers.count {
            if let secret = keychainService.get(key: loadedServers[i].id.uuidString) {
                loadedServers[i].secret = secret
            }
        }
        self.servers = loadedServers
    }
    
    private func saveServers() {
        let serversToSave = servers.map { server -> T in
            var serverCopy = server
            serverCopy.secret = ""
            return serverCopy
        }
        
        if let encoded = try? JSONEncoder().encode(serversToSave) {
            UserDefaults.standard.set(encoded, forKey: T.serversKey)
        }
    }
    
    func addServer(_ server: T) {
        do {
            try keychainService.save(key: server.id.uuidString, value: server.secret)
            servers.append(server)
            if servers.count == 1 {
                activeServerId = server.id
            }
        } catch {
            print("Keychain save error for \(T.self): \(error)")
        }
    }
    
    func updateServer(_ server: T) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        
        do {
            try keychainService.save(key: server.id.uuidString, value: server.secret)
            servers[index] = server
        } catch {
            print("Keychain update error for \(T.self): \(error)")
        }
    }
    
    func deleteServer(at offsets: IndexSet) {
        let serversToDelete = offsets.map { servers[$0] }
        servers.remove(atOffsets: offsets)
        
        for server in serversToDelete {
            do {
                try keychainService.delete(key: server.id.uuidString)
                if activeServerId == server.id {
                    activeServerId = servers.first?.id
                }
            } catch {
                print("Keychain delete error for \(T.self): \(error)")
            }
        }
    }
}