import Foundation

enum MockDataError: Error {
    case fileNotFound(String)
    case dataDecodingFailed(Error)
}

struct MockDataLoader {
    static func load<T: Decodable>(_ filename: String) -> T {
        guard let url = Bundle(for: BitProwlerUITests.self).url(forResource: filename, withExtension: "json") else {
            fatalError("Mock data file not found: \(filename).json")
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode mock data from \(filename).json: \(error)")
        }
    }
}