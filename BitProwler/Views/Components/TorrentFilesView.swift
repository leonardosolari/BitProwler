import SwiftUI

struct TorrentFilesView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: TorrentFilesViewModel
    
    @State private var expandedFile: TorrentFile?
    @State private var isShowingErrorAlert = false
    
    init(torrent: QBittorrentTorrent, container: AppContainer) {
        self.torrent = torrent
        _viewModel = StateObject(wrappedValue: TorrentFilesViewModel(
            torrent: torrent,
            qbittorrentManager: container.qbittorrentManager,
            apiService: container.qbittorrentService
        ))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.files.isEmpty {
                    ProgressView("Loading files...")
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "xmark.octagon", description: Text(error))
                } else if viewModel.files.isEmpty {
                    ContentUnavailableView("No Files", systemImage: "doc.questionmark", description: Text("Could not find the files for this torrent"))
                } else {
                    List {
                        ForEach(Array(viewModel.files.enumerated()), id: \.element.id) { index, file in
                            TorrentFileRow(
                                file: file,
                                isSelected: file.priority != 0,
                                onToggle: { viewModel.toggleFileSelection(at: index) },
                                expandedFile: $expandedFile
                            )
                        }
                    }
                }
            }
            .navigationTitle("Torrent Files")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.error) { error in
                if error != nil {
                    isShowingErrorAlert = true
                }
            }
            .alert("Error", isPresented: $isShowingErrorAlert, actions: {
                Button("OK", role: .cancel) { viewModel.error = nil }
            }, message: {
                Text(viewModel.error ?? "An unknown error occurred.")
            })
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveChanges() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.fetchFiles()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.files.isEmpty {
                    ProgressView()
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
}


struct TorrentFileRow: View {
    let file: TorrentFile
    let isSelected: Bool
    let onToggle: () -> Void
    @Binding var expandedFile: TorrentFile?
    
    private var isExpanded: Bool {
        expandedFile == file
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.title2)
                        .frame(width: 30)
                }
                .buttonStyle(.plain)
                
                FileIconView(filename: file.name)
                
                Text(file.name)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 1)
                
                Spacer()
                
                Text(Formatters.formatSize(file.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            ProgressView(value: file.progress)
                .tint(file.progress >= 1.0 ? .green : .blue)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                expandedFile = isExpanded ? nil : file
            }
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = file.name
            }) {
                Label("Copy File Name", systemImage: "doc.on.doc")
            }
        }
    }
}