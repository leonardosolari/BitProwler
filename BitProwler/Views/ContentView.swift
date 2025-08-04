import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchViewContainer()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            TorrentsView()
                .tabItem {
                    Label("Torrent", systemImage: "arrow.down.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
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
