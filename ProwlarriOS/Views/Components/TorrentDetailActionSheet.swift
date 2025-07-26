// File: /ProwlarriOS/Views/Components/TorrentDetailActionSheet.swift

import SwiftUI

struct TorrentDetailActionSheet: View {
    @StateObject private var viewModel: TorrentActionsViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingDeleteWithDataAlert = false
    @State private var showingLocationPicker = false
    @State private var showingFileList = false
    
    private let torrent: QBittorrentTorrent
    
    init(torrent: QBittorrentTorrent, manager: QBittorrentServerManager) {
        self.torrent = torrent
        _viewModel = StateObject(wrappedValue: TorrentActionsViewModel(torrent: torrent, manager: manager))
    }
    
    var body: some View {
        NavigationView {
            listContent
                .navigationTitle("Gestione Torrent")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
    
    private var listContent: some View {
        List {
            headerSection
            infoSection
            actionsSection
        }
    }
    
    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                CircularProgressView(progress: torrent.progress)
                Text(torrent.name)
                    .font(.headline)
                    .lineLimit(3)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var infoSection: some View {
        Section(header: Text("Informazioni")) {
            LabeledContent("Stato", value: TorrentState(from: torrent.state).displayName)
            LabeledContent("Dimensione", value: formatSize(torrent.size))
            LabeledContent("Ratio", value: String(format: "%.2f", torrent.ratio))
        }
    }
    
    private var actionsSection: some View {
        Section(header: Text("Azioni")) {
            Button {
                Task { await viewModel.performAction(.togglePauseResume) { dismiss() } }
            } label: {
                Label(viewModel.isPaused ? "Riprendi" : "Pausa",
                      systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .foregroundColor(viewModel.isPaused ? .green : .orange)
            }
            
            Button {
                Task { await viewModel.performAction(.forceStart, forceStart: !viewModel.isForced) { dismiss() } }
            } label: {
                Label(viewModel.isForced ? "Annulla Avvio Forzato" : "Forza Avvio",
                      systemImage: viewModel.isForced ? "bolt.slash.fill" : "bolt.fill")
                    .foregroundColor(.purple)
            }
            
            Button {
                Task { await viewModel.performAction(.recheck) { dismiss() } }
            } label: {
                Label("Ricontrolla", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Button { showingLocationPicker = true } label: {
                Label("Sposta", systemImage: "folder")
            }
            
            Button { showingFileList = true } label: {
                Label("Mostra File", systemImage: "doc.text")
            }
            
            Button(role: .destructive) { showingDeleteAlert = true } label: {
                Label("Elimina Torrent", systemImage: "trash")
            }
            
            Button(role: .destructive) { showingDeleteWithDataAlert = true } label: {
                Label("Elimina Torrent e Dati", systemImage: "trash.fill")
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// --- Viste Componente ---

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress >= 1.0 ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption.bold())
        }
        .frame(width: 50, height: 50)
    }
}

// VISTA AGGIORNATA
struct LocationPickerView: View {
    @ObservedObject var viewModel: TorrentActionsViewModel
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newLocation = ""
    @State private var showingPathManager = false // Stato per la nuova sheet
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nuova Posizione")) {
                    HStack {
                        TextField("Percorso Completo", text: $newLocation)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        // NUOVO MENU UNIFICATO
                        if !recentPathsManager.paths.isEmpty {
                            Menu {
                                ForEach(recentPathsManager.paths, id: \.self) { recentPath in
                                    Button(recentPath.path) {
                                        newLocation = recentPath.path
                                    }
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
            // Sheet per la gestione dei percorsi
            .sheet(isPresented: $showingPathManager) {
                PathManagementView()
            }
        }
    }
}