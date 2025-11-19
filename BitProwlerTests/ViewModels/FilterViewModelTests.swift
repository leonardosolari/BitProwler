import Testing
import Foundation
@testable import BitProwler

struct FilterViewModelTests {
    
    var viewModel: FilterViewModel
    var sampleResults: [TorrentResult]
    
    init() {
        let testDefaults = UserDefaults(suiteName: "FilterViewModelTests")!
        testDefaults.removePersistentDomain(forName: "FilterViewModelTests")
        
        viewModel = FilterViewModel(userDefaults: testDefaults)
        
        sampleResults = [
            TorrentResult(id: "1", title: "Ubuntu 24.04 Desktop", size: 0, seeders: 0, leechers: 0, downloadUrl: nil, magnetUrl: nil, infoUrl: nil, indexer: "", publishDate: ""),
            TorrentResult(id: "2", title: "Ubuntu Server", size: 0, seeders: 0, leechers: 0, downloadUrl: nil, magnetUrl: nil, infoUrl: nil, indexer: "", publishDate: ""),
            TorrentResult(id: "3", title: "Debian NetInst", size: 0, seeders: 0, leechers: 0, downloadUrl: nil, magnetUrl: nil, infoUrl: nil, indexer: "", publishDate: "")
        ]
    }
    
    @Test func addAndToggleFilter() {
        let filter = TorrentFilter(name: "Ubuntu", keyword: "ubuntu")
        viewModel.addFilter(filter)
        
        #expect(viewModel.filters.count == 1)
        #expect(viewModel.filters.first?.isEnabled == true)
        
        viewModel.toggleFilter(filter)
        #expect(viewModel.filters.first?.isEnabled == false)
    }
    
    @Test func filterLogicAND() {
        viewModel.filterLogic = .and
        viewModel.addFilter(TorrentFilter(name: "Ubuntu", keyword: "Ubuntu"))
        viewModel.addFilter(TorrentFilter(name: "Desktop", keyword: "Desktop"))
        
        let filtered = viewModel.filterResults(sampleResults)
        
        #expect(filtered.count == 1)
        #expect(filtered.first?.title == "Ubuntu 24.04 Desktop")
    }
    
    @Test func filterLogicOR() {
        viewModel.filterLogic = .or
        viewModel.addFilter(TorrentFilter(name: "Server", keyword: "Server"))
        viewModel.addFilter(TorrentFilter(name: "Debian", keyword: "Debian"))
        
        let filtered = viewModel.filterResults(sampleResults)
        
        #expect(filtered.count == 2)
    }
}