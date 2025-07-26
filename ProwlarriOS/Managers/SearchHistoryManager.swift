// File: /ProwlarriOS/Managers/SearchHistoryManager.swift

import Foundation

class SearchHistoryManager: ObservableObject {
    @Published private(set) var searches: [String] = []
    
    private let historyKey = "searchHistory"
    private let maxHistoryCount = 15
    
    init() {
        loadSearches()
    }
    
    private func loadSearches() {
        self.searches = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }
    
    private func saveSearches() {
        UserDefaults.standard.set(searches, forKey: historyKey)
    }
    
    /// Aggiunge un termine di ricerca alla cronologia.
    /// Previene i duplicati e mantiene la lista ordinata per recenza.
    func addSearch(_ term: String) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return }
        
        // Rimuovi eventuali occorrenze precedenti per evitare duplicati
        searches.removeAll { $0.caseInsensitiveCompare(trimmedTerm) == .orderedSame }
        
        // Aggiungi il nuovo termine in cima alla lista
        searches.insert(trimmedTerm, at: 0)
        
        // Mantieni la cronologia entro il limite massimo
        if searches.count > maxHistoryCount {
            searches = Array(searches.prefix(maxHistoryCount))
        }
        
        saveSearches()
    }
    
    /// Cancella l'intera cronologia delle ricerche.
    func clearHistory() {
        searches.removeAll()
        saveSearches()
    }
}