import Foundation
import KeychainAccess

protocol KeychainProtocol {
    func save(key: String, value: String) throws
    func get(key: String) -> String?
    func delete(key: String) throws
    func clearAll() throws
}

final class KeychainService: KeychainProtocol {
    private let keychain: Keychain
    
    init(service: String? = nil) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.leosolari.utm.BitProwler"
        let serviceName = service ?? bundleIdentifier
        self.keychain = Keychain(service: serviceName)
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
    
    func clearAll() throws {
        try keychain.removeAll()
    }
}