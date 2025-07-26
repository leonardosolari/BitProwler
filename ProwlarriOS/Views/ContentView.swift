// File: /ProwlarriOS/Views/ContentView.swift

import SwiftUI

struct ContentView: View {
    // Manager per lo stato globale dell'app
    @StateObject private var prowlarrManager = ProwlarrServerManager()
    @StateObject private var qbittorrentManager = QBittorrentServerManager()
    @StateObject private var recentPathsManager = RecentPathsManager()
    @StateObject private var searchHistoryManager = SearchHistoryManager()
    
    // <-- MODIFICA QUI: Creiamo un'unica istanza del FilterViewModel
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
        // Inietta tutti i manager e view model nell'ambiente di SwiftUI
        .environmentObject(prowlarrManager)
        .environmentObject(qbittorrentManager)
        .environmentObject(recentPathsManager)
        .environmentObject(searchHistoryManager)
        .environmentObject(filterViewModel) // <-- MODIFICA QUI: Inietta il FilterViewModel
    }
}

#Preview {
    ContentView()
}