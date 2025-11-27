import Testing
import Foundation
@testable import BitProwler

@MainActor
struct PersistenceIntegrationTests {
    
    @Test func keychainServiceRealPersistence() throws {
        let testService = "com.bitprowler.test.integration.keychain"
        let keychain = KeychainService(service: testService)
        
        try keychain.clearAll()
        
        let key = "integration_test_secret"
        let value = "super_secret_value_123"
        
        try keychain.save(key: key, value: value)
        
        let retrievedValue = keychain.get(key: key)
        #expect(retrievedValue == value)
        
        let newKeychainInstance = KeychainService(service: testService)
        let persistedValue = newKeychainInstance.get(key: key)
        #expect(persistedValue == value)
        
        try keychain.delete(key: key)
        #expect(keychain.get(key: key) == nil)
        
        try keychain.clearAll()
    }
    
    @Test func genericServerManagerFullCyclePersistence() throws {
        let testService = "com.bitprowler.test.integration.manager"
        let realKeychain = KeychainService(service: testService)
        try realKeychain.clearAll()
        
        let suiteName = "IntegrationTestDefaults"
        let realDefaults = UserDefaults(suiteName: suiteName)!
        realDefaults.removePersistentDomain(forName: suiteName)
        
        var manager = GenericServerManager<ProwlarrServer>(
            keychainService: realKeychain,
            userDefaults: realDefaults
        )
        
        let newServer = ProwlarrServer(
            name: "Integration Server",
            url: "http://192.168.1.100:9696",
            apiKey: "real_api_key_stored_securely"
        )
        
        manager.addServer(newServer)
        
        #expect(manager.servers.count == 1)
        #expect(manager.activeServer?.apiKey == "real_api_key_stored_securely")
        
        manager = GenericServerManager<ProwlarrServer>(
            keychainService: realKeychain,
            userDefaults: realDefaults
        )
        
        #expect(manager.servers.count == 1)
        #expect(manager.servers.first?.name == "Integration Server")
        #expect(manager.servers.first?.url == "http://192.168.1.100:9696")
        
        #expect(manager.activeServer != nil)
        #expect(manager.activeServer?.apiKey == "real_api_key_stored_securely")
        
        manager.deleteServer(at: IndexSet(integer: 0))
        #expect(manager.servers.isEmpty)
        #expect(realKeychain.get(key: newServer.id.uuidString) == nil)
        
        try realKeychain.clearAll()
        realDefaults.removePersistentDomain(forName: suiteName)
    }
    
    @Test func searchHistoryManagerPersistence() {
        let suiteName = "IntegrationTestHistory"
        let realDefaults = UserDefaults(suiteName: suiteName)!
        realDefaults.removePersistentDomain(forName: suiteName)
        
        var historyManager = SearchHistoryManager(userDefaults: realDefaults)
        
        historyManager.addSearch("Ubuntu ISO")
        historyManager.addSearch("Debian")
        
        #expect(historyManager.searches.count == 2)
        #expect(historyManager.searches.first == "Debian")
        
        historyManager = SearchHistoryManager(userDefaults: realDefaults)
        
        #expect(historyManager.searches.count == 2)
        #expect(historyManager.searches[0] == "Debian")
        #expect(historyManager.searches[1] == "Ubuntu ISO")
        
        realDefaults.removePersistentDomain(forName: suiteName)
    }
}