import SwiftUI

struct ContentView: View {
    @StateObject private var prowlarrManager = ProwlarrServerManager()
    @StateObject private var qbittorrentManager = QBittorrentServerManager()
    @StateObject private var recentPathsManager = RecentPathsManager()
    @StateObject private var searchHistoryManager = SearchHistoryManager()
    
    @StateObject private var filterViewModel = FilterViewModel()
    
    var body: some View {
        TabView {
            SearchViewContainer()
                .tabItem {
                    Label("Cerca", systemImage: "magnifyingglass")
                }
            
            TorrentsView()
                .tabItem {
                    Label("Torrent", systemImage: "arrow.down.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gear")
                }
        }
        .environmentObject(prowlarrManager)
        .environmentObject(qbittorrentManager)
        .environmentObject(recentPathsManager)
        .environmentObject(searchHistoryManager)
        .environmentObject(filterViewModel)
    }
}

#Preview {
    ContentView()
}