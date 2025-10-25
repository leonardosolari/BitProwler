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
    
    private func logRequest(_ request: URLRequest) {
        print("\n--- [NETWORK REQUEST] ---")
        if let url = request.url {
            print("URL: \(url.absoluteString)")
        }
        if let method = request.httpMethod {
            print("Method: \(method)")
        }
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        print("--- [END REQUEST] ---\n")
    }
    
    internal func performRequest(_ request: URLRequest, using session: URLSession? = nil) async throws -> (Data, HTTPURLResponse) {
        logRequest(request) // Aggiungiamo il log della richiesta
        
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