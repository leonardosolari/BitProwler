import SwiftUI

struct ProwlarrServerListView: View {
    @EnvironmentObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    @State private var showingAddServer = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Add Server", systemImage: "plus.circle")
                }
            }
            
            if !prowlarrManager.servers.isEmpty {
                Section("Configured Servers") {
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
        .navigationTitle("Prowlarr Servers")
        .sheet(isPresented: $showingAddServer) {
            AddProwlarrServerView()
        }
    }
}
