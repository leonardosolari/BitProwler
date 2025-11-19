import Testing
import Foundation
@testable import BitProwler

@MainActor
struct SearchViewModelTests {
    
    var mockService: MockProwlarrService
    var mockManager: GenericServerManager<ProwlarrServer>
    var historyManager: SearchHistoryManager
    var viewModel: SearchViewModel
    
    init() {
        mockService = MockProwlarrService()
        
        let testDefaults = UserDefaults(suiteName: "SearchViewModelTests")!
        testDefaults.removePersistentDomain(forName: "SearchViewModelTests")
        
        let mockKeychain = MockKeychain()
        
        mockManager = GenericServerManager(
            keychainService: mockKeychain,
            userDefaults: testDefaults
        )
        
        historyManager = SearchHistoryManager(userDefaults: testDefaults)
        
        viewModel = SearchViewModel(
            apiService: mockService,
            prowlarrManager: mockManager,
            searchHistoryManager: historyManager
        )
        
        let server = ProwlarrServer(name: "Test", url: "http://test", apiKey: "123")
        mockManager.addServer(server)
    }
    
    @Test func searchSuccess() async {
        let mockResult = TorrentResult(
            id: "guid",
            title: "Ubuntu",
            size: 100,
            seeders: 10,
            leechers: 0,
            downloadUrl: nil,
            magnetUrl: nil,
            infoUrl: nil,
            indexer: "Test",
            publishDate: "2025-01-01"
        )
        mockService.searchResultToReturn = [mockResult]
        
        await viewModel.search(query: "Ubuntu")
        
        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.searchResults.first?.title == "Ubuntu")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showError == false)
        #expect(historyManager.searches.contains("Ubuntu"))
    }
    
    @Test func searchFailure() async {
        mockService.errorToThrow = AppError.httpError(statusCode: 401)
        
        await viewModel.search(query: "ErrorQuery")
        
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test func emptyQueryDoesNotTriggerSearch() async {
        await viewModel.search(query: "   ")
        #expect(viewModel.hasSearched == false)
    }
}