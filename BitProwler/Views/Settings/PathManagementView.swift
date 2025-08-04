import SwiftUI

struct PathManagementView: View {
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if recentPathsManager.paths.isEmpty {
                    ContentUnavailableView(
                        "No Paths",
                        systemImage: "folder.badge.questionmark",
                        description: Text("The paths you use for downloads will appear here")
                    )
                } else {
                    List {
                        ForEach(recentPathsManager.paths) { path in
                            VStack(alignment: .leading) {
                                Text(path.path)
                                    .font(.body)
                                Text("Last Used: \(path.lastUsed.formatted(date: .numeric, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: recentPathsManager.deletePath)
                    }
                }
            }
            .navigationTitle("Path Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}
