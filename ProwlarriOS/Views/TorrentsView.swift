// File: /ProwlarriOS/Views/TorrentsView.swift
import SwiftUI

struct TorrentsView: View {
    @StateObject private var viewModel = TorrentsViewModel()
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @EnvironmentObject var recentPathsManager: RecentPathsManager // Aggiungi questa dipendenza
    
    @State private var showingAddTorrent = false
    
    // Creiamo qui il ViewModel per la sheet.
    // Usiamo @State per un oggetto di classe perché il suo ciclo di vita
    // è legato alla presentazione della sheet.
    @State private var addTorrentViewModel: AddTorrentViewModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                content
                
                floatingAddButton
            }
            .navigationTitle("Torrent")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.fetchTorrents() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddTorrent, onDismiss: {
                // Resetta il ViewModel quando la sheet viene chiusa
                addTorrentViewModel = nil
            }) {
                // Assicurati che il ViewModel esista prima di presentare la vista
                if let addTorrentViewModel = addTorrentViewModel {
                    AddTorrentView(viewModel: addTorrentViewModel)
                }
            }
        }
        .onAppear {
            viewModel.setup(with: qbittorrentManager)
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.torrents.isEmpty {
            ProgressView("Caricamento...")
        } else if let error = viewModel.error {
            ContentUnavailableView {
                Label("Errore di Connessione", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Riprova") {
                    Task { await viewModel.fetchTorrents() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.torrents.isEmpty {
            ContentUnavailableView(
                "Nessun Torrent",
                systemImage: "arrow.down.circle",
                description: Text("Non ci sono torrent attivi al momento.")
            )
        } else {
            List(viewModel.torrents, id: \.hash) { torrent in
                TorrentRow(torrent: torrent)
            }
            .refreshable {
                await viewModel.fetchTorrents()
            }
        }
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // Crea il ViewModel *prima* di mostrare la sheet
                    addTorrentViewModel = AddTorrentViewModel(
                        qbittorrentManager: qbittorrentManager,
                        recentPathsManager: recentPathsManager
                    )
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
}