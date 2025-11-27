import Testing
import Foundation
@testable import BitProwler

struct RecentPathsManagerTests {
    
    @Test func addPathLogic() {
        let suiteName = "RecentPathsTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        
        let manager = RecentPathsManager(userDefaults: defaults)
        
        manager.addPath("/downloads/movie")
        #expect(manager.paths.count == 1)
        
        manager.addPath("/downloads/movie")
        #expect(manager.paths.count == 1)
        
        for i in 0..<20 {
            manager.addPath("/downloads/path\(i)")
        }
        
        #expect(manager.paths.count == 15)
        #expect(manager.paths.first?.path == "/downloads/path19")
        
        defaults.removePersistentDomain(forName: suiteName)
    }
}