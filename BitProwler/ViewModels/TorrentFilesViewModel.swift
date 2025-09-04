import Foundation

@MainActor
class TorrentFilesViewModel: ObservableObject {
    @Published var files: [TorrentFile] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let torrent: QBittorrentTorrent
    private let qbittorrentManager: GenericServerManager<QBittorrentServer>
    private let apiService: QBittorrentAPIService
    
    private var originalFiles: [TorrentFile] = []

    init(
        torrent: QBittorrentTorrent,
        qbittorrentManager: GenericServerManager<QBittorrentServer>,
        apiService: QBittorrentAPIService
    ) {
        self.torrent = torrent
        self.qbittorrentManager = qbittorrentManager
        self.apiService = apiService
    }
    
    func fetchFiles() async {
        guard let server = qbittorrentManager.activeServer else {
            error = AppError.serverNotConfigured.errorDescription
            return
        }
        
        isLoading = true
        
        do {
            let fetchedFiles = try await apiService.getFiles(for: torrent, on: server)
            self.files = fetchedFiles
            self.originalFiles = fetchedFiles
            self.error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleFileSelection(at fileIndex: Int) {
        guard files.indices.contains(fileIndex) else { return }
        
        let currentPriority = files[fileIndex].priority
        files[fileIndex].priority = (currentPriority == 0) ? 1 : 0
    }
    
    func saveChanges() async -> Bool {
        guard let server = qbittorrentManager.activeServer else {
            error = AppError.serverNotConfigured.errorDescription
            return false
        }
        
        let filesToSkip = files.indices.filter {
            files[$0].priority == 0 && originalFiles[$0].priority != 0
        }.map { String(files[$0].index) }

        let filesToDownload = files.indices.filter {
            files[$0].priority != 0 && originalFiles[$0].priority == 0
        }.map { String(files[$0].index) }
        
        guard !filesToSkip.isEmpty || !filesToDownload.isEmpty else {
            return true
        }

        isLoading = true
        
        do {
            if !filesToSkip.isEmpty {
                try await apiService.setFilePriority(for: torrent, on: server, fileIds: filesToSkip, priority: 0)
            }
            if !filesToDownload.isEmpty {
                try await apiService.setFilePriority(for: torrent, on: server, fileIds: filesToDownload, priority: 1)
            }
            isLoading = false
            return true
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            self.files = originalFiles
            isLoading = false
            return false
        }
    }
}