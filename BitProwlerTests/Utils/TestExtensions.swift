import Foundation

extension URLRequest {
    func getBodyData() -> Data? {
        if let body = self.httpBody { return body }
        guard let stream = self.httpBodyStream else { return nil }
        
        stream.open()
        defer { stream.close() }
        
        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        while true {
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)
            if bytesRead <= 0 { break }
            data.append(buffer, count: bytesRead)
        }
        
        return data
    }
}