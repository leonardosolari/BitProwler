import SwiftUI

struct AddProwlarrServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: ProwlarrSettings
    
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
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
                    SecureField("API Key", text: $apiKey)
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
            .navigationTitle("Nuovo Server Prowlarr")
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
        !url.isEmpty && !apiKey.isEmpty
    }
    
    private var canSave: Bool {
        !name.isEmpty && !url.isEmpty && !apiKey.isEmpty
    }
    
    private func testConnection() {
        var finalUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalUrl.hasSuffix("/") {
            finalUrl += "/"
        }
        
        guard let testUrl = URL(string: "\(finalUrl)api/v1/system/status") else {
            testMessage = "URL non valido"
            testSuccess = false
            showingTestResult = true
            return
        }
        
        var request = URLRequest(url: testUrl)
        request.setValue(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "X-Api-Key")
        
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
                    case 401:
                        testMessage = "API Key non valida"
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
        
        let server = ProwlarrServer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            url: finalUrl,
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        settings.addProwlarrServer(server)
        dismiss()
    }
} 