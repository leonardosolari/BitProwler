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
}