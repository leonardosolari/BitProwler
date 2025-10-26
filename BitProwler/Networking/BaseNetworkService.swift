// BitProwler/Networking/BaseNetworkService.swift

import Foundation

class BaseNetworkService {
    
    internal let urlSession: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        self.urlSession = URLSession(configuration: configuration)
    }
    
    internal func buildURL(from baseURL: String, path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        let sanitizedBaseURL = baseURL.asSanitizedURL()
        
        guard let base = URL(string: sanitizedBaseURL) else {
            throw AppError.invalidURL
        }
        
        guard var components = URLComponents(string: path) else {
            throw AppError.invalidURL
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        
        // Usiamo il costruttore che unisce un percorso relativo a un URL base.
        guard let finalURL = components.url(relativeTo: base) else {
            throw AppError.invalidURL
        }
        
        return finalURL
    }
    
    internal func performRequest(_ request: URLRequest, using session: URLSession? = nil) async throws -> (Data, HTTPURLResponse) {
        
        do {
            let sessionToUse = session ?? self.urlSession
            let (data, response) = try await sessionToUse.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.unknownError
            }
            
            print("\n--- [NETWORK RESPONSE] ---")
            print("Status Code: \(httpResponse.statusCode)")
            print("--- [END RESPONSE] ---\n")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.httpError(statusCode: httpResponse.statusCode)
            }
            
            return (data, httpResponse)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.networkError(underlyingError: error)
        }
    }
}