import SwiftUI

struct ProwlarrServerListView: View {
    @EnvironmentObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    @State private var showingAddServer = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Aggiungi Server", systemImage: "plus.circle")
                }
            }
            
            if !prowlarrManager.servers.isEmpty {
                Section("Server Configurati") {
                    ForEach(prowlarrManager.servers) { server in
                        NavigationLink(destination: AddProwlarrServerView(serverToEdit: server)) {
                            ServerRow(
                                name: server.name,
                                isActive: prowlarrManager.activeServerId == server.id,
                                onSelect: { prowlarrManager.activeServerId = server.id }
                            )
                        }
                    }
                    .onDelete(perform: prowlarrManager.deleteServer)
                }
            }
        }
        .navigationTitle("Server Prowlarr")
        .sheet(isPresented: $showingAddServer) {
            AddProwlarrServerView()
        }
    }
}