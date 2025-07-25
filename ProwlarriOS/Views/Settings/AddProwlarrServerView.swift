import SwiftUI

// Definiamo un tipo di errore semplice per il risultato del test
struct TestConnectionError: Error, LocalizedError {
    var errorDescription: String?
}

struct AddProwlarrServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var isTesting = false
    
    // Usiamo la nostra nuova struct di errore
    @State private var testResult: Result<String, TestConnectionError>?
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
            .navigationTitle("Nuovo Server Prowlarr")
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
    
    private var canTest: Bool { !url.isEmpty && !apiKey.isEmpty }
    private var canSave: Bool { !name.isEmpty && canTest }
    
    private func testConnection() {
        isTesting = true
        let serverToTest = ProwlarrServer(name: "Test", url: formattedUrl, apiKey: apiKey)
        
        Task {
            let success = await apiService.testConnection(to: serverToTest)
            if success {
                testResult = .success("Connessione al server Prowlarr riuscita!")
            } else {
                // Creiamo un'istanza del nostro errore personalizzato
                testResult = .failure(TestConnectionError(errorDescription: "Impossibile connettersi al server. Controlla l'URL e la chiave API."))
            }
            isShowingTestResult = true
            isTesting = false
        }
    }
    
    private func saveServer() {
        let server = ProwlarrServer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            url: formattedUrl,
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        prowlarrManager.addProwlarrServer(server)
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