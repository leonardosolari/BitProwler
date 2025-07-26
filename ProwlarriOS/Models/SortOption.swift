// File: /ProwlarriOS/Models/SortOption.swift

import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case seeders = "Seeders"
    case size = "Dimensione"
    case recent = "Più Recente"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .default:
            return "list.bullet"
        case .seeders:
            return "person.2.wave.2.fill"
        case .size:
            return "tray.full.fill"
        case .recent:
            return "calendar"
        }
    }
}