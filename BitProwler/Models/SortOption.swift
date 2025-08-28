import Foundation
import SwiftUI

enum SortOption: String, CaseIterable, Identifiable, SortOptionable, Codable {
    case `default` = "Default"
    case seeders = "Seeders"
    case size = "Size"
    case recent = "Most Recent"
    
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
    
    var localizedLabel: Text {
        switch self {
        case .default:
            return Text("Default")
        case .seeders:
            return Text("Seeders")
        case .size:
            return Text("Size")
        case .recent:
            return Text("Most Recent")
        }
    }
}