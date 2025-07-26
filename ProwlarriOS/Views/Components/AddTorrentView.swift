// File: /ProwlarriOS/Views/Components/AddTorrentView.swift

import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AddTorrentViewModel
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    
    @State private var showFileImporter = false
    @State private var showingPathManager = false // Stato per la nuova sheet
    
    var body: some View {
        NavigationView {
            formContent
                .navigationTitle("Aggiungi Torrent")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annulla") { dismiss() }
                    }
                }
                .alert("Errore", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.errorMessage ?? "Si è verificato un errore")
                }
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.torrent],
                    allowsMultipleSelection: false
                ) { result in
                    viewModel.handleFileImport(result)
                }
                .overlay {
                    if viewModel.isLoading {
                        loadingView
                    }
                }
                // Sheet per la gestione dei percorsi
                .sheet(isPresented: $showingPathManager) {
                    PathManagementView()
                }
                .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                    if shouldDismiss {
                        dismiss()
                    }
                }
        }
    }
    
    private var formContent: some View {
        Form {
            Section {
                Picker("Metodo", selection: $viewModel.isMagnetLink) {
                    Text("Link Magnet").tag(true)
                    Text("File Torrent").tag(false)
                }
                .pickerStyle(.segmented)
            }
            
            if viewModel.isMagnetLink {
                Section(header: Text("Link Magnet")) {
                    TextField("Inserisci il link magnet", text: $viewModel.magnetUrl)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } else {
                Section(header: Text("File Torrent")) {
                    if let fileName = viewModel.selectedFileName {
                        HStack {
                            Text(fileName)
                            Spacer()
                            Button("Cambia") { showFileImporter = true }
                        }
                    } else {
                        Button("Seleziona File") { showFileImporter = true }
                    }
                }
            }
            
            Section(header: Text("Percorso Download")) {
                HStack {
                    TextField("Percorso", text: $viewModel.downloadPath)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    // NUOVO MENU UNIFICATO
                    if !recentPathsManager.paths.isEmpty {
                        Menu {
                            ForEach(recentPathsManager.paths, id: \.self) { recentPath in
                                Button(recentPath.path) {
                                    viewModel.downloadPath = recentPath.path
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
                Button(action: {
                    Task { await viewModel.addTorrent() }
                }) {
                    HStack {
                        Spacer()
                        Text("Aggiungi Torrent")
                        Spacer()
                    }
                }
                .disabled(!viewModel.canAddTorrent)
            }
        }
    }
    
    private var loadingView: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .overlay(
                ProgressView()
                    .padding()
                    .background(Color.systemBackground)
                    .cornerRadius(10)
            )
    }
}

// L'estensione UTType rimane invariata
extension UTType {
    static var torrent: UTType {
        if let type = UTType("application/x-bittorrent") {
            return type
        }
        if let type = UTType(tag: "torrent",
                            tagClass: .filenameExtension,
                            conformingTo: .data) {
            return type
        }
        return .data
    }
}