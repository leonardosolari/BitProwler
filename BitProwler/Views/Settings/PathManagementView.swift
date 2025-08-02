// File: /ProwlarriOS/Views/Settings/PathManagementView.swift

import SwiftUI

struct PathManagementView: View {
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if recentPathsManager.paths.isEmpty {
                    ContentUnavailableView(
                        "Nessun Percorso",
                        systemImage: "folder.badge.questionmark",
                        description: Text("I percorsi che usi per i download appariranno qui.")
                    )
                } else {
                    List {
                        ForEach(recentPathsManager.paths) { path in
                            VStack(alignment: .leading) {
                                Text(path.path)
                                    .font(.body)
                                Text("Usato il: \(path.lastUsed.formatted(date: .numeric, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: recentPathsManager.deletePath)
                    }
                }
            }
            .navigationTitle("Gestione Percorsi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Aggiunge il pulsante standard di iOS per modificare/eliminare
                    EditButton()
                }
            }
        }
    }
}