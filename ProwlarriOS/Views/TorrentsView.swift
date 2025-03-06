import SwiftUI

struct TorrentsView: View {
    @StateObject private var viewModel = TorrentsViewModel()
    @EnvironmentObject var settings: ProwlarrSettings
    @State private var showingAddTorrent = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                
                // Pulsante floating per aggiungere torrent
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddTorrent = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
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
            .sheet(isPresented: $showingAddTorrent) {
                AddTorrentView()
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