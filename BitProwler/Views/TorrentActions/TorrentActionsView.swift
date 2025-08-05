import SwiftUI

struct TorrentActionsView: View {
    @StateObject private var viewModel: TorrentActionsViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingDeleteWithDataAlert = false
    @State private var showingLocationPicker = false
    @State private var showingFileList = false
    
    private let torrent: QBittorrentTorrent
    
    init(torrent: QBittorrentTorrent, manager: GenericServerManager<QBittorrentServer>, apiService: QBittorrentAPIService) {
        self.torrent = torrent
        _viewModel = StateObject(wrappedValue: TorrentActionsViewModel(torrent: torrent, manager: manager, apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TorrentActionsHeaderView(torrent: torrent)
                
                ScrollView {
                    VStack(spacing: 24) {
                        primaryActionsGrid
                        managementList
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Torrent Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Elimina Torrent", isPresented: $showingDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel.performAction(.delete) { dismiss() } }
                }
            }, message: {
                Text("Do you want to delete this torrent? The downloaded data will not be removed")
            })
            .alert("Delete Torrent and Data", isPresented: $showingDeleteWithDataAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel.performAction(.delete, deleteFiles: true) { dismiss() } }
                }
            }, message: {
                Text("WARNING: This action is irreversible. Do you want to delete this torrent and all its downloaded data?")
            })
            .alert("Error", isPresented: $viewModel.showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(viewModel.errorMessage ?? "An Unknown Errror occurred")
            })
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFileList) {
                TorrentFilesView(torrent: torrent)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(30)
                        .background(.thinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var primaryActionsGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 16) {
            TorrentActionButton(
                title: viewModel.isPaused ? "Resume" : "Pause",
                icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                color: viewModel.isPaused ? .green : .orange
            ) {
                Task { await viewModel.performAction(.togglePauseResume) { dismiss() } }
            }
            
            TorrentActionButton(
                title: viewModel.isForced ? "Annulla" : "Forza",
                icon: viewModel.isForced ? "bolt.slash.fill" : "bolt.fill",
                color: .purple
            ) {
                Task { await viewModel.performAction(.forceStart, forceStart: !viewModel.isForced) { dismiss() } }
            }
            
            TorrentActionButton(title: "Ricontrolla", icon: "arrow.triangle.2.circlepath", color: .blue) {
                Task { await viewModel.performAction(.recheck) { dismiss() } }
            }
            
            TorrentActionButton(title: "Move", icon: "folder.fill", color: .cyan) {
                showingLocationPicker = true
            }
        }
    }
    
    private var managementList: some View {
        List {
            Section(header: Text("Management")) {
                Button(action: { showingFileList = true }) {
                    Label("Show Files", systemImage: "doc.text")
                }
            }
            
            Section(header: Text("Danger Zone")) {
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Delete Torrent", systemImage: "trash")
                }
                Button(role: .destructive, action: { showingDeleteWithDataAlert = true }) {
                    Label("Delete Torrent and Data", systemImage: "trash.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .frame(height: 250)
        .scrollDisabled(true)
    }
}
