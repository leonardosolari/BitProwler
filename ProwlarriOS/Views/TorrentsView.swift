import SwiftUI

struct TorrentsView: View {
    @StateObject private var viewModel = TorrentsViewModel()
    @EnvironmentObject var settings: ProwlarrSettings
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Caricamento...")
                } else if let error = viewModel.error {
                    ContentUnavailableView(
                        "Errore",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.torrents.isEmpty {
                    ContentUnavailableView(
                        "Nessun Torrent",
                        systemImage: "arrow.down.circle",
                        description: Text("Non ci sono torrent attivi")
                    )
                } else {
                    List(viewModel.torrents) { torrent in
                        TorrentRow(torrent: torrent)
                    }
                    .refreshable {
                        await viewModel.fetchTorrents(settings: settings)
                    }
                }
            }
            .navigationTitle("Torrent")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.fetchTorrents(settings: settings)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.fetchTorrents(settings: settings)
        }
        .onAppear {
            viewModel.setupTimer(with: settings)
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
} 