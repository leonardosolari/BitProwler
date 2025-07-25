import SwiftUI

struct ContentView: View {
    // Inizializziamo i nostri nuovi manager qui.
    // Saranno la "source of truth" per l'intera app.
    @StateObject private var prowlarrManager = ProwlarrServerManager()
    @StateObject private var qbittorrentManager = QBittorrentServerManager()
    @StateObject private var recentPathsManager = RecentPathsManager()
    
    var body: some View {
        TabView {
            SearchView()
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
        // Inseriamo tutti i manager necessari nell'ambiente di SwiftUI.
        .environmentObject(prowlarrManager)
        .environmentObject(qbittorrentManager)
        .environmentObject(recentPathsManager)
    }
}

#Preview {
    ContentView()
}
