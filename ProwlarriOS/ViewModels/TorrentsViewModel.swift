import Foundation
import Combine

class TorrentsViewModel: ObservableObject {
    @Published var torrents: [QBittorrentTorrent] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 2.0 // Aggiornamento ogni 2 secondi
    private var qbittorrentManager: QBittorrentServerManager?
    
    init() {
        // L'inizializzazione del timer avverrà quando verranno fornite le impostazioni
    }
    
    deinit {
        stopTimer()
    }
    
    func setupTimer(with manager: QBittorrentServerManager) {
        self.qbittorrentManager = manager
        stopTimer() // Ferma il timer esistente se presente
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self, let manager = self.qbittorrentManager else { return }
            Task {
                await self.fetchTorrents(silent: true)
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchTorrents(silent: Bool = false) async {
        guard let qbittorrentManager = self.qbittorrentManager,
          let qbittorrentServer = qbittorrentManager.activeQBittorrentServer else {
            await MainActor.run {
                self.error = "Server qBittorrent non configurato"
                self.isLoading = false
            }
            return
        }
        
        guard let url = URL(string: "\(qbittorrentServer.url)api/v2/torrents/info") else {
            await MainActor.run {
                self.error = "URL non valido"
                self.isLoading = false
            }
            return
        }
        
        if !silent {
            await MainActor.run {
                self.isLoading = true
            }
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Prima effettua il login
            if let success = await login(to: qbittorrentServer) {
                if !success {
                    throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Login fallito"])
                }
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let torrents = jsonArray.map { QBittorrentTorrent(from: $0) }
                await MainActor.run {
                    self.torrents = torrents
                    self.isLoading = false
                    self.error = nil
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func login(to server: QBittorrentServer) async -> Bool? {
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(server.username)&password=\(server.password)"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
} 