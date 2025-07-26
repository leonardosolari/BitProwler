// File: /ProwlarriOS/Views/Components/AddTorrentView.swift

import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentView: View {
    @Environment(\.dismiss) var dismiss
    
    // Usiamo @ObservedObject perché il ciclo di vita del ViewModel
    // sarà gestito dalla vista che presenta questa sheet.
    @ObservedObject var viewModel: AddTorrentViewModel
    
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    
    @State private var showFileImporter = false
    @State private var showingRecentPaths = false
    
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
                .sheet(isPresented: $showingRecentPaths) {
                    recentPathsSheet
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
                TextField("Percorso", text: $viewModel.downloadPath)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if !recentPathsManager.paths.isEmpty {
                    Button(action: { showingRecentPaths = true }) {
                        Label("Percorsi Recenti", systemImage: "clock")
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
    
    private var recentPathsSheet: some View {
        NavigationView {
            List(recentPathsManager.paths) { recentPath in
                Button(action: {
                    viewModel.downloadPath = recentPath.path
                    showingRecentPaths = false
                }) {
                    VStack(alignment: .leading) {
                        Text(recentPath.path)
                        Text(recentPath.lastUsed.formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Percorsi Recenti")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { showingRecentPaths = false }
                }
            }
        }
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