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