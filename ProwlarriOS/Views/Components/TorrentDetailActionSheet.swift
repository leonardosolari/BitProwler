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
                    LabeledContent("Stato", value: TorrentState(from: torrent.state).displayName)
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
        guard let server = settings.activeQBittorrentServer else {
            errorMessage = "Nessun server qBittorrent configurato"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Prima effettuiamo il login
        guard let loginSuccess = await login(server: server) else {
            errorMessage = "Errore di connessione al server"
            showError = true
            return
        }
        
        if !loginSuccess {
            errorMessage = "Login fallito"
            showError = true
            return
        }
        
        guard let url = URL(string: "\(server.url)api/v2/torrents/delete") else {
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
        let state = torrent.state.lowercased()
        return state.contains("paused") || state.contains("stopped") || state.contains("stalled")
    }
    
    private func togglePauseResume() async {
        guard let server = settings.activeQBittorrentServer else {
            errorMessage = "Nessun server qBittorrent configurato"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Prima effettuiamo il login
        guard let loginSuccess = await login(server: server) else {
            errorMessage = "Errore di connessione al server"
            showError = true
            return
        }
        
        if !loginSuccess {
            errorMessage = "Login fallito"
            showError = true
            return
        }
        
        let endpoint = isPaused ? "start" : "stop"
        
        guard let url = URL(string: "\(server.url)api/v2/torrents/\(endpoint)") else {
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
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Attendiamo un breve momento per permettere a qBittorrent di aggiornare lo stato
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
                    dismiss()
                } else {
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Errore nel cambio stato del torrent (Status: \(httpResponse.statusCode))"])
                }
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Risposta non valida dal server"])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func login(server: QBittorrentServer) async -> Bool? {
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(server.username)&password=\(server.password)"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
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
        guard let server = settings.activeQBittorrentServer else {
            errorMessage = "Nessun server qBittorrent configurato"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Prima effettuiamo il login
        guard let loginSuccess = await login(server: server) else {
            errorMessage = "Errore di connessione al server"
            showError = true
            return
        }
        
        if !loginSuccess {
            errorMessage = "Login fallito"
            showError = true
            return
        }
        
        guard let url = URL(string: "\(server.url)api/v2/torrents/setLocation") else {
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
    
    private func login(server: QBittorrentServer) async -> Bool? {
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(server.username)&password=\(server.password)"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}