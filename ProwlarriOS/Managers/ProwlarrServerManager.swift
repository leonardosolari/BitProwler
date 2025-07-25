import Foundation
import SwiftUI

class ProwlarrServerManager: ObservableObject {
    @Published var prowlarrServers: [ProwlarrServer] {
        didSet {
            saveServers()
        }
    }
    
    @Published var activeProwlarrServerId: UUID? {
        didSet {
            UserDefaults.standard.set(activeProwlarrServerId?.uuidString, forKey: "activeProwlarrServerId")
        }
    }
    
    var activeServer: ProwlarrServer? {
        // Prima di restituire il server, assicuriamoci che abbia l'API key caricata.
        guard let server = prowlarrServers.first(where: { $0.id == activeProwlarrServerId }) else {
            return nil
        }
        // Se l'apiKey è vuota, potrebbe essere un server appena caricato da UserDefaults.
        // Proviamo a ricaricarla dal Keychain.
        if server.apiKey.isEmpty, let apiKey = keychainService.get(key: server.id.uuidString) {
            var mutableServer = server
            mutableServer.apiKey = apiKey
            return mutableServer
        }
        return server
    }
    
    private let keychainService = KeychainService()
    private let serversKey = "prowlarrServers"
    
    init() {
        self.prowlarrServers = [] // Inizializza vuoto, poi carica
        loadServers()
        
        if let idString = UserDefaults.standard.string(forKey: "activeProwlarrServerId") {
            self.activeProwlarrServerId = UUID(uuidString: idString)
        } else {
            self.activeProwlarrServerId = nil
        }
    }
    
    private func loadServers() {
        guard let data = UserDefaults.standard.data(forKey: serversKey),
              var servers = try? JSONDecoder().decode([ProwlarrServer].self, from: data) else {
            self.prowlarrServers = []
            return
        }
        
        // Per ogni server, carica la sua API key dal Keychain
        for i in 0..<servers.count {
            if let apiKey = keychainService.get(key: servers[i].id.uuidString) {
                servers[i].apiKey = apiKey
            }
        }
        self.prowlarrServers = servers
    }
    
    private func saveServers() {
        if let encoded = try? JSONEncoder().encode(prowlarrServers) {
            UserDefaults.standard.set(encoded, forKey: serversKey)
        }
    }
    
    func addProwlarrServer(_ server: ProwlarrServer) {
        do {
            try keychainService.save(key: server.id.uuidString, value: server.apiKey)
            prowlarrServers.append(server)
            if prowlarrServers.count == 1 {
                activeProwlarrServerId = server.id
            }
        } catch {
            print("Errore nel salvataggio della API key nel Keychain: \(error)")
        }
    }
    
    func deleteProwlarrServer(_ server: ProwlarrServer) {
        do {
            try keychainService.delete(key: server.id.uuidString)
            prowlarrServers.removeAll { $0.id == server.id }
            if activeProwlarrServerId == server.id {
                activeProwlarrServerId = prowlarrServers.first?.id
            }
        } catch {
            print("Errore nell'eliminazione della API key dal Keychain: \(error)")
        }
    }
}