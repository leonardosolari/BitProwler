import Foundation

struct AppEnvironment {
    static var isUITesting: Bool {
        return ProcessInfo.processInfo.arguments.contains("-UITesting")
    }
}