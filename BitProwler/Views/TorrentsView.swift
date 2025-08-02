import SwiftUI

struct TorrentsView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        TorrentsContentView(apiService: container.apiService)
    }
}

fileprivate struct TorrentsContentView: View {
    @StateObject private var viewModel: TorrentsViewModel
    @EnvironmentObject private var container: AppContainer
    
    @State private var showingAddTorrent = false
    @State private var addTorrentViewModel: AddTorrentViewModel?
    
    init(apiService: QBittorrentAPIService) {
        _viewModel = StateObject(wrappedValue: TorrentsViewModel(apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                content
                floatingAddButton
            }
            .navigationTitle("Torrent")
            .searchable(text: $viewModel.searchText, prompt: "Cerca per nome...")
            .toolbar {
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
            viewModel.setup(with: container.qbittorrentManager)
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
    
    @ViewBuilder
    private var content: some View {
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
            List(viewModel.filteredTorrents) { torrent in
                TorrentRow(torrent: torrent)
            }
            .listStyle(.plain)
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
                        qbittorrentManager: container.qbittorrentManager,
                        recentPathsManager: container.recentPathsManager,
                        apiService: container.apiService
                    )
                    showingAddTorrent = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.accentColor)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding()
            }
        }
    }
}

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