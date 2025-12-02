import Testing
import Foundation
@testable import BitProwler

@MainActor
struct SearchHistoryManagerTests {
    
    private func createCleanManager() -> (SearchHistoryManager, UserDefaults) {
        let suiteName = "SearchHistoryManagerTests"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        let manager = SearchHistoryManager(userDefaults: userDefaults)
        return (manager, userDefaults)
    }
    
    @Test func addSearchTerm() {
        let (manager, _) = createCleanManager()
        
        manager.addSearch("Ubuntu")
        #expect(manager.searches.count == 1)
        #expect(manager.searches.first == "Ubuntu")
        
        manager.addSearch("Debian")
        #expect(manager.searches.count == 2)
        #expect(manager.searches.first == "Debian", "Il nuovo termine deve essere in cima alla lista")
        #expect(manager.searches[1] == "Ubuntu")
    }
    
    @Test func addDuplicateSearchTermIsMovedToTop() {
        let (manager, _) = createCleanManager()
        
        manager.addSearch("Ubuntu")
        manager.addSearch("Debian")
        manager.addSearch("Fedora")
        
        #expect(manager.searches == ["Fedora", "Debian", "Ubuntu"])
        
        manager.addSearch("Debian")
        
        #expect(manager.searches.count == 3, "Non devono essere creati duplicati")
        #expect(manager.searches == ["Debian", "Fedora", "Ubuntu"], "Il termine duplicato deve essere spostato in cima")
    }
    
    @Test func addDuplicateSearchTermIsCaseInsensitive() {
        let (manager, _) = createCleanManager()
        
        manager.addSearch("Ubuntu")
        manager.addSearch("Debian")
        
        manager.addSearch("ubuntu")
        
        #expect(manager.searches.count == 2)
        #expect(manager.searches.first == "ubuntu", "Il termine con il nuovo case dovrebbe essere in cima")
    }
    
    @Test func historyLimitIsRespected() {
        let (manager, _) = createCleanManager()
        let maxHistoryCount = 15
        
        for i in 1...20 {
            manager.addSearch("Term \(i)")
        }
        
        #expect(manager.searches.count == maxHistoryCount, "La cronologia non deve superare il limite massimo")
        #expect(manager.searches.first == "Term 20", "L'ultimo termine aggiunto deve essere il primo")
        #expect(manager.searches.last == "Term 6", "Il termine più vecchio (oltre il limite) deve essere stato rimosso")
    }
    
    @Test func clearHistory() {
        let (manager, _) = createCleanManager()
        
        manager.addSearch("Term 1")
        manager.addSearch("Term 2")
        #expect(!manager.searches.isEmpty)
        
        manager.clearHistory()
        #expect(manager.searches.isEmpty)
    }
    
    @Test func emptyAndWhitespaceTermsAreIgnored() {
        let (manager, _) = createCleanManager()
        
        manager.addSearch("  ")
        #expect(manager.searches.isEmpty, "I termini composti da soli spazi devono essere ignorati")
        
        manager.addSearch("")
        #expect(manager.searches.isEmpty, "I termini vuoti devono essere ignorati")
    }
    
    @Test func persistenceOnLoad() {
        let (initialManager, userDefaults) = createCleanManager()
        
        initialManager.addSearch("Persisted Term")
        
        let newManager = SearchHistoryManager(userDefaults: userDefaults)
        
        #expect(newManager.searches.count == 1)
        #expect(newManager.searches.first == "Persisted Term")
    }
}