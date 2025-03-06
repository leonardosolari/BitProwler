import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: ProwlarrSettings
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: ProwlarrServerListView()) {
                        HStack {
                            Label("Server Prowlarr", systemImage: "server.rack")
                            Spacer()
                            if let activeServer = settings.activeServer {
                                Text(activeServer.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: QBittorrentServerListView()) {
                        HStack {
                            Label("Server qBittorrent", systemImage: "arrow.down.circle")
                            Spacer()
                            if let activeServer = settings.activeQBittorrentServer {
                                Text(activeServer.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProwlarrSettings())
}