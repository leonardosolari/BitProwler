import Testing
import Foundation
@testable import BitProwler

struct FormattersTests {

    @Test func formatSize() {
        #expect(Formatters.formatSize(1000) == "1 KB")
        #expect(Formatters.formatSize(1024 * 1024) == "1 MB")
        #expect(Formatters.formatSize(0) == "Zero KB" || Formatters.formatSize(0) == "0 bytes" || Formatters.formatSize(0) == "0 byte") 
    }
    
    @Test func formatSpeed() {
        #expect(Formatters.formatSpeed(1024 * 1024) == "1 MB/s")
    }
    
    @Test func formatETA() {
        #expect(Formatters.formatETA(8640000) == "∞")
        
        #expect(Formatters.formatETA(0) == "")
        
        let eta = Formatters.formatETA(3660)
        #expect(eta.contains("1")) 
    }
}