import Foundation
import SwiftUI

@MainActor
class AddServerViewModel<T: Server>: ObservableObject {
    @Published var name: String = ""
    @Published var url: String = ""
    @Published var isTesting: Bool = false
    @Published var testResult: Result<String, AppError>?
    @Published var isShowingTestResult: Bool = false
    
    private var serverToEdit: T?
    private let manager: GenericServerManager<T>
    private let apiTestHandler: (T) async -> Bool
    
    var canSave: Bool {
        !name.isEmpty && !url.isEmpty
    }
    
    init(
        manager: GenericServerManager<T>,
        serverToEdit: T? = nil,
        apiTestHandler: @escaping (T) async -> Bool
    ) {
        self.manager = manager
        self.serverToEdit = serverToEdit
        self.apiTestHandler = apiTestHandler
        
        if let server = serverToEdit {
            self.name = server.name
            self.url = server.url
        }
    }
    
    func testConnection(with specificServer: T) async {
        isTesting = true
        
        let success = await apiTestHandler(specificServer)
        if success {
            testResult = .success("Connection successful!")
        } else {
            testResult = .failure(.authenticationFailed)
        }
        isShowingTestResult = true
        isTesting = false
    }
    
    func save(with specificServer: T, completion: @escaping () -> Void) {
        if serverToEdit != nil {
            manager.updateServer(specificServer)
        } else {
            manager.addServer(specificServer)
        }
        completion()
    }
}