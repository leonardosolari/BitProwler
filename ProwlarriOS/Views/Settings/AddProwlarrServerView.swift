import SwiftUI

struct AddProwlarrServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var prowlarrManager: ProwlarrServerManager
    
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var isTesting = false
    
    private let apiService: ProwlarrAPIService = NetworkManager()
    
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
                    SecureField("API Key", text: $apiKey)
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
            .navigationTitle("Nuovo Server Prowlarr")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
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
            // Qui dovresti mostrare un alert o un feedback
            print("Test connessione Prowlarr: \(success ? "Successo" : "Fallito")")
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