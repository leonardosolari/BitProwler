import SwiftUI

struct AddProwlarrServerView: View {
    @StateObject private var viewModel: AddServerViewModel<ProwlarrServer>
    
    @State private var apiKey: String
    
    private let serverToEdit: ProwlarrServer?
    
    init(serverToEdit: ProwlarrServer? = nil) {
        self.serverToEdit = serverToEdit
        _apiKey = State(initialValue: serverToEdit?.apiKey ?? "")
        
        _viewModel = StateObject(wrappedValue: AddServerViewModel(
            manager: AppContainer.shared.prowlarrManager,
            serverToEdit: serverToEdit,
            apiTestHandler: { server in await AppContainer.shared.prowlarrService.testConnection(to: server) }
        ))
    }
    
    private func makeServer() -> ProwlarrServer {
        ProwlarrServer(
            id: serverToEdit?.id ?? UUID(),
            name: viewModel.name,
            url: viewModel.url,
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    var body: some View {
        AddServerView(
            viewModel: viewModel,
            title: serverToEdit == nil ? "New Prowlarr Server" : "Edit Server",
            onTest: {
                await viewModel.testConnection(with: makeServer())
            },
            onSave: { completion in
                viewModel.save(with: makeServer(), completion: completion)
            }
        ) {
            SecureField("API Key", text: $apiKey)
                .accessibilityIdentifier("server_apikey_field")
        }
    }
}