import SwiftUI

struct PathManagementView: View {
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    
    var body: some View {
        Group {
            if recentPathsManager.paths.isEmpty {
                ContentUnavailableView(
                    "No Paths",
                    systemImage: "folder.badge.questionmark",
                    description: Text("The paths you use for downloads will appear here")
                )
                .accessibilityIdentifier("paths_empty_state")
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
                        .accessibilityIdentifier("path_row_\(path.path)")
                    }
                    .onDelete(perform: recentPathsManager.deletePath)
                }
                .accessibilityIdentifier("paths_list")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
        .navigationTitle("Path Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}