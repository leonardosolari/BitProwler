import Foundation
import KeychainAccess

protocol KeychainProtocol {
    func save(key: String, value: String) throws
    func get(key: String) -> String?
    func delete(key: String) throws
}

final class KeychainService: KeychainProtocol {
    private let keychain: Keychain
    
    init() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.leosolari.utm.BitProwler"
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