import Foundation
import SwiftUI

@MainActor
class TorrentActionsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let torrent: QBittorrentTorrent
    private let qbittorrentManager: QBittorrentServerManager
    private let apiService: QBittorrentAPIService
    
    var isPaused: Bool {
        TorrentState(from: torrent.state).isPaused
    }
    
    var isForced: Bool {
        TorrentState(from: torrent.state).isForced
    }
    
    init(torrent: QBittorrentTorrent, manager: QBittorrentServerManager, apiService: QBittorrentAPIService) {
        self.torrent = torrent
        self.qbittorrentManager = manager
        self.apiService = apiService
    }
    
    func performAction(_ action: TorrentAction, location: String? = nil, deleteFiles: Bool = false, forceStart: Bool? = nil, completion: @escaping () -> Void) async {
        guard let server = qbittorrentManager.activeQBittorrentServer else {
            handleError(AppError.serverNotConfigured)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiService.performAction(action, for: torrent, on: server, location: location, deleteFiles: deleteFiles, forceStart: forceStart)
            completion()
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.showError = true
    }
    
    enum TorrentAction {
        case togglePauseResume
        case delete
        case move
        case forceStart
        case recheck
    }
}