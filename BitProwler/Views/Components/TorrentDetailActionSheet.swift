import SwiftUI

struct TorrentDetailActionSheet: View {
    @StateObject private var viewModel: TorrentActionsViewModel
    @EnvironmentObject private var container: AppContainer
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingDeleteWithDataAlert = false
    @State private var showingLocationPicker = false
    @State private var showingFileList = false
    
    private let torrent: QBittorrentTorrent
    
    init(torrent: QBittorrentTorrent, manager: QBittorrentServerManager, apiService: QBittorrentAPIService) {
        self.torrent = torrent
        _viewModel = StateObject(wrappedValue: TorrentActionsViewModel(torrent: torrent, manager: manager, apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView(torrent: torrent)
                
                ScrollView {
                    VStack(spacing: 24) {
                        PrimaryActionsGrid()
                        ManagementList()
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dettagli Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .alert("Elimina Torrent", isPresented: $showingDeleteAlert, actions: {
                Button("Annulla", role: .cancel) {}
                Button("Elimina", role: .destructive) {
                    Task { await viewModel.performAction(.delete) { dismiss() } }
                }
            }, message: {
                Text("Vuoi eliminare questo torrent? I dati scaricati non verranno rimossi.")
            })
            .alert("Elimina Torrent e Dati", isPresented: $showingDeleteWithDataAlert, actions: {
                Button("Annulla", role: .cancel) {}
                Button("Elimina", role: .destructive) {
                    Task { await viewModel.performAction(.delete, deleteFiles: true) { dismiss() } }
                }
            }, message: {
                Text("ATTENZIONE: Questa azione è irreversibile. Vuoi eliminare questo torrent e tutti i dati scaricati?")
            })
            .alert("Errore", isPresented: $viewModel.showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore sconosciuto.")
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
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func PrimaryActionsGrid() -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        
        LazyVGrid(columns: columns, spacing: 16) {
            ActionButton(
                title: viewModel.isPaused ? "Riprendi" : "Pausa",
                icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                color: viewModel.isPaused ? .green : .orange
            ) {
                Task { await viewModel.performAction(.togglePauseResume) { dismiss() } }
            }
            
            ActionButton(
                title: viewModel.isForced ? "Annulla" : "Forza",
                icon: viewModel.isForced ? "bolt.slash.fill" : "bolt.fill",
                color: .purple
            ) {
                Task { await viewModel.performAction(.forceStart, forceStart: !viewModel.isForced) { dismiss() } }
            }
            
            ActionButton(title: "Ricontrolla", icon: "arrow.triangle.2.circlepath", color: .blue) {
                Task { await viewModel.performAction(.recheck) { dismiss() } }
            }
            
            ActionButton(title: "Sposta", icon: "folder.fill", color: .cyan) {
                showingLocationPicker = true
            }
        }
    }
    
    @ViewBuilder
    private func ManagementList() -> some View {
        VStack {
            List {
                Section(header: Text("Gestione")) {
                    Button(action: { showingFileList = true }) {
                        Label("Mostra File", systemImage: "doc.text")
                    }
                }
                
                Section(header: Text("Zona Pericolo")) {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Elimina Torrent", systemImage: "trash")
                    }
                    Button(role: .destructive, action: { showingDeleteWithDataAlert = true }) {
                        Label("Elimina Torrent e Dati", systemImage: "trash.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .frame(height: 250)
            .scrollDisabled(true)
        }
    }
}

// MARK: - Reusable Components

private struct HeaderView: View {
    let torrent: QBittorrentTorrent
    
    var body: some View {
        VStack(spacing: 16) {
            Text(torrent.name)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            HStack {
                StatItem(icon: "tray.full.fill", value: formatSize(torrent.size))
                Spacer()
                StatusBadge(state: torrent.state)
                Spacer()
                StatItem(icon: "arrow.up.arrow.down.circle.fill", value: String(format: "%.2f", torrent.ratio))
            }
            
            ProgressView(value: torrent.progress)
                .tint(StatusBadge.getBackgroundColor(for: torrent.state))
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Cerchio con icona
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                .frame(width: 56, height: 56)
                
                // Testo sotto l'icona
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
}

struct LocationPickerView: View {
    @ObservedObject var viewModel: TorrentActionsViewModel
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newLocation = ""
    @State private var showingPathManager = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nuova Posizione")) {
                    HStack {
                        TextField("Percorso Completo", text: $newLocation)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        if !recentPathsManager.paths.isEmpty {
                            Menu {
                                ForEach(recentPathsManager.paths, id: \.self) { recentPath in
                                    Button(recentPath.path) { newLocation = recentPath.path }
                                }
                                Divider()
                                Button(action: { showingPathManager = true }) {
                                    Label("Gestisci Percorsi", systemImage: "folder.badge.gear")
                                }
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Sposta") {
                        Task {
                            await viewModel.performAction(.move, location: newLocation) {
                                recentPathsManager.addPath(newLocation)
                                dismiss()
                            }
                        }
                    }
                    .disabled(newLocation.isEmpty)
                }
            }
            .navigationTitle("Sposta Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPathManager) {
                PathManagementView()
            }
        }
    }
}