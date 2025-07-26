// File: /ProwlarriOS/Views/Settings/QBittorrentServerListView.swift

import SwiftUI

struct QBittorrentServerListView: View {
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @State private var showingAddServer = false
    
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
                        // Usa NavigationLink per la modifica
                        NavigationLink(destination: AddQBittorrentServerView(serverToEdit: server)) {
                            ServerRow(
                                name: server.name,
                                isActive: qbittorrentManager.activeQBittorrentServerId == server.id,
                                onSelect: { qbittorrentManager.activeQBittorrentServerId = server.id }
                            )
                        }
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
            // La sheet apre la vista in modalità "Aggiungi" (serverToEdit è nil)
            AddQBittorrentServerView()
        }
    }
}