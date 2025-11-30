import SwiftUI

struct AddServerView<T: Server, Content: View>: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AddServerViewModel<T>
    
    let title: LocalizedStringKey
    let onTest: () async -> Void
    let onSave: (@escaping () -> Void) -> Void
    @ViewBuilder var specificFields: () -> Content
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Informations")) {
                    TextField("Name", text: $viewModel.name)
                        .accessibilityIdentifier("server_name_field")
                    
                    TextField("Server URL", text: $viewModel.url)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("server_url_field")
                    
                    specificFields()
                }
                
                Section {
                    Button(action: { Task { await onTest() } }) {
                        HStack {
                            Spacer()
                            if viewModel.isTesting { ProgressView() } else { Text("Test Connection") }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isTesting)
                    .accessibilityIdentifier("server_test_button")
                    
                    Button("Save", action: { onSave { dismiss() } })
                        .disabled(!viewModel.canSave)
                        .accessibilityIdentifier("server_save_button")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(isPresented: $viewModel.isShowingTestResult) {
                switch viewModel.testResult {
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
}