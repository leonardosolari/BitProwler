import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchViewContainer()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .accessibilityIdentifier("tab_search")
            
            TorrentsView()
                .tabItem {
                    Label("Torrent", systemImage: "arrow.down.circle")
                }
                .accessibilityIdentifier("tab_torrents")
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .accessibilityIdentifier("tab_settings")
        }
    }
}

#Preview {
    let container = AppContainer()
    return ContentView()
        .environmentObject(container)
        .environmentObject(container.prowlarrManager)
        .environmentObject(container.qbittorrentManager)
        .environmentObject(container.recentPathsManager)
        .environmentObject(container.searchHistoryManager)
        .environmentObject(container.filterViewModel)
}