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
        var rootNodes: [String: TorrentFileNode] = [:]
        var directoryCache: [String: [String: TorrentFileNode]] = ["": rootNodes]

        for file in files {
            let pathComponents = (file.name as NSString).pathComponents
            var currentPath = ""

            for i in 0..<(pathComponents.count - 1) {
                let component = pathComponents[i]
                let parentPath = currentPath
                currentPath = (currentPath as NSString).appendingPathComponent(component)

                if directoryCache[currentPath] == nil {
                    let dirNode = TorrentFileNode(name: component, children: [])
                    directoryCache[currentPath] = [:]
                    
                    if parentPath.isEmpty {
                        rootNodes[component] = dirNode
                    } else {
                        var parentChildren = directoryCache[parentPath] ?? [:]
                        parentChildren[component] = dirNode
                        directoryCache[parentPath] = parentChildren
                    }
                }
            }
            
            let fileName = pathComponents.last!
            let fileNode = TorrentFileNode(file: file)
            
            if pathComponents.count == 1 {
                rootNodes[fileName] = fileNode
            } else {
                let parentPath = (file.name as NSString).deletingLastPathComponent
                var parentChildren = directoryCache[parentPath] ?? [:]
                parentChildren[fileName] = fileNode
                directoryCache[parentPath] = parentChildren
            }
        }

        func generateFinalTree(from dict: [String: TorrentFileNode]) -> [TorrentFileNode] {
            return dict.values.map { node in
                if node.children != nil {
                    let fullPath = findPath(for: node, in: rootNodes) ?? ""
                    let childrenDict = directoryCache[fullPath] ?? [:]
                    let sortedChildren = generateFinalTree(from: childrenDict)
                    return TorrentFileNode(name: node.name, children: sortedChildren)
                }
                return node
            }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        
        func findPath(for targetNode: TorrentFileNode, in nodes: [String: TorrentFileNode], currentPath: String = "") -> String? {
            for (name, node) in nodes {
                let newPath = currentPath.isEmpty ? name : (currentPath as NSString).appendingPathComponent(name)
                if node.id == targetNode.id {
                    return newPath
                }
                if node.children != nil {
                    let fullPath = findPath(for: node, in: rootNodes) ?? ""
                    if let foundPath = findPath(for: targetNode, in: directoryCache[fullPath] ?? [:], currentPath: newPath) {
                        return foundPath
                    }
                }
            }
            return nil
        }

        return generateFinalTree(from: rootNodes)
    }
}