import SwiftUI

struct ProwlarrServerListView: View {
    @EnvironmentObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    
    var body: some View {
        ServerListView(
            title: "Prowlarr Servers",
            manager: prowlarrManager,
            addServerView: { AddProwlarrServerView() },
            editServerView: { server in AddProwlarrServerView(serverToEdit: server) }
        )
    }
}