import SwiftUI

struct ProwlarrServerListView: View {
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
            
            if !settings.prowlarrServers.isEmpty {
                Section("Server Configurati") {
                    ForEach(settings.prowlarrServers) { server in
                        ServerRow(
                            name: server.name,
                            isActive: settings.activeProwlarrServerId == server.id,
                            onSelect: { settings.activeProwlarrServerId = server.id }
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                settings.deleteProwlarrServer(server)
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