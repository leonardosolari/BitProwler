import Foundation

enum TorrentState: String {
    case downloading = "downloading"
    case uploading = "uploading"
    case pausedDL = "pauseddl"
    case pausedUP = "pausedup"
    case stalledDL = "stalleddl"
    case stalledUP = "stalledup"
    case stoppedDL = "stoppeddl"
    case stoppedUP = "stoppedup"
    case error = "error"
    case missingFiles = "missingfiles"
    case unknown = "unknown"
    
    init(from string: String) {
        self = TorrentState(rawValue: string.lowercased()) ?? .unknown
    }
    
    var isPaused: Bool {
        self == .pausedDL || self == .pausedUP
    }
    
    var displayName: String {
        switch self {
        case .downloading: return "Download"
        case .uploading: return "Upload"
        case .pausedDL: return "In Pausa (DL)"
        case .pausedUP: return "In Pausa (UP)"
        case .stalledDL: return "Stalled (DL)"
        case .stalledUP: return "Stalled (UP)"
        case .stoppedDL: return "Arrestato (DL)"
        case .stoppedUP: return "Completato"
        case .error: return "Errore"
        case .missingFiles: return "File Mancanti"
        case .unknown: return "Sconosciuto"
        }
    }
} 