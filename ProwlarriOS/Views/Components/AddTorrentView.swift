import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentView: View {
    @Environment(\.dismiss) var dismiss
    // Aggiorna le dipendenze con i nuovi manager
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    @EnvironmentObject var recentPathsManager: RecentPathsManager
    
    @State private var isMagnetLink = true
    @State private var magnetUrl = ""
    @State private var torrentFile: Data?
    @State private var downloadPath = "/downloads"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showFileImporter = false
    @State private var selectedFileName: String?
    @State private var showingRecentPaths = false
    
    var body: some View {
        NavigationView {
            // Applichiamo i modificatori al form estratto
            formContent
                .navigationTitle("Aggiungi Torrent")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Chiudi") {
                            dismiss()
                        }
                    }
                }
                .alert("Errore", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage ?? "Si è verificato un errore")
                }
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.torrent],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileImport(result)
                }
                .overlay {
                    if isLoading {
                        loadingView
                    }
                }
                .sheet(isPresented: $showingRecentPaths) {
                    recentPathsSheet
                }
        }
    }
    
    // 1. Estraiamo il Form in una proprietà calcolata
    private var formContent: some View {
        Form {
            Section {
                Picker("Metodo", selection: $isMagnetLink) {
                    Text("Link Magnet").tag(true)
                    Text("File Torrent").tag(false)
                }
                .pickerStyle(.segmented)
            }
            
            if isMagnetLink {
                Section(header: Text("Link Magnet")) {
                    TextField("Inserisci il link magnet", text: $magnetUrl)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } else {
                Section(header: Text("File Torrent")) {
                    if let fileName = selectedFileName {
                        HStack {
                            Text(fileName)
                            Spacer()
                            Button("Cambia") {
                                showFileImporter = true
                            }
                        }
                    } else {
                        Button("Seleziona File") {
                            showFileImporter = true
                        }
                    }
                }
            }
            
            Section(header: Text("Percorso Download")) {
                TextField("Percorso", text: $downloadPath)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if !recentPathsManager.paths.isEmpty {
                    Button(action: { showingRecentPaths = true }) {
                        Label("Percorsi Recenti", systemImage: "clock")
                    }
                }
            }
            
            Section {
                Button(action: {
                    Task {
                        await addTorrent()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Aggiungi Torrent")
                        Spacer()
                    }
                }
                .disabled(!canAddTorrent)
            }
        }
    }
    
    // 2. (Opzionale ma consigliato) Estraiamo anche altre viste complesse
    private var loadingView: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .overlay(
                ProgressView()
                    .padding()
                    .background(Color.systemBackground)
                    .cornerRadius(10)
            )
    }
    
    private var recentPathsSheet: some View {
        NavigationView {
            List(recentPathsManager.paths) { recentPath in
                Button(action: {
                    downloadPath = recentPath.path
                    showingRecentPaths = false
                }) {
                    VStack(alignment: .leading) {
                        Text(recentPath.path)
                        Text(recentPath.lastUsed.formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Percorsi Recenti")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        showingRecentPaths = false
                    }
                }
            }
        }
    }
    
    // 3. (Opzionale ma consigliato) Estraiamo la logica di gestione in un metodo
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                // Assicurati che l'URL sia accessibile
                guard url.startAccessingSecurityScopedResource() else {
                    errorMessage = "Impossibile accedere al file selezionato."
                    showError = true
                    return
                }
                torrentFile = try Data(contentsOf: url)
                selectedFileName = url.lastPathComponent
                // Rilascia la risorsa quando hai finito
                url.stopAccessingSecurityScopedResource()
            } catch {
                errorMessage = "Errore nel caricamento del file: \(error.localizedDescription)"
                showError = true
            }
        case .failure(let error):
            errorMessage = "Errore nella selezione del file: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private var canAddTorrent: Bool {
        guard qbittorrentManager.activeQBittorrentServer != nil else { return false }
        
        if isMagnetLink {
            return !magnetUrl.isEmpty
        } else {
            return torrentFile != nil
        }
    }
    
    private func addTorrent() async {
        // Sostituisci `settings.activeQBittorrentServer` con `qbittorrentManager.activeQBittorrentServer`
        guard let qbittorrentServer = qbittorrentManager.activeQBittorrentServer else {
            errorMessage = "Nessun server qBittorrent configurato"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // La logica di login è ora in un metodo separato per pulizia
        let loginSuccess = await login(to: qbittorrentServer)
        if !loginSuccess {
            errorMessage = "Login fallito"
            showError = true
            return
        }
        
        guard let url = URL(string: "\(qbittorrentServer.url)api/v2/torrents/add") else {
            errorMessage = "URL non valido"
            showError = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Aggiungi il percorso di download
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"savepath\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(downloadPath)\r\n".data(using: .utf8)!)
        
        if isMagnetLink {
            // Aggiungi il link magnet
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"urls\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(magnetUrl)\r\n".data(using: .utf8)!)
        } else if let fileData = torrentFile {
            // Aggiungi il file torrent
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"torrents\"; filename=\"torrent.torrent\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/x-bittorrent\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Sostituisci `settings.recentPaths` con `recentPathsManager`
                    recentPathsManager.addPath(downloadPath)
                    dismiss()
                } else {
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Errore nell'aggiunta del torrent (Status: \(httpResponse.statusCode))"])
                }
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Risposta non valida dal server"])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Ho estratto anche la logica di login per coerenza con gli altri ViewModel
    private func login(to server: QBittorrentServer) async -> Bool {
        guard let url = URL(string: "\(server.url)api/v2/auth/login") else {
            return false
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

// Il resto del file (UTType extension) rimane invariato.
extension UTType {
    static var torrent: UTType {
        if let type = UTType("application/x-bittorrent") {
            return type
        }
        if let type = UTType(tag: "torrent",
                            tagClass: .filenameExtension,
                            conformingTo: .data) {
            return type
        }
        return .data
    }
}