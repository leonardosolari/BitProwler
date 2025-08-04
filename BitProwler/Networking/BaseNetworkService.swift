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
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw AppError.invalidURL
        }
        
        urlComponents.path = (urlComponents.path as NSString).appendingPathComponent(path)
        
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let finalURL = urlComponents.url else {
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