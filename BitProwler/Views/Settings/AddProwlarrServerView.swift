import SwiftUI

struct AddProwlarrServerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var prowlarrManager: GenericServerManager<ProwlarrServer>
    @EnvironmentObject var container: AppContainer
    
    var serverToEdit: ProwlarrServer?
    private var isEditing: Bool { serverToEdit != nil }
    
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var isTesting = false
    
    @State private var testResult: Result<String, AppError>?
    @State private var isShowingTestResult = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Informations")) {
                    TextField("Name", text: $name)
                    TextField("Server URL", text: $url)
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
                            if isTesting { ProgressView() } else { Text("Test Connection") }
                            Spacer()
                        }
                    }
                    .disabled(!canTest || isTesting)
                    
                    Button("Save", action: saveServer)
                        .disabled(!canSave)
                }
            }
            .navigationTitle(isEditing ? "Edit Server" : "New Prowlarr Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: setupForEditing)
            .alert(isPresented: $isShowingTestResult) {
                switch testResult {
                case .success(let message):
                    return Alert(title: Text("Success"), message: Text(message), dismissButton: .default(Text("OK")))
                case .failure(let error):
                    return Alert(title: Text("Error"), message: Text(error.errorDescription ?? "Unknown Error"), dismissButton: .default(Text("OK")))
                case .none:
                    return Alert(title: Text("Unknown Error"))
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
            let success = await container.prowlarrService.testConnection(to: serverToTest)
            if success {
                testResult = .success("Connessione al server Prowlarr riuscita!")
            } else {
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
            prowlarrManager.updateServer(updatedServer)
        } else {
            let newServer = ProwlarrServer(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url.asSanitizedURL(),
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            prowlarrManager.addServer(newServer)
        }
        dismiss()
    }
}
