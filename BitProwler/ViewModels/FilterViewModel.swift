import Foundation

final class FilterViewModel: ObservableObject {
    @Published var filters: [TorrentFilter] {
        didSet {
            saveFilters()
        }
    }
    
    enum FilterLogic: String, Codable {
        case and
        case or
    }
    
    @Published var filterLogic: FilterLogic {
        didSet {
            UserDefaults.standard.set(filterLogic.rawValue, forKey: "filterLogic")
        }
    }
    
    init() {
        if let savedLogicRaw = UserDefaults.standard.string(forKey: "filterLogic"),
           let savedLogic = FilterLogic(rawValue: savedLogicRaw) {
            self.filterLogic = savedLogic
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
    }
    
    func deleteFilter(at offsets: IndexSet) {
        filters.remove(atOffsets: offsets)
    }
    
    func toggleFilter(_ filter: TorrentFilter) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index].isEnabled.toggle()
        }
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
                return activeFilters.allSatisfy { filter in
                    title.contains(filter.keyword.lowercased())
                }
            case .or:
                return activeFilters.contains { filter in
                    title.contains(filter.keyword.lowercased())
                }
            }
        }
    }
}