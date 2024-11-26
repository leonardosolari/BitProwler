import SwiftUI

struct TorrentDetailActionSheet: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: ProwlarrSettings
    @State private var showingDeleteAlert = false
    @State private var showingDeleteWithDataAlert = false
    @State private var showingLocationPicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Informazioni")) {
                    LabeledContent("Nome", value: torrent.name)
                    LabeledContent("Stato", value: torrent.state.capitalized)
                    LabeledContent("Dimensione", value: formatSize(torrent.size))
                    LabeledContent("Progresso", value: "\(Int(torrent.progress * 100))%")
                    LabeledContent("Ratio", value: String(format: "%.2f", torrent.ratio))
                }
                
                Section {
                    Button {
                        Task {
                            await togglePauseResume()
                        }
                    } label: {
                        Label(isPaused ? "Riprendi" : "Pausa", 
                              systemImage: isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(isPaused ? .green : .orange)
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Elimina Torrent", systemImage: "trash")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteWithDataAlert = true
                    } label: {
                        Label("Elimina Torrent e Dati", systemImage: "trash.fill")
                    }
                    
                    Button {
                        showingLocationPicker = true
                    } label: {
                        Label("Sposta", systemImage: "folder")
                    }
                }
            }
            .navigationTitle("Gestione Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .alert("Elimina Torrent", isPresented: $showingDeleteAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Elimina", role: .destructive) {
                    Task {
                        await deleteTorrent(withData: false)
                    }
                }
            } message: {
                Text("Vuoi eliminare questo torrent?")
            }
            .alert("Elimina Torrent e Dati", isPresented: $showingDeleteWithDataAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Elimina", role: .destructive) {
                    Task {
                        await deleteTorrent(withData: true)
                    }
                }
            } message: {
                Text("Vuoi eliminare questo torrent e tutti i dati scaricati?")
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(torrent: torrent)
            }
            .alert("Errore", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Si è verificato un errore")
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(Color.systemBackground)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func deleteTorrent(withData: Bool) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(settings.qbittorrentUrl)/api/v2/torrents/delete") else {
            errorMessage = "URL non valido"
            showError = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "hashes=\(torrent.hash)&deleteFiles=\(withData)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                dismiss()
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Errore nell'eliminazione del torrent"])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private var isPaused: Bool {
        torrent.state.lowercased().contains("paused")
    }
    
    private func togglePauseResume() async {
        isLoading = true
        defer { isLoading = false }
        
        let endpoint = isPaused ? "resume" : "pause"
        
        guard let url = URL(string: "\(settings.qbittorrentUrl)/api/v2/torrents/\(endpoint)") else {
            errorMessage = "URL non valido"
            showError = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "hashes=\(torrent.hash)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                dismiss()
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Errore nel cambio stato del torrent"])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct LocationPickerView: View {
    let torrent: QBittorrentTorrent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: ProwlarrSettings
    @State private var newLocation = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nuova Posizione")) {
                    TextField("Percorso Completo", text: $newLocation)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Text("Inserisci il percorso completo della nuova posizione")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Sposta") {
                        Task {
                            await moveLocation()
                        }
                    }
                    .disabled(newLocation.isEmpty)
                }
            }
            .navigationTitle("Sposta Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
            .alert("Errore", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Si è verificato un errore")
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(Color.systemBackground)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func moveLocation() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(settings.qbittorrentUrl)/api/v2/torrents/setLocation") else {
            errorMessage = "URL non valido"
            showError = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "hashes=\(torrent.hash)&location=\(newLocation)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                dismiss()
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Errore nello spostamento del torrent"])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}