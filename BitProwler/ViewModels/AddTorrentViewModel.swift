import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class AddTorrentViewModel: ObservableObject {
    // MARK: - Published Properties for UI State
    @Published var isMagnetLink = true
    @Published var magnetUrl = ""
    @Published var torrentFile: Data?
    @Published var selectedFileName: String?
    @Published var downloadPath = ""
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    @Published var shouldDismiss = false
    
    // MARK: - Dependencies
    private let qbittorrentManager: GenericServerManager<QBittorrentServer>
    private let recentPathsManager: RecentPathsManager
    private let apiService: QBittorrentAPIService
    
    // MARK: - Computed Properties
    var canAddTorrent: Bool {
        guard qbittorrentManager.activeServer != nil, !downloadPath.isEmpty else { return false }
        
        if isMagnetLink {
            return !magnetUrl.isEmpty
        } else {
            return torrentFile != nil
        }
    }
    
    // MARK: - Initializer
    init(qbittorrentManager: GenericServerManager<QBittorrentServer>, recentPathsManager: RecentPathsManager, apiService: QBittorrentAPIService) {
        self.qbittorrentManager = qbittorrentManager
        self.recentPathsManager = recentPathsManager
        self.apiService = apiService
        self.downloadPath = recentPathsManager.paths.first?.path ?? "/downloads"
    }
    
    // MARK: - Public Methods (Actions)
    
    func addTorrent() async {
        guard let server = qbittorrentManager.activeServer else {
            handleError(AppError.serverNotConfigured)
            return
        }
        
        let source: TorrentSource
        if isMagnetLink {
            source = .url(magnetUrl)
        } else if let fileData = torrentFile, let fileName = selectedFileName {
            source = .file(data: fileData, filename: fileName)
        } else {
            handleError(AppError.unknownError)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiService.addTorrent(from: source, savePath: downloadPath, on: server)
            recentPathsManager.addPath(downloadPath)
            shouldDismiss = true
        } catch {
            handleError(error)
        }
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw AppError.unknownError
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                self.torrentFile = try Data(contentsOf: url)
                self.selectedFileName = url.lastPathComponent
                
            } catch {
                handleError(error)
            }
        case .failure(let error):
            handleError(error)
        }
    }
    
    #if UITESTING
    func mockFileSelection(fileName: String, data: Data) {
        self.torrentFile = data
        self.selectedFileName = fileName
    }
    #endif
    
    // MARK: - Private Helper
    
    private func handleError(_ error: Error) {
        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.showError = true
    }
}

enum TorrentSource {
    case url(String)
    case file(data: Data, filename: String)
}