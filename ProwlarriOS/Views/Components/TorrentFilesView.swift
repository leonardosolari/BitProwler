// File: /ProwlarriOS/Views/Components/TorrentFilesView.swift

import SwiftUI

struct TorrentFilesView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    @State private var files: [TorrentFile] = []
    @State private var isLoading = false
    
    // Stato per tenere traccia del file espanso
    @State private var expandedFile: TorrentFile?
    
    private let apiService: QBittorrentAPIService = NetworkManager()
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Caricamento file...")
                } else if files.isEmpty {
                    ContentUnavailableView("Nessun File", systemImage: "doc.questionmark", description: Text("Non è stato possibile trovare i file per questo torrent."))
                } else {
                    List {
                        ForEach(files) { file in
                            TorrentFileRow(file: file, expandedFile: $expandedFile)
                        }
                    }
                }
            }
            .navigationTitle("File del Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .task {
                await fetchFiles()
            }
        }
    }
    
    private func fetchFiles() async {
        guard let server = qbittorrentManager.activeQBittorrentServer else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedFiles = try await apiService.getFiles(for: torrent, on: server)
            self.files = fetchedFiles
        } catch {
            // Potremmo mostrare un errore all'utente qui
            print("Error fetching files: \(error.localizedDescription)")
        }
    }
}

// MARK: - Vista per la singola riga

struct TorrentFileRow: View {
    let file: TorrentFile
    @Binding var expandedFile: TorrentFile?
    
    private var isExpanded: Bool {
        expandedFile == file
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // 1. Icona del file
                FileIconView(filename: file.name)
                
                // 2. Nome del file (espandibile)
                Text(file.name)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 1) // Logica di espansione
                
                Spacer()
                
                // 3. Dimensione del file
                Text(formatSize(file.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            // 4. Barra di progresso
            ProgressView(value: file.progress)
                .tint(file.progress >= 1.0 ? .green : .blue)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle()) // Rende l'intera area toccabile
        .onTapGesture {
            // Animazione per un'espansione fluida
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                expandedFile = isExpanded ? nil : file
            }
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = file.name
            }) {
                Label("Copia Nome File", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll] // Mostra l'unità più appropriata
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}