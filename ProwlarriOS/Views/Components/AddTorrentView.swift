import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: ProwlarrSettings
    
    @State private var isMagnetLink = true
    @State private var magnetUrl = ""
    @State private var torrentFile: Data?
    @State private var downloadPath = "/downloads"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showFileImporter = false
    @State private var selectedFileName: String?
    
    var body: some View {
        NavigationView {
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
                switch result {
                case .success(let urls):
                    do {
                        torrentFile = try Data(contentsOf: urls.first!)
                        selectedFileName = urls.first?.lastPathComponent
                    } catch {
                        errorMessage = "Errore nel caricamento del file: \(error.localizedDescription)"
                        showError = true
                    }
                case .failure(let error):
                    errorMessage = "Errore nella selezione del file: \(error.localizedDescription)"
                    showError = true
                }
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
    
    private var canAddTorrent: Bool {
        guard settings.activeQBittorrentServer != nil else { return false }
        
        if isMagnetLink {
            return !magnetUrl.isEmpty
        } else {
            return torrentFile != nil
        }
    }
    
    private func addTorrent() async {
        guard let qbittorrentServer = settings.activeQBittorrentServer else {
            errorMessage = "Nessun server qBittorrent configurato"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Prima effettuiamo il login
        guard let loginSuccess = await login(server: qbittorrentServer) else {
            errorMessage = "Errore di connessione al server"
            showError = true
            return
        }
        
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

extension UTType {
    static var torrent: UTType {
        // Prova prima con l'identificatore MIME
        if let type = UTType("application/x-bittorrent") {
            return type
        }
        
        // Se fallisce, prova con l'estensione
        if let type = UTType(tag: "torrent",
                            tagClass: .filenameExtension,
                            conformingTo: .data) {
            return type
        }
        
        // Se entrambi falliscono, usa un tipo generico
        return .data
    }
} 