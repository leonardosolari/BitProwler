import Foundation

class BaseMockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func stopLoading() {}
    
    func startLoading(with handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?) {
        guard let handler = handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

final class ProwlarrMockURLProtocol: BaseMockURLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override func startLoading() {
        startLoading(with: ProwlarrMockURLProtocol.requestHandler)
    }
}

final class QBittorrentMockURLProtocol: BaseMockURLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override func startLoading() {
        startLoading(with: QBittorrentMockURLProtocol.requestHandler)
    }
}