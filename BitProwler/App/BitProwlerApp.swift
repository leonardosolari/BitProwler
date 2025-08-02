import SwiftUI

@main
struct BitProwlerApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(container.prowlarrManager)
                .environmentObject(container.qbittorrentManager)
                .environmentObject(container.recentPathsManager)
                .environmentObject(container.searchHistoryManager)
                .environmentObject(container.filterViewModel)
        }
    }
}