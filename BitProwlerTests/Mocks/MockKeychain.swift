import Foundation
@testable import BitProwler

final class MockKeychain: KeychainProtocol {
    var storage: [String: String] = [:]
    var shouldThrowError = false
    
    func save(key: String, value: String) throws {
        if shouldThrowError {
            throw AppError.unknownError
        }
        storage[key] = value
    }
    
    func get(key: String) -> String? {
        return storage[key]
    }
    
    func delete(key: String) throws {
        if shouldThrowError {
            throw AppError.unknownError
        }
        storage.removeValue(forKey: key)
    }
    
    func clearAll() throws {
        if shouldThrowError {
            throw AppError.unknownError
        }
        storage.removeAll()
    }
}