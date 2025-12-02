import SwiftUI

struct ServerListView<T: Server, AddView: View, EditView: View>: View {
    let title: LocalizedStringKey
    @ObservedObject var manager: GenericServerManager<T>
    
    @ViewBuilder var addServerView: () -> AddView
    @ViewBuilder var editServerView: (T) -> EditView
    
    @State private var showingAddServer = false
    @State private var serverToEdit: T?

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
                        ServerRow(
                            name: server.name,
                            isActive: manager.activeServerId == server.id
                        )
                        .onTapGesture {
                            manager.activeServerId = server.id
                            serverToEdit = server
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
        .navigationDestination(item: $serverToEdit) { server in
            editServerView(server)
        }
    }
}