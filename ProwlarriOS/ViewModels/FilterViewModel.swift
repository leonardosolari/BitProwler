import Foundation

class FilterViewModel: ObservableObject {
    @Published var filters: [TorrentFilter] {
        didSet {
            saveFilters()
        }
    }
    
    @Published var filterUpdateTrigger = false
    
    enum FilterLogic {
        case and  // Deve corrispondere a tutti i filtri
        case or   // Deve corrispondere ad almeno un filtro
    }
    
    @Published var filterLogic: FilterLogic {
        didSet {
            UserDefaults.standard.set(filterLogic == .and ? "and" : "or", forKey: "filterLogic")
        }
    }
    
    init() {
        // Carica la logica salvata
        if let savedLogic = UserDefaults.standard.string(forKey: "filterLogic") {
            self.filterLogic = savedLogic == "and" ? .and : .or
        } else {
            self.filterLogic = .and
        }
        
        if let data = UserDefaults.standard.data(forKey: "torrentFilters"),
           let decodedFilters = try? JSONDecoder().decode([TorrentFilter].self, from: data) {
            self.filters = decodedFilters
        } else {
            self.filters = []
        }
    }
    
    private func saveFilters() {
        if let encoded = try? JSONEncoder().encode(filters) {
            UserDefaults.standard.set(encoded, forKey: "torrentFilters")
        }
    }
    
    func addFilter(_ filter: TorrentFilter) {
        filters.append(filter)
        triggerUpdate()
    }
    
    func deleteFilter(_ filter: TorrentFilter) {
        filters.removeAll { $0.id == filter.id }
        triggerUpdate()
    }
    
    func toggleFilter(_ filter: TorrentFilter) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            var updatedFilter = filters[index]
            updatedFilter.isEnabled.toggle()
            filters[index] = updatedFilter
            triggerUpdate()
        }
    }
    
    private func triggerUpdate() {
        filterUpdateTrigger.toggle()
    }
    
    func filterResults(_ results: [TorrentResult]) -> [TorrentResult] {
        let activeFilters = filters.filter { $0.isEnabled }
        if activeFilters.isEmpty {
            return results
        }
        
        return results.filter { result in
            let title = result.title.lowercased()
            
            switch filterLogic {
            case .and:
                // Deve corrispondere a TUTTI i filtri attivi
                return activeFilters.allSatisfy { filter in
                    title.contains(filter.keyword.lowercased())
                }
            case .or:
                // Deve corrispondere ad ALMENO UN filtro attivo
                return activeFilters.contains { filter in
                    title.contains(filter.keyword.lowercased())
                }
            }
        }
    }
} 