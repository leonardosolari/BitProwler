import SwiftUI

struct AddQBittorrentServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isTesting = false
    
    private let apiService: QBittorrentAPIService = NetworkManager()
    
    var body: some View {
        NavigationView {
            Form {
                // ... il tuo Form rimane identico ...
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
                    Button(action: testConnection) {
                        if isTesting {
                            ProgressView()
                        } else {
                            Text("Testa Connessione")
                        }
                    }
                    .disabled(!canTest || isTesting)
                    
                    Button("Salva", action: saveServer)
                        .disabled(!canSave)
                }
            }
            .navigationTitle("Nuovo Server qBittorrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
    
    private var canTest: Bool { !url.isEmpty && !username.isEmpty && !password.isEmpty }
    private var canSave: Bool { !name.isEmpty && canTest }
    
    private func testConnection() {
        isTesting = true
        let serverToTest = QBittorrentServer(name: "Test", url: formattedUrl, username: username, password: password)
        
        Task {
            let success = await apiService.testConnection(to: serverToTest)
            // Qui dovresti mostrare un alert o un feedback
            print("Test connessione qBittorrent: \(success ? "Successo" : "Fallito")")
            isTesting = false
        }
    }
    
    private func saveServer() {
        let server = QBittorrentServer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            url: formattedUrl,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        qbittorrentManager.addQBittorrentServer(server)
        dismiss()
    }
    
    private var formattedUrl: String {
        var finalUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalUrl.hasSuffix("/") {
            finalUrl += "/"
        }
        return finalUrl
    }
}