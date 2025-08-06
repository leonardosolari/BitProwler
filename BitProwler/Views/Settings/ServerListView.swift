import SwiftUI

struct ServerListView<T: Server, AddView: View, EditView: View>: View {
    let title: LocalizedStringKey
    @ObservedObject var manager: GenericServerManager<T>
    
    @ViewBuilder var addServerView: () -> AddView
    @ViewBuilder var editServerView: (T) -> EditView
    
    @State private var showingAddServer = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showingAddServer = true }) {
                    Label("Add Server", systemImage: "plus.circle")
                }
            }
            
            if !manager.servers.isEmpty {
                Section("Configured Servers") {
                    ForEach(manager.servers) { server in
                        NavigationLink(destination: editServerView(server)) {
                            ServerRow(
                                name: server.name,
                                isActive: manager.activeServerId == server.id,
                                onSelect: { manager.activeServerId = server.id }
                            )
                        }
                    }
                    .onDelete(perform: manager.deleteServer)
                }
            }
        }
        .navigationTitle(title)
        .sheet(isPresented: $showingAddServer) {
            addServerView()
        }
    }
}