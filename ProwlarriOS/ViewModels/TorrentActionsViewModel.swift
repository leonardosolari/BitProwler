import Foundation
import SwiftUI

@MainActor
class TorrentActionsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let torrent: QBittorrentTorrent
    private let qbittorrentManager: QBittorrentServerManager
    
    var isPaused: Bool {
        let state = torrent.state.lowercased()
        return state.contains("paused") || state.contains("stopped") || state.contains("stalled")
    }
    
    init(torrent: QBittorrentTorrent, manager: QBittorrentServerManager) {
        self.torrent = torrent
        self.qbittorrentManager = manager
    }
    
    func performAction(_ action: TorrentAction, location: String? = nil, deleteFiles: Bool = false, completion: @escaping () -> Void) async {
        guard let server = qbittorrentManager.activeQBittorrentServer else {
            handleError("Nessun server qBittorrent configurato")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let loginSuccess = await login(to: server)
        if !loginSuccess {
            handleError("Login fallito")
            return
        }
        
        var endpoint: String
        var bodyParams: [String: String] = ["hashes": torrent.hash]
        
        switch action {
        case .togglePauseResume:
            endpoint = isPaused ? "resume" : "pause" // Corretto da start/stop a pause/resume
        case .delete:
            endpoint = "delete"
            bodyParams["deleteFiles"] = String(deleteFiles)
        case .move:
            guard let location = location else {
                handleError("Nessuna nuova posizione specificata")
                return
            }
            endpoint = "setLocation"
            bodyParams["location"] = location
        }
        
        guard let url = URL(string: "\(server.url)api/v2/torrents/\(endpoint)") else {
            handleError("URL non valido per l'azione: \(endpoint)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = bodyParams.map { key, value in
            "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // L'azione ha avuto successo, esegui la completion (es. chiudere la vista)
                completion()
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Errore del server (Status: \(statusCode))"])
            }
        } catch {
            handleError(error.localizedDescription)
        }
    }
    
    private func login(to server: QBittorrentServer) async -> Bool {
        // (Questa logica di login potrebbe essere centralizzata in un NetworkManager in futuro)
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else { return false }
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
    
    private func handleError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }
    
    enum TorrentAction {
        case togglePauseResume
        case delete
        case move
    }
}