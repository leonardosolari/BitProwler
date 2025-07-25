import SwiftUI

struct AddQBittorrentServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager

    
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showingTestResult = false
    @State private var testMessage = ""
    @State private var testSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informazioni Server")) {
                    TextField("Nome", text: $name)
                    TextField("URL Server", text: $url)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                }
                
                Section {
                    Button("Testa Connessione") {
                        testConnection()
                    }
                    .disabled(!canTest)
                    
                    Button("Salva") {
                        saveServer()
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Nuovo Server qBittorrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
            .alert(testSuccess ? "Successo" : "Errore", isPresented: $showingTestResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(testMessage)
            }
        }
    }
    
    private var canTest: Bool {
        !url.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    private var canSave: Bool {
        !name.isEmpty && !url.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    private func testConnection() {
        var finalUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalUrl.hasSuffix("/") {
            finalUrl += "/"
        }
        
        guard let testUrl = URL(string: "\(finalUrl)api/v2/auth/login") else {
            testMessage = "URL non valido"
            testSuccess = false
            showingTestResult = true
            return
        }
        
        var request = URLRequest(url: testUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(username.trimmingCharacters(in: .whitespacesAndNewlines))&password=\(password)"
        request.httpBody = credentials.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testMessage = "Errore di connessione: \(error.localizedDescription)"
                    testSuccess = false
                } else if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        testMessage = "Connessione stabilita con successo!"
                        testSuccess = true
                    case 403:
                        testMessage = "Credenziali non valide"
                        testSuccess = false
                    case 404:
                        testMessage = "Server non trovato"
                        testSuccess = false
                    default:
                        testMessage = "Errore: Status code \(httpResponse.statusCode)"
                        testSuccess = false
                    }
                }
                showingTestResult = true
            }
        }.resume()
    }
    
    private func saveServer() {
        var finalUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalUrl.hasSuffix("/") {
            finalUrl += "/"
        }
        
        let server = QBittorrentServer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            url: finalUrl,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        
        qbittorrentManager.addQBittorrentServer(server)
        dismiss()
    }
} 