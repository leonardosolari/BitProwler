import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: ProwlarrSettings
    @State private var tempServerUrl: String = ""
    @State private var tempApiKey: String = ""
    @State private var tempQbittorrentUrl: String = ""
    @State private var tempQbittorrentUsername: String = ""
    @State private var tempQbittorrentPassword: String = ""
    @State private var showingSaveAlert = false
    @State private var isEdited = false
    @State private var showingQbittorrentTestResult = false
    @State private var qbittorrentTestMessage = ""
    @State private var qbittorrentTestSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prowlarr")) {
                    TextField("URL Server", text: $tempServerUrl)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.URL)
                        .onChange(of: tempServerUrl) { _ in
                            isEdited = true
                        }
                    
                    SecureField("API Key", text: $tempApiKey)
                        .onChange(of: tempApiKey) { _ in
                            isEdited = true
                        }
                }
                
                Section(header: Text("qBittorrent")) {
                    TextField("URL Server", text: $tempQbittorrentUrl)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.URL)
                        .onChange(of: tempQbittorrentUrl) { _ in
                            isEdited = true
                        }
                    Text("Formato: http://indirizzo:porta")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Username", text: $tempQbittorrentUsername)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: tempQbittorrentUsername) { _ in
                            isEdited = true
                        }
                    
                    SecureField("Password", text: $tempQbittorrentPassword)
                        .onChange(of: tempQbittorrentPassword) { _ in
                            isEdited = true
                        }
                    
                    Button("Testa Connessione qBittorrent") {
                        testQbittorrentConnection()
                    }
                    .disabled(tempQbittorrentUrl.isEmpty)
                }
                
                Section(header: Text("Info")) {
                    Text("Inserisci i dati di accesso ai tuoi server per iniziare a cercare e scaricare")
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            Text("Salva Impostazioni")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(!isEdited)
                }
            }
            .navigationTitle("Impostazioni")
            .alert("Impostazioni Salvate", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert(qbittorrentTestSuccess ? "Connessione Riuscita" : "Errore Connessione", isPresented: $showingQbittorrentTestResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(qbittorrentTestMessage)
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func loadSettings() {
        tempServerUrl = settings.serverUrl
        tempApiKey = settings.apiKey
        tempQbittorrentUrl = settings.qbittorrentUrl
        tempQbittorrentUsername = settings.qbittorrentUsername
        tempQbittorrentPassword = settings.qbittorrentPassword
        isEdited = false
    }
    
    private func saveSettings() {
        // Rimuove spazi iniziali e finali
        let cleanServerUrl = tempServerUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanApiKey = tempApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanQbittorrentUrl = tempQbittorrentUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Verifica e formatta gli URL
        var finalServerUrl = cleanServerUrl
        if !finalServerUrl.isEmpty {
            if finalServerUrl.hasSuffix("/") {
                finalServerUrl = String(finalServerUrl.dropLast())
            }
            finalServerUrl += "/"
        }
        
        var finalQbittorrentUrl = cleanQbittorrentUrl
        if !finalQbittorrentUrl.isEmpty {
            if finalQbittorrentUrl.hasSuffix("/") {
                finalQbittorrentUrl = String(finalQbittorrentUrl.dropLast())
            }
        }
        
        // Salva le impostazioni
        settings.serverUrl = finalServerUrl
        settings.apiKey = cleanApiKey
        settings.qbittorrentUrl = finalQbittorrentUrl
        settings.qbittorrentUsername = tempQbittorrentUsername
        settings.qbittorrentPassword = tempQbittorrentPassword
        
        // Mostra l'alert di conferma
        showingSaveAlert = true
        isEdited = false
    }
    
    private func testQbittorrentConnection() {
        // Prepara l'URL base
        var urlString = tempQbittorrentUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Rimuovi la barra finale se presente
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        
        // Aggiungi il percorso dell'API
        urlString += "/api/v2/auth/login"
        
        guard let url = URL(string: urlString) else {
            qbittorrentTestMessage = "URL non valido: \(urlString)"
            qbittorrentTestSuccess = false
            showingQbittorrentTestResult = true
            return
        }
        
        print("Testing URL: \(url.absoluteString)") // Debug
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(tempQbittorrentUsername)&password=\(tempQbittorrentPassword)"
        request.httpBody = credentials.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    qbittorrentTestMessage = "Errore di connessione: \(error.localizedDescription)"
                    qbittorrentTestSuccess = false
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)") // Debug
                    if httpResponse.statusCode == 200 {
                        qbittorrentTestMessage = "Connessione stabilita con successo!"
                        qbittorrentTestSuccess = true
                    } else {
                        qbittorrentTestMessage = "Errore: Status code \(httpResponse.statusCode)"
                        qbittorrentTestSuccess = false
                    }
                }
                showingQbittorrentTestResult = true
            }
        }.resume()
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProwlarrSettings())
}