import SwiftUI

struct QBittorrentServerListView: View {
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @State private var showingAddServer = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Aggiungi Server", systemImage: "plus.circle")
                }
            }
            
            if !qbittorrentManager.qbittorrentServers.isEmpty {
                Section("Server Configurati") {
                    ForEach(qbittorrentManager.qbittorrentServers) { server in
                        ServerRow(
                            name: server.name,
                            isActive: qbittorrentManager.activeQBittorrentServerId == server.id,
                            onSelect: { qbittorrentManager.activeQBittorrentServerId = server.id }
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                qbittorrentManager.deleteQBittorrentServer(server)
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Server qBittorrent")
        .sheet(isPresented: $showingAddServer) {
            AddQBittorrentServerView()
        }
    }
} 