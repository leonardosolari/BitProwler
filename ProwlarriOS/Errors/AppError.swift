import Foundation

enum AppError: Error, LocalizedError {
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
            return "L'URL del server non è valido."
        case .networkError(let error):
            return "Errore di rete: \(error.localizedDescription)"
        case .httpError(let statusCode):
            switch statusCode {
            case 401, 403:
                return "Autenticazione fallita. Controlla le credenziali o la chiave API."
            case 404:
                return "Server non trovato (404). Controlla l'URL."
            default:
                return "Errore del server (Status: \(statusCode))."
            }
        case .decodingError:
            return "Errore nella lettura della risposta del server."
        case .authenticationFailed:
            return "Autenticazione fallita."
        case .serverNotConfigured:
            return "Nessun server attivo configurato."
        case .unknownError:
            return "Si è verificato un errore sconosciuto."
        }
    }
}