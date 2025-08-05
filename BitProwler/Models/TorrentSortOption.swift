import Foundation
import SwiftUI

enum TorrentSortOption: String, CaseIterable, Identifiable, SortOptionable {
    case name = "Name"
    case progress = "Progress"
    case downloadSpeed = "Download Speed"
    case uploadSpeed = "Upload Speed"
    case size = "Size"
    case state = "State"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .name:
            return "textformat.abc"
        case .progress:
            return "chart.bar.fill"
        case .downloadSpeed:
            return "arrow.down"
        case .uploadSpeed:
            return "arrow.up"
        case .size:
            return "tray.full.fill"
        case .state:
            return "tag.fill"
        }
    }
    
    var localized: LocalizedStringKey {
        return LocalizedStringKey(self.rawValue)
    }
}