// File: /ProwlarriOS/Views/Settings/AddProwlarrServerView.swift

import SwiftUI

struct AddProwlarrServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    
    var serverToEdit: ProwlarrServer?
    private var isEditing: Bool { serverToEdit != nil }
    
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var isTesting = false
    
    // Ora usiamo AppError, il nostro tipo di errore globale
    @State private var testResult: Result<String, AppError>?
    @State private var isShowingTestResult = false
    
    private let apiService: ProwlarrAPIService = NetworkManager()
    
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
                    SecureField("API Key", text: $apiKey)
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
            .navigationTitle(isEditing ? "Modifica Server" : "Nuovo Server Prowlarr")
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
    
    private var canTest: Bool { !url.isEmpty && !apiKey.isEmpty }
    private var canSave: Bool { !name.isEmpty && canTest }
    
    private func setupForEditing() {
        if let server = serverToEdit {
            name = server.name
            url = server.url
            apiKey = server.apiKey
        }
    }
    
    private func testConnection() {
        isTesting = true
        let serverToTest = ProwlarrServer(name: "Test", url: url.asSanitizedURL(), apiKey: apiKey)
        
        Task {
            let success = await apiService.testConnection(to: serverToTest)
            if success {
                testResult = .success("Connessione al server Prowlarr riuscita!")
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
            updatedServer.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            prowlarrManager.updateProwlarrServer(updatedServer)
        } else {
            let newServer = ProwlarrServer(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url.asSanitizedURL(),
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            prowlarrManager.addProwlarrServer(newServer)
        }
        dismiss()
    }
}