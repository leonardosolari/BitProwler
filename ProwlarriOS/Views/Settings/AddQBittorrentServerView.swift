// File: /ProwlarriOS/Views/Settings/AddQBittorrentServerView.swift

import SwiftUI

struct AddQBittorrentServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isTesting = false
    
    // Usiamo la struct di errore che conforma a Error
    @State private var testResult: Result<String, TestConnectionError>?
    @State private var isShowingTestResult = false
    
    private let apiService: QBittorrentAPIService = NetworkManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informazioni Server")) {
                    TextField("Nome", text: $name)
                    TextField("URL Server", text: $url)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                }
                
                Section {
                    Button(action: testConnection) {
                        HStack {
                            Spacer()
                            if isTesting {
                                ProgressView()
                            } else {
                                Text("Testa Connessione")
                            }
                            Spacer()
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
            .alert(isPresented: $isShowingTestResult) {
                switch testResult {
                case .success(let message):
                    return Alert(title: Text("Successo"), message: Text(message), dismissButton: .default(Text("OK")))
                case .failure(let error):
                    return Alert(title: Text("Errore"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
                case .none:
                    return Alert(title: Text("Errore Sconosciuto"))
                }
            }
        }
    }
    
    private var canTest: Bool { !url.isEmpty && !username.isEmpty && !password.isEmpty }
    private var canSave: Bool { !name.isEmpty && canTest }
    
    private func testConnection() {
        isTesting = true
        // Usiamo la nuova estensione qui
        let serverToTest = QBittorrentServer(name: "Test", url: url.asSanitizedURL(), username: username, password: password)
        
        Task {
            let success = await apiService.testConnection(to: serverToTest)
            if success {
                testResult = .success("Connessione al server qBittorrent riuscita!")
            } else {
                testResult = .failure(TestConnectionError(errorDescription: "Impossibile connettersi al server. Controlla URL e credenziali."))
            }
            isShowingTestResult = true
            isTesting = false
        }
    }
    
    private func saveServer() {
        let server = QBittorrentServer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            // E la usiamo anche qui
            url: url.asSanitizedURL(),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        qbittorrentManager.addQBittorrentServer(server)
        dismiss()
    }
    
}