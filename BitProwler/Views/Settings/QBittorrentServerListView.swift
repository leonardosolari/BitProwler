import SwiftUI

struct QBittorrentServerListView: View {
    @EnvironmentObject var qbittorrentManager: GenericServerManager<QBittorrentServer>
    
    var body: some View {
        ServerListView(
            title: "qBittorrent Servers",
            manager: qbittorrentManager,
            addServerView: { AddQBittorrentServerView() },
            editServerView: { server in AddQBittorrentServerView(serverToEdit: server) }
        )
    }
}