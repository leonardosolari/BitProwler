import Foundation

struct AppInfo {
    static var version: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
    
    static var build: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
    }
    
    static var displayVersion: String {
        return "Versione \(version) (\(build))"
    }
}