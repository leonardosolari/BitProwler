import SwiftUI

struct TorrentsView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        TorrentsContentView(apiService: container.qbittorrentService)
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
            .searchable(text: $viewModel.searchText, prompt: "Search by name...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SortMenu(activeSortOption: $viewModel.activeSortOption, title: "Sort by...")
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
        if viewModel.isLoading && viewModel.torrents.isEmpty {
            ProgressView("Loading...")
        } else if let error = viewModel.error {
            ContentUnavailableView {
                Label("Connection Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.fetchTorrents() }
                }
                .buttonStyle(.borderedProminent)
            }
            .accessibilityIdentifier("torrents_error_view")
        } else if viewModel.torrents.isEmpty {
            if !viewModel.searchText.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ContentUnavailableView(
                    "No Torrents",
                    systemImage: "arrow.down.circle",
                    description: Text("There are no active torrents at the moment")
                )
                .accessibilityIdentifier("torrents_empty_state")
            }
        } else {
            List(viewModel.torrents) { torrent in
                TorrentRow(torrent: torrent)
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.fetchTorrents()
            }
            .accessibilityIdentifier("torrents_list")
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
                        apiService: container.qbittorrentService
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
                .accessibilityIdentifier("add_torrent_button")
            }
        }
    }
}