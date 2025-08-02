import Foundation
import KeychainAccess

class KeychainService {
    private let keychain: Keychain
    
    init() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.leosolari.utm.ProwlarriOS"
        self.keychain = Keychain(service: bundleIdentifier)
    }
    
    func save(key: String, value: String) throws {
        try keychain.set(value, key: key)
    }
    
    func get(key: String) -> String? {
        return try? keychain.get(key)
    }
    
    func delete(key: String) throws {
        try keychain.remove(key)
    }
}