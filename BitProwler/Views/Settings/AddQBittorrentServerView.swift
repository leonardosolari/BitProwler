// File: /ProwlarriOS/Views/Settings/AddQBittorrentServerView.swift

import SwiftUI

struct AddQBittorrentServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var qbittorrentManager: QBittorrentServerManager
    
    var serverToEdit: QBittorrentServer?
    private var isEditing: Bool { serverToEdit != nil }
    
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isTesting = false
    
    // Ora usiamo AppError, il nostro tipo di errore globale
    @State private var testResult: Result<String, AppError>?
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
                            if isTesting { ProgressView() } else { Text("Testa Connessione") }
                            Spacer()
                        }
                    }
                    .disabled(!canTest || isTesting)
                    
                    Button("Salva", action: saveServer)
                        .disabled(!canSave)
                }
            }
            .navigationTitle(isEditing ? "Modifica Server" : "Nuovo Server qBittorrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
            .onAppear(perform: setupForEditing)
            .alert(isPresented: $isShowingTestResult) {
                switch testResult {
                case .success(let message):
                    return Alert(title: Text("Successo"), message: Text(message), dismissButton: .default(Text("OK")))
                case .failure(let error):
                    // Usiamo la errorDescription di AppError
                    return Alert(title: Text("Errore"), message: Text(error.errorDescription ?? "Errore sconosciuto"), dismissButton: .default(Text("OK")))
                case .none:
                    return Alert(title: Text("Errore Sconosciuto"))
                }
            }
        }
    }
    
    private var canTest: Bool { !url.isEmpty && !username.isEmpty && !password.isEmpty }
    private var canSave: Bool { !name.isEmpty && canTest }
    
    private func setupForEditing() {
        if let server = serverToEdit {
            name = server.name
            url = server.url
            username = server.username
            password = server.password
        }
    }
    
    private func testConnection() {
        isTesting = true
        let serverToTest = QBittorrentServer(name: "Test", url: url.asSanitizedURL(), username: username, password: password)
        
        Task {
            let success = await apiService.testConnection(to: serverToTest)
            if success {
                testResult = .success("Connessione al server qBittorrent riuscita!")
            } else {
                // In caso di fallimento, usiamo un errore specifico da AppError
                testResult = .failure(.authenticationFailed)
            }
            isShowingTestResult = true
            isTesting = false
        }
    }
    
    private func saveServer() {
        if let serverToEdit = serverToEdit {
            var updatedServer = serverToEdit
            updatedServer.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedServer.url = url.asSanitizedURL()
            updatedServer.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedServer.password = password
            qbittorrentManager.updateQBittorrentServer(updatedServer)
        } else {
            let newServer = QBittorrentServer(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url.asSanitizedURL(),
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            qbittorrentManager.addQBittorrentServer(newServer)
        }
        dismiss()
    }
}