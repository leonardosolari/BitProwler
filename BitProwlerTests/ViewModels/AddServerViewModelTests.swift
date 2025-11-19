import Testing
import Foundation
@testable import BitProwler

@MainActor
struct AddServerViewModelTests {
    
    var mockManager: GenericServerManager<ProwlarrServer>
    var viewModel: AddServerViewModel<ProwlarrServer>
    
    init() {
        let testDefaults = UserDefaults(suiteName: "AddServerViewModelTests")!
        testDefaults.removePersistentDomain(forName: "AddServerViewModelTests")
        
        let mockKeychain = MockKeychain()
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        viewModel = AddServerViewModel(
            manager: mockManager,
            serverToEdit: nil,
            apiTestHandler: { _ in return true }
        )
    }
    
    @Test func validationLogic() {
        #expect(viewModel.canSave == false)
        
        viewModel.name = "My Server"
        #expect(viewModel.canSave == false)
        
        viewModel.url = "http://local"
        #expect(viewModel.canSave == true)
        
        viewModel.name = ""
        #expect(viewModel.canSave == false)
    }
    
    @Test func testConnectionSuccess() async {
        let server = ProwlarrServer(name: "T", url: "U", apiKey: "K")
        
        await viewModel.testConnection(with: server)
        
        #expect(viewModel.isTesting == false)
        #expect(viewModel.isShowingTestResult == true)
        
        if case .success = viewModel.testResult {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected success")
        }
    }
    
    @Test func saveNewServer() {
        let server = ProwlarrServer(name: "New", url: "http://new", apiKey: "key")
        
        viewModel.save(with: server) { }
        
        #expect(mockManager.servers.count == 1)
        #expect(mockManager.servers.first?.name == "New")
    }
    
    @Test func editExistingServer() {
        let existing = ProwlarrServer(name: "Old", url: "http://old", apiKey: "oldKey")
        mockManager.addServer(existing)
        
        let editVM = AddServerViewModel(
            manager: mockManager,
            serverToEdit: existing,
            apiTestHandler: { _ in return true }
        )
        
        #expect(editVM.name == "Old")
        #expect(editVM.url == "http://old")
        
        let updated = ProwlarrServer(id: existing.id, name: "Updated", url: "http://old", apiKey: "oldKey")
        editVM.save(with: updated) { }
        
        #expect(mockManager.servers.first?.name == "Updated")
        #expect(mockManager.servers.count == 1)
    }
}