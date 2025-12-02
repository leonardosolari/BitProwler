import SwiftUI

struct TorrentActionsView: View {
    @StateObject private var viewModel: TorrentActionsViewModel
    @EnvironmentObject var container: AppContainer
    
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
            .alert("Delete Torrent", isPresented: $showingDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel.performAction(.delete) { dismiss() } }
                }
            }, message: {
                Text("Do you want to delete this torrent? The downloaded data will not be removed.")
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
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            })
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(viewModel: viewModel, onMoveComplete: { dismiss() })
            }
            .sheet(isPresented: $showingFileList) {
                TorrentFilesView(torrent: torrent, container: container)
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
        
        let pauseResumeTitle: LocalizedStringKey = viewModel.isPaused ? "Resume" : "Pause"
        let forceTitle: LocalizedStringKey = viewModel.isForced ? "Unforce" : "Force"
        
        return LazyVGrid(columns: columns, spacing: 16) {
            TorrentActionButton(
                title: pauseResumeTitle,
                icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                color: viewModel.isPaused ? .green : .orange
            ) {
                Task { await viewModel.performAction(.togglePauseResume) { dismiss() } }
            }
            .accessibilityIdentifier("action_button_toggle_pause")
            
            TorrentActionButton(
                title: forceTitle,
                icon: viewModel.isForced ? "bolt.slash.fill" : "bolt.fill",
                color: .purple
            ) {
                Task { await viewModel.performAction(.forceStart, forceStart: !viewModel.isForced) { dismiss() } }
            }
            .accessibilityIdentifier("action_button_toggle_force")
            
            TorrentActionButton(title: "Recheck", icon: "arrow.triangle.2.circlepath", color: .blue) {
                Task { await viewModel.performAction(.recheck) { dismiss() } }
            }
            .accessibilityIdentifier("action_button_recheck")
            
            TorrentActionButton(title: "Move", icon: "folder.fill", color: .cyan) {
                showingLocationPicker = true
            }
            .accessibilityIdentifier("action_button_move")
        }
    }
    
    private var managementList: some View {
        List {
            Section(header: Text("Management")) {
                Button(action: { showingFileList = true }) {
                    Label("Show Files", systemImage: "doc.text")
                }
                .accessibilityIdentifier("action_button_show_files")
            }
            
            Section(header: Text("Danger Zone")) {
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Delete Torrent", systemImage: "trash")
                }
                .accessibilityIdentifier("action_button_delete")
                
                Button(role: .destructive, action: { showingDeleteWithDataAlert = true }) {
                    Label("Delete Torrent and Data", systemImage: "trash.fill")
                }
                .accessibilityIdentifier("action_button_delete_data")
            }
        }
        .listStyle(.insetGrouped)
        .frame(height: 250)
        .scrollDisabled(true)
    }
}