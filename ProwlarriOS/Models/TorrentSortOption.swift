// File: /ProwlarriOS/Models/TorrentSortOption.swift

import Foundation

enum TorrentSortOption: String, CaseIterable, Identifiable {
    case name = "Nome"
    case progress = "Progresso"
    case downloadSpeed = "Velocità Download"
    case uploadSpeed = "Velocità Upload"
    case size = "Dimensione"
    case state = "Stato"
    
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
}