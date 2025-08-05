import Foundation
import SwiftUI

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
    case queuedDL = "queueddl"
    case queuedUP = "queuedup"
    case moving = "moving"
    case checkingUP = "checkingup"
    case checkingDL = "checkingdl"
    case metaDL = "metadl"
    case forcedUP = "forcedup"
    case forcedDL = "forceddl"
    case unknown = "unknown"
    
    init(from string: String) {
        self = TorrentState(rawValue: string.lowercased()) ?? .unknown
    }
    
    var isPaused: Bool {
        self == .pausedDL || self == .pausedUP
    }
    
    var isForced: Bool {
        self == .forcedDL || self == .forcedUP
    }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .downloading: return "Downloading"
        case .uploading: return "Uploading"
        case .pausedDL: return "Paused (DL)"
        case .pausedUP: return "Paused (UP)"
        case .stalledDL: return "Stalled (DL)"
        case .stalledUP: return "Stalled (UP)"
        case .stoppedDL: return "Stopped (DL)"
        case .stoppedUP: return "Completed"
        case .error: return "Error"
        case .missingFiles: return "Missing Files"
        case .queuedDL: return "Queued (DL)"
        case .queuedUP: return "Queued (UP)"
        case .moving: return "Moving"
        case .checkingUP: return "Checking (UP)"
        case .checkingDL: return "Checking (DL)"
        case .metaDL: return "Downloading Metadata"
        case .forcedUP: return "Forced (UP)"
        case .forcedDL: return "Forced (DL)"
        case .unknown: return "Unknown"
        }
    }
}