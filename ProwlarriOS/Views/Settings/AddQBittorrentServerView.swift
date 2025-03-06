import SwiftUI

struct AddQBittorrentServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: ProwlarrSettings
    
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
        // Implementa il test della connessione
        // Simile a quello che già hai nel codice esistente
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
        
        settings.addQBittorrentServer(server)
        dismiss()
    }
} 