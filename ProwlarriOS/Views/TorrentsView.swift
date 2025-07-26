// File: /ProwlarriOS/Views/TorrentsView.swift

import SwiftUI

struct TorrentsView: View {
    @StateObject private var viewModel = TorrentsViewModel()
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    
    @State private var showingAddTorrent = false
    @State private var addTorrentViewModel: AddTorrentViewModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                content
                floatingAddButton
            }
            .navigationTitle("Torrent")
            // 1. Aggiungi la barra di ricerca
            .searchable(text: $viewModel.searchText, prompt: "Cerca per nome...")
            .toolbar {
                // 2. Aggiungi il menu di ordinamento
                ToolbarItem(placement: .navigationBarLeading) {
                    SortMenu(viewModel: viewModel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.fetchTorrents() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddTorrent, onDismiss: {
                addTorrentViewModel = nil
            }) {
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
        // La vista ora osserva `filteredTorrents` invece di `torrents`
        if viewModel.isLoading && viewModel.filteredTorrents.isEmpty {
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
        } else if viewModel.filteredTorrents.isEmpty {
            // Messaggio contestuale se la lista è vuota a causa della ricerca
            if !viewModel.searchText.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ContentUnavailableView(
                    "Nessun Torrent",
                    systemImage: "arrow.down.circle",
                    description: Text("Non ci sono torrent attivi al momento.")
                )
            }
        } else {
            // La lista ora itera su `filteredTorrents`
            List(viewModel.filteredTorrents) { torrent in
                TorrentRow(torrent: torrent)
            }
            .listStyle(.plain) // Stile migliore per le card
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
                    addTorrentViewModel = AddTorrentViewModel(
                        qbittorrentManager: qbittorrentManager,
                        recentPathsManager: recentPathsManager
                    )
                    showingAddTorrent = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.accentColor)
                        .background(Color(.systemBackground)) // Adatta a light/dark mode
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding()
            }
        }
    }
}

// NUOVA VISTA COMPONENTE PER IL MENU DI ORDINAMENTO
private struct SortMenu: View {
    @ObservedObject var viewModel: TorrentsViewModel
    
    var body: some View {
        Menu {
            Picker("Ordina per", selection: $viewModel.activeSortOption) {
                ForEach(TorrentSortOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.systemImage).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
    }
}