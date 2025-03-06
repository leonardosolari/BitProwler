import SwiftUI

struct QBittorrentServerListView: View {
    @EnvironmentObject var settings: ProwlarrSettings
    @State private var showingAddServer = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Aggiungi Server", systemImage: "plus.circle")
                }
            }
            
            if !settings.qbittorrentServers.isEmpty {
                Section("Server Configurati") {
                    ForEach(settings.qbittorrentServers) { server in
                        ServerRow(
                            name: server.name,
                            isActive: settings.activeQBittorrentServerId == server.id,
                            onSelect: { settings.activeQBittorrentServerId = server.id }
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                settings.deleteQBittorrentServer(server)
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