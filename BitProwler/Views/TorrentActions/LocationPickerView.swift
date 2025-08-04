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