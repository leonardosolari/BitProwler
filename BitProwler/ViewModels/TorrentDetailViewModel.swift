import Foundation

@MainActor
class TorrentDetailViewModel: ObservableObject {
    @Published var isDownloading = false
    @Published var error: AppError?
    @Published var showSuccessAlert = false
    
    private let result: TorrentResult
    private let qbittorrentManager: GenericServerManager<QBittorrentServer>
    private let apiService: QBittorrentAPIService

    init(result: TorrentResult, qbittorrentManager: GenericServerManager<QBittorrentServer>, apiService: QBittorrentAPIService) {
        self.result = result
        self.qbittorrentManager = qbittorrentManager
        self.apiService = apiService
    }

    func downloadTorrent() async {
        guard let server = qbittorrentManager.activeServer, let url = result.primaryDownloadLink else {
            self.error = .serverNotConfigured
            return
        }
        
        isDownloading = true
        defer { isDownloading = false }
        
        do {
            try await apiService.addTorrent(url: url, on: server)
            showSuccessAlert = true
        } catch let appError as AppError {
            self.error = appError
        } catch {
            self.error = .unknownError
        }
    }
}