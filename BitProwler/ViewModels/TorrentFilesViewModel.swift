import Foundation

@MainActor
class TorrentFilesViewModel: ObservableObject {
    @Published var fileTree: [TorrentFileNode] = []
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
            self.originalFiles = fetchedFiles
            self.fileTree = buildTree(from: fetchedFiles)
            self.error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleNodeSelection(_ node: TorrentFileNode) {
        var filesToUpdate = [TorrentFile]()
        
        func collectFiles(from node: TorrentFileNode) {
            if let file = node.file {
                filesToUpdate.append(file)
            } else if let children = node.children {
                for child in children {
                    collectFiles(from: child)
                }
            }
        }
        
        collectFiles(from: node)
        
        
        let shouldSelect = !filesToUpdate.contains { $0.priority != 0 }
        let newPriority = shouldSelect ? 1 : 0
        
        for fileToUpdate in filesToUpdate {
            if let index = originalFiles.firstIndex(where: { $0.id == fileToUpdate.id }) {
                originalFiles[index].priority = newPriority
            }
        }
        
        
        self.fileTree = buildTree(from: originalFiles)
    }
    
    func saveChanges() async -> Bool {
        guard let server = qbittorrentManager.activeServer else {
            error = AppError.serverNotConfigured.errorDescription
            return false
        }
        
        
        var changesByPriority: [Int: [String]] = [:]
        
        let initialFiles = try? await apiService.getFiles(for: torrent, on: server)
        
        for i in 0..<originalFiles.count {
            let newPriority = originalFiles[i].priority
            let originalPriority = initialFiles?.first(where: { $0.id == originalFiles[i].id })?.priority
            
            if newPriority != originalPriority {
                let fileId = String(originalFiles[i].index)
                changesByPriority[newPriority, default: []].append(fileId)
            }
        }
        
        guard !changesByPriority.isEmpty else {
            return true
        }

        isLoading = true
        
        do {
            for (priority, fileIds) in changesByPriority {
                try await apiService.setFilePriority(for: torrent, on: server, fileIds: fileIds, priority: priority)
            }
            isLoading = false
            return true
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await fetchFiles()
            isLoading = false
            return false
        }
    }
    
    private func buildTree(from files: [TorrentFile]) -> [TorrentFileNode] {
        let root = TorrentFileNode(name: "root", children: [])

        for file in files {
            var currentNode = root
            let components = (file.name as NSString).pathComponents

            for (index, component) in components.enumerated() {
                if index == components.count - 1 {
                    let fileNode = TorrentFileNode(file: file)
                    currentNode.children?.append(fileNode)
                } else {
                    if let existingChild = currentNode.children?.first(where: { $0.name == component && $0.file == nil }) {
                        currentNode = existingChild
                    } else {
                        let newDirNode = TorrentFileNode(name: component, children: [])
                        currentNode.children?.append(newDirNode)
                        currentNode = newDirNode
                    }
                }
            }
        }

        func sortChildrenRecursively(of node: TorrentFileNode) {
            guard node.children != nil else { return }
            
            node.children?.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
            for child in node.children! {
                sortChildrenRecursively(of: child)
            }
        }

        sortChildrenRecursively(of: root)

        return root.children ?? []
    }
}