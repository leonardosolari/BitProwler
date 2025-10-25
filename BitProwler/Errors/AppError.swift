import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case invalidURL
    case networkError(underlyingError: Error)
    case httpError(statusCode: Int)
    case decodingError(underlyingError: Error)
    case authenticationFailed
    case serverNotConfigured
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("The server URL is invalid.", comment: "Error message for an invalid server URL")
            
        case .networkError(let error):
            let format = NSLocalizedString("Network error: %@", comment: "Error message for a generic network error. The placeholder is for the specific error description.")
            return String(format: format, error.localizedDescription)
            
        case .httpError(let statusCode):
            switch statusCode {
            case 401, 403:
                return NSLocalizedString("Authentication failed. Check your credentials or API key.", comment: "Error message for HTTP 401/403 authentication failure")
            case 404:
                return NSLocalizedString("Server not found (404). Check the URL.", comment: "Error message for HTTP 404 not found")
            default:
                let format = NSLocalizedString("Server error (Status: %d).", comment: "Error message for other HTTP errors. The placeholder is for the status code.")
                return String(format: format, statusCode)
            }
            
        case .decodingError:
            return NSLocalizedString("Error reading the server response.", comment: "Error message for a data decoding/parsing failure")
            
        case .authenticationFailed:
            return NSLocalizedString("Authentication failed.", comment: "Error message for a generic authentication failure")
            
        case .serverNotConfigured:
            return NSLocalizedString("No active server configured.", comment: "Error message when no server is selected or configured")
            
        case .unknownError:
            return NSLocalizedString("An unknown error occurred.", comment: "Error message for an unexpected or unknown error")
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.authenticationFailed, .authenticationFailed):
            return true
        case (.serverNotConfigured, .serverNotConfigured):
            return true
        case (.unknownError, .unknownError):
            return true
        default:
            return false
        }
    }
}