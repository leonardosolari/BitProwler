import SwiftUI

struct LocationPickerView: View {
    @ObservedObject var viewModel: TorrentActionsViewModel
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newLocation = ""
    @State private var showingPathManager = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Location")) {
                    HStack {
                        TextField("Full Path", text: $newLocation)
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
                    Button("Move") {
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
            .navigationTitle("Move Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPathManager) {
                PathManagementView()
            }
        }
    }
}
