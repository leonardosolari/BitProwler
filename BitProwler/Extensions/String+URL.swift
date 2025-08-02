import Foundation

extension String {
    func asSanitizedURL() -> String {
        var finalUrl = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalUrl.hasSuffix("/") {
            finalUrl += "/"
        }
        return finalUrl
    }
}