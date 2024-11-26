import Foundation

class ProwlarrSettings: ObservableObject {
    @Published var serverUrl: String = UserDefaults.standard.string(forKey: "serverUrl") ?? "" {
        didSet {
            UserDefaults.standard.set(serverUrl, forKey: "serverUrl")
        }
    }
    
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "apiKey")
        }
    }
    
    @Published var qbittorrentUrl: String = UserDefaults.standard.string(forKey: "qbittorrentUrl") ?? "" {
        didSet {
            UserDefaults.standard.set(qbittorrentUrl, forKey: "qbittorrentUrl")
        }
    }
    
    @Published var qbittorrentUsername: String = UserDefaults.standard.string(forKey: "qbittorrentUsername") ?? "" {
        didSet {
            UserDefaults.standard.set(qbittorrentUsername, forKey: "qbittorrentUsername")
        }
    }
    
    @Published var qbittorrentPassword: String = UserDefaults.standard.string(forKey: "qbittorrentPassword") ?? "" {
        didSet {
            UserDefaults.standard.set(qbittorrentPassword, forKey: "qbittorrentPassword")
        }
    }
}