import Foundation

final class SearchHistoryManager: ObservableObject {
    @Published private(set) var searches: [String] = []
    
    private let historyKey = "searchHistory"
    private let maxHistoryCount = 15
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadSearches()
    }
    
    private func loadSearches() {
        self.searches = userDefaults.stringArray(forKey: historyKey) ?? []
    }
    
    private func saveSearches() {
        userDefaults.set(searches, forKey: historyKey)
    }
    
    func addSearch(_ term: String) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return }
        
        searches.removeAll { $0.caseInsensitiveCompare(trimmedTerm) == .orderedSame }
        
        searches.insert(trimmedTerm, at: 0)
        
        if searches.count > maxHistoryCount {
            searches = Array(searches.prefix(maxHistoryCount))
        }
        
        saveSearches()
    }
    
    func clearHistory() {
        searches.removeAll()
        saveSearches()
    }
}