import SwiftUI

struct TorrentFilesView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: TorrentFilesViewModel
    
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
                if viewModel.isLoading && viewModel.fileTree.isEmpty {
                    ProgressView("Loading files...")
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "xmark.octagon", description: Text(error))
                } else if viewModel.fileTree.isEmpty {
                    ContentUnavailableView("No Files", systemImage: "doc.questionmark", description: Text("Could not find the files for this torrent"))
                } else {
                    List(viewModel.fileTree, id: \.self, children: \.children) { node in
                        TorrentFileNodeRow(node: node, onToggle: {
                            viewModel.toggleNodeSelection(node)
                        })
                    }
                    .accessibilityIdentifier("file_list")
                }
            }
            .navigationTitle("Torrent Files")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.error) { _, error in
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
                    .accessibilityIdentifier("save_files_button")
                }
            }
            .task {
                await viewModel.fetchFiles()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.fileTree.isEmpty {
                    ProgressView()
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct TorrentFileNodeRow: View {
    let node: TorrentFileNode
    let onToggle: () -> Void
    
    @State private var isExpanded: Bool = false
    
    private var accessibilityIDComponent: String {
        if let file = node.file {
            return "file-\(file.index)"
        } else {
            return "dir-\(node.name.replacingOccurrences(of: " ", with: "-"))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Button(action: onToggle) {
                    Image(systemName: node.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(node.isSelected ? .accentColor : .secondary)
                        .font(.title2)
                        .frame(width: 30)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("file_toggle_\(accessibilityIDComponent)")
                .accessibilityValue(node.isSelected ? "Selected" : "Not Selected")
                .accessibilityLabel(node.isSelected ? "Deselect \(node.name)" : "Select \(node.name)")
                .accessibilityElement(children: .ignore)
                
                FileIconView(filename: node.name, isDirectory: node.children != nil)
                
                Text(node.name)
                    .font(.body)
                    .lineLimit(1)
                
                Spacer()
                
                Text(Formatters.formatSize(node.totalSize))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            ProgressView(value: node.totalProgress)
                .tint(node.totalProgress >= 1.0 ? .green : .blue)
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = node.name
            }) {
                Label("Copy Name", systemImage: "doc.on.doc")
            }
        }
        .accessibilityIdentifier("file_row_\(accessibilityIDComponent)")
    }
}