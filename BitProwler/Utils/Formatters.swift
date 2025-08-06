import Foundation

struct Formatters {
    static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter
    }()
    
    static let speedFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .decimal
        return formatter
    }()
    
    static let iso8601Formatter = ISO8601DateFormatter()
    
    static let etaFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter
    }()

    static func formatSize(_ size: Int64) -> String {
        return byteCountFormatter.string(fromByteCount: size)
    }
    
    static func formatSpeed(_ speed: Int64) -> String {
        return "\(speedFormatter.string(fromByteCount: speed))/s"
    }
    
    static func formatDate(_ dateString: String) -> String {
        if let date = iso8601Formatter.date(from: dateString) {
            return date.formatted(date: .long, time: .shortened)
        }
        return dateString
    }
    
    static func formatETA(_ seconds: Int) -> String {
        if seconds == 8640000 {
            return "∞"
        }
        
        if seconds > 0 {
            return etaFormatter.string(from: TimeInterval(seconds)) ?? ""
        }
        
        return ""
    }
}