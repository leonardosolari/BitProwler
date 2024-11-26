//
//  ContentView.swift
//  ProwlarriOS
//
//  Created by Leonardo Solari on 26/11/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = ProwlarrSettings()
    
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Cerca", systemImage: "magnifyingglass")
                }
                .environmentObject(settings)
            
            TorrentsView()
                .tabItem {
                    Label("Torrent", systemImage: "arrow.down.circle")
                }
                .environmentObject(settings)
            
            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gear")
                }
                .environmentObject(settings)
        }
    }
}

#Preview {
    ContentView()
}
