import Foundation

struct AppInfo {
    /// La versione di marketing dell'app (es. "1.0.0").
    static var version: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
    
    /// Il numero di build dell'app (es. "1").
    static var build: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
    }
    
    /// Una stringa combinata, formattata come "Versione 1.0.0 (1)".
    static var displayVersion: String {
        return "Versione \(version) (\(build))"
    }
}