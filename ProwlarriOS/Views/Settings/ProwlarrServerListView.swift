import SwiftUI

struct ProwlarrServerListView: View {
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    @State private var showingAddServer = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Aggiungi Server", systemImage: "plus.circle")
                }
            }
            
            if !prowlarrManager.prowlarrServers.isEmpty {
                Section("Server Configurati") {
                    ForEach(prowlarrManager.prowlarrServers) { server in
                        ServerRow(
                            name: server.name,
                            isActive: prowlarrManager.activeProwlarrServerId == server.id,
                            onSelect: { prowlarrManager.activeProwlarrServerId = server.id }
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                prowlarrManager.deleteProwlarrServer(server)
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Server Prowlarr")
        .sheet(isPresented: $showingAddServer) {
            AddProwlarrServerView()
        }
    }
} 