import Testing
import Foundation
@testable import BitProwler

@MainActor
struct GenericServerManagerTest {
    
    var mockKeychain: MockKeychain
    var testDefaults: UserDefaults
    var manager: GenericServerManager<ProwlarrServer>
    
    init() {
        mockKeychain = MockKeychain()
        testDefaults = UserDefaults(suiteName: "GenericServerManagerTests")!
        testDefaults.removePersistentDomain(forName: "GenericServerManagerTests")
        
        manager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
    }
    
    @Test func addServer() {
        let server = ProwlarrServer(
            name: "Test Server",
            url: "http://localhost:9696",
            apiKey: "secret123"
        )
        
        manager.addServer(server)
        
        #expect(manager.servers.count == 1)
        #expect(manager.activeServerId == server.id)
        #expect(mockKeychain.storage[server.id.uuidString] == "secret123")
        
        let savedServer = manager.servers.first!
        #expect(savedServer.secret == "secret123")
    }
    
    @Test func deleteServer() {
        let server = ProwlarrServer(
            name: "To Delete",
            url: "http://delete.me",
            apiKey: "key"
        )
        manager.addServer(server)
        #expect(mockKeychain.storage[server.id.uuidString] != nil)
        
        manager.deleteServer(at: IndexSet(integer: 0))
        
        #expect(manager.servers.isEmpty)
        #expect(mockKeychain.storage[server.id.uuidString] == nil)
    }
    
    @Test func updateServer() {
        let originalServer = ProwlarrServer(
            name: "Original Server",
            url: "http://localhost:9696",
            apiKey: "original_secret"
        )
        manager.addServer(originalServer)
        
        var updatedServer = originalServer
        updatedServer.name = "Updated Server Name"
        updatedServer.apiKey = "updated_secret_key"
        
        manager.updateServer(updatedServer)
        
        #expect(manager.servers.count == 1)
        let serverInManager = manager.servers.first!
        #expect(serverInManager.name == "Updated Server Name")
        #expect(mockKeychain.storage[originalServer.id.uuidString] == "updated_secret_key")
        
        let activeServer = manager.activeServer
        #expect(activeServer?.name == "Updated Server Name")
        #expect(activeServer?.secret == "updated_secret_key")
    }
    
    @Test func changeActiveServer() {
        let serverA = ProwlarrServer(
            name: "Server A",
            url: "http://server-a.local",
            apiKey: "secret_A"
        )
        let serverB = ProwlarrServer(
            name: "Server B",
            url: "http://server-b.local",
            apiKey: "secret_B"
        )
        
        manager.addServer(serverA)
        manager.addServer(serverB)
        
        #expect(manager.servers.count == 2)
        #expect(manager.activeServerId == serverA.id, "Il primo server aggiunto dovrebbe essere attivo di default")
        #expect(manager.activeServer?.secret == "secret_A")
        
        manager.activeServerId = serverB.id
        
        #expect(manager.activeServerId == serverB.id)
        let newActiveServer = manager.activeServer
        #expect(newActiveServer?.id == serverB.id)
        #expect(newActiveServer?.name == "Server B")
        #expect(newActiveServer?.secret == "secret_B", "Il secret del nuovo server attivo deve essere caricato dal keychain")
    }
}