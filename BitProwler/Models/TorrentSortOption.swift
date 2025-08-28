import Foundation
import SwiftUI

enum TorrentSortOption: String, CaseIterable, Identifiable, SortOptionable, Codable {
    case name = "Name"
    case progress = "Progress"
    case downloadSpeed = "Download Speed"
    case uploadSpeed = "Upload Speed"
    case size = "Size"
    case state = "State"
    
    var id: String { self.rawValue }
    
    var apiKey: String {
        switch self {
        case .name: return "name"
        case .progress: return "progress"
        case .downloadSpeed: return "dlspeed"
        case .uploadSpeed: return "upspeed"
        case .size: return "size"
        case .state: return "state"
        }
    }
    
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
    
    var localizedLabel: Text {
        switch self {
        case .name:
            return Text("Name")
        case .progress:
            return Text("Progress")
        case .downloadSpeed:
            return Text("Download Speed")
        case .uploadSpeed:
            return Text("Upload Speed")
        case .size:
            return Text("Size")
        case .state:
            return Text("State")
        }
    }
}