import Testing
import Foundation
@testable import BitProwler

struct TorrentFileNodeTests {
    
    @Test func leafNodeProperties() {
        let file = TorrentFile(index: 0, name: "test.txt", size: 100, progress: 0.5, priority: 1)
        let node = TorrentFileNode(file: file)
        
        #expect(node.totalSize == 100)
        #expect(node.totalProgress == 0.5)
        #expect(node.isSelected == true)
    }
    
    @Test func directoryNodeCalculations() {
        let file1 = TorrentFile(index: 0, name: "A.txt", size: 100, progress: 1.0, priority: 1)
        let file2 = TorrentFile(index: 1, name: "B.txt", size: 300, progress: 0.0, priority: 0)
        
        let node1 = TorrentFileNode(file: file1)
        let node2 = TorrentFileNode(file: file2)
        
        let dirNode = TorrentFileNode(name: "Folder", children: [node1, node2])
        
        #expect(dirNode.totalSize == 400)
        
        let expectedProgress = (1.0 * 100.0 + 0.0 * 300.0) / 400.0
        #expect(dirNode.totalProgress == expectedProgress)
        
        #expect(dirNode.isSelected == true)
    }
    
    @Test func nestedDirectorySelection() {
        let file = TorrentFile(index: 0, name: "A.txt", size: 100, progress: 0, priority: 0)
        let node = TorrentFileNode(file: file)
        let subDir = TorrentFileNode(name: "Sub", children: [node])
        let rootDir = TorrentFileNode(name: "Root", children: [subDir])
        
        #expect(rootDir.isSelected == false)
        
        let selectedFile = TorrentFile(index: 1, name: "B.txt", size: 100, progress: 0, priority: 1)
        let selectedNode = TorrentFileNode(file: selectedFile)
        let subDir2 = TorrentFileNode(name: "Sub2", children: [selectedNode])
        let rootDir2 = TorrentFileNode(name: "Root2", children: [subDir2])
        
        #expect(rootDir2.isSelected == true)
    }
}