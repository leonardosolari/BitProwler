import SwiftUI

struct QBittorrentServerListView: View {
    @EnvironmentObject var qbittorrentManager: GenericServerManager<QBittorrentServer>
    @State private var showingAddServer = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Add Server", systemImage: "plus.circle")
                }
            }
            
            if !qbittorrentManager.servers.isEmpty {
                Section("Configured Servers") {
                    ForEach(qbittorrentManager.servers) { server in
                        NavigationLink(destination: AddQBittorrentServerView(serverToEdit: server)) {
                            ServerRow(
                                name: server.name,
                                isActive: qbittorrentManager.activeServerId == server.id,
                                onSelect: { qbittorrentManager.activeServerId = server.id }
                            )
                        }
                    }
                    .onDelete(perform: qbittorrentManager.deleteServer)
                }
            }
        }
        .navigationTitle("qBittorrent servers")
        .sheet(isPresented: $showingAddServer) {
            AddQBittorrentServerView()
        }
    }
}
