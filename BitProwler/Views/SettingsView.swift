import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    @EnvironmentObject var qbittorrentManager: GenericServerManager<QBittorrentServer>
    
    var body: some View {
        NavigationStack {
            List {
                Section("Server") {
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
                    .accessibilityIdentifier("link_prowlarr_servers")
                    
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
                    .accessibilityIdentifier("link_qbittorrent_servers")
                }
                
                Section("Management") {
                    NavigationLink(destination: FilterManagementView()) {
                        Label("Manage Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    NavigationLink(destination: PathManagementView()) {
                        Label("Manage Paths", systemImage: "folder")
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
            .accessibilityIdentifier("settings_list")
        }
    }
}