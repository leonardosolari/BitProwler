import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager 
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: ProwlarrServerListView()) {
                        HStack {
                            Label("Server Prowlarr", systemImage: "server.rack")
                            Spacer()
                            if let activeServer = prowlarrManager.activeServer {
                                Text(activeServer.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: QBittorrentServerListView()) {
                        HStack {
                            Label("Server qBittorrent", systemImage: "arrow.down.circle")
                            Spacer()
                            if let activeServer = qbittorrentManager.activeQBittorrentServer {
                                Text(activeServer.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                } footer: {
                    HStack {
                        Spacer()
                        Text(AppInfo.displayVersion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                .listRowInsets(EdgeInsets()) 
            }
            .navigationTitle("Impostazioni")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProwlarrServerManager())
        .environmentObject(QBittorrentServerManager())
}