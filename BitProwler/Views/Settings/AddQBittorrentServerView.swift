import SwiftUI

struct AddQBittorrentServerView: View {
    @StateObject private var viewModel: AddServerViewModel<QBittorrentServer>
    
    @State private var username: String
    @State private var password: String
    
    private let serverToEdit: QBittorrentServer?
    
    init(serverToEdit: QBittorrentServer? = nil) {
        self.serverToEdit = serverToEdit
        _username = State(initialValue: serverToEdit?.username ?? "")
        _password = State(initialValue: serverToEdit?.password ?? "")
        
        _viewModel = StateObject(wrappedValue: AddServerViewModel(
            manager: AppContainer.shared.qbittorrentManager,
            serverToEdit: serverToEdit,
            apiTestHandler: { server in await AppContainer.shared.qbittorrentService.testConnection(to: server) }
        ))
    }
    
    private func makeServer() -> QBittorrentServer {
        QBittorrentServer(
            id: serverToEdit?.id ?? UUID(),
            name: viewModel.name,
            url: viewModel.url,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }
    
    var body: some View {
        AddServerView(
            viewModel: viewModel,
            title: serverToEdit == nil ? "New qBittorrent Server" : "Edit Server",
            onTest: {
                await viewModel.testConnection(with: makeServer())
            },
            onSave: { completion in
                viewModel.save(with: makeServer(), completion: completion)
            }
        ) {
            TextField("Username", text: $username)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .accessibilityIdentifier("server_username_field")
            SecureField("Password", text: $password)
                .accessibilityIdentifier("server_password_field")
        }
    }
}