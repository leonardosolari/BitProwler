import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    @EnvironmentObject var qbittorrentManager: GenericServerManager<QBittorrentServer>
    
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
                            Label("qBittorrent Servers", systemImage: "arrow.down.circle")
                            Spacer()
                            if let activeServer = qbittorrentManager.activeServer {
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
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(GenericServerManager<ProwlarrServer>())
        .environmentObject(GenericServerManager<QBittorrentServer>())
}
