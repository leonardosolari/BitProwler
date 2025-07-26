// File: /ProwlarriOS/ViewModels/TorrentActionsViewModel.swift

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
    
    // NUOVA PROPRIETÀ CALCOLATA
    var isForced: Bool {
        TorrentState(from: torrent.state).isForced
    }
    
    init(torrent: QBittorrentTorrent, manager: QBittorrentServerManager, apiService: QBittorrentAPIService = NetworkManager()) {
        self.torrent = torrent
        self.qbittorrentManager = manager
        self.apiService = apiService
    }
    
    // Modifichiamo il metodo per accettare un parametro booleano per forceStart
    func performAction(_ action: TorrentAction, location: String? = nil, deleteFiles: Bool = false, forceStart: Bool? = nil, completion: @escaping () -> Void) async {
        guard let server = qbittorrentManager.activeQBittorrentServer else {
            handleError(AppError.serverNotConfigured)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Passiamo il nuovo parametro al servizio API
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
    
    // NUOVI CASI ENUM
    enum TorrentAction {
        case togglePauseResume
        case delete
        case move
        case forceStart // Un'unica azione per abilitare/disabilitare
        case recheck
    }
}