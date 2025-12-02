import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AddTorrentViewModel
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    
    @State private var showFileImporter = false
    @State private var showingPathManager = false
    
    var body: some View {
        NavigationView {
            formContent
                .navigationTitle("Add Torrent")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .alert("Error", isPresented: $viewModel.showError) {
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
                .sheet(isPresented: $showingPathManager) {
                    PathManagementView()
                }
                .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                    if shouldDismiss {
                        dismiss()
                    }
                }
        }
    }
    
    private var formContent: some View {
        Form {
            Section {
                Picker("Method", selection: $viewModel.isMagnetLink) {
                    Text("Magnet Link").tag(true)
                    Text("Torrent File").tag(false)
                }
                .pickerStyle(.segmented)
            }
            
            if viewModel.isMagnetLink {
                Section(header: Text("Magnet Link")) {
                    TextField("Enter magnet Link", text: $viewModel.magnetUrl)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } else {
                Section(header: Text("Torrent File")) {
                    if let fileName = viewModel.selectedFileName {
                        HStack {
                            Text(fileName)
                            Spacer()
                            Button("Change") { showFileImporter = true }
                        }
                    } else {
                        Button("Select File") { showFileImporter = true }
                    }
                    
                    if AppEnvironment.isUITesting {
                        Button("Mock Pick File") {
                            viewModel.mockFileSelection(
                                fileName: "mock.torrent",
                                data: "mock_data".data(using: .utf8)!
                            )
                        }
                        .accessibilityIdentifier("mock_pick_file_button")
                    }
                }
            }
            
            Section(header: Text("Download Path")) {
                HStack {
                    TextField("Path", text: $viewModel.downloadPath)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if !recentPathsManager.paths.isEmpty {
                        Menu {
                            ForEach(recentPathsManager.paths, id: \.self) { recentPath in
                                Button(recentPath.path) {
                                    viewModel.downloadPath = recentPath.path
                                }
                            }
                            Divider()
                            Button(action: { showingPathManager = true }) {
                                Label("Manage Paths", systemImage: "folder.badge.gear")
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
                        Text("Add Torrent")
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