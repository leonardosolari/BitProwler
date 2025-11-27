import Testing
import SwiftUI
@testable import BitProwler

struct SortOptionTests {
    
    @Test func sortOptionProperties() {
        for option in SortOption.allCases {
            #expect(!option.id.isEmpty)
            #expect(!option.systemImage.isEmpty)
            _ = option.localizedLabel
        }
    }
    
    @Test func torrentSortOptionProperties() {
        for option in TorrentSortOption.allCases {
            #expect(!option.id.isEmpty)
            #expect(!option.apiKey.isEmpty)
            #expect(!option.systemImage.isEmpty)
            _ = option.localizedLabel
        }
    }
    
    @Test func sortDirectionToggle() {
        var direction = SortDirection.ascending
        #expect(direction.systemImage == "chevron.up")
        
        direction.toggle()
        #expect(direction == .descending)
        #expect(direction.systemImage == "chevron.down")
        
        direction.toggle()
        #expect(direction == .ascending)
    }
}