import Testing
import Foundation
@testable import BitProwler

struct AppErrorLocalizationTests {

    private func setEnglishLocalization() -> [Any]? {
        let originalLanguages = UserDefaults.standard.array(forKey: "AppleLanguages")
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        return originalLanguages
    }

    private func restoreOriginalLocalization(originalLanguages: [Any]?) {
        if let original = originalLanguages {
            UserDefaults.standard.set(original, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    @Test
    func testStaticErrorMessages() {
        let originalLanguages = setEnglishLocalization()
        defer { restoreOriginalLocalization(originalLanguages: originalLanguages) }

        #expect(AppError.invalidURL.errorDescription == "The server URL is invalid.")
        #expect(AppError.decodingError(underlyingError: TestError()).errorDescription == "Error reading the server response.")
        #expect(AppError.authenticationFailed.errorDescription == "Authentication failed.")
        #expect(AppError.serverNotConfigured.errorDescription == "No active server configured.")
        #expect(AppError.unknownError.errorDescription == "An unknown error occurred.")
    }
    
    @Test
    func testHttpErrorMessages() {
        let originalLanguages = setEnglishLocalization()
        defer { restoreOriginalLocalization(originalLanguages: originalLanguages) }

        #expect(AppError.httpError(statusCode: 401).errorDescription == "Authentication failed. Check your credentials or API key.")
        #expect(AppError.httpError(statusCode: 403).errorDescription == "Authentication failed. Check your credentials or API key.")
        #expect(AppError.httpError(statusCode: 404).errorDescription == "Server not found (404). Check the URL.")
        #expect(AppError.httpError(statusCode: 500).errorDescription == "Server error (Status: 500).")
    }
    
    @Test
    func testDynamicErrorMessages() {
        let originalLanguages = setEnglishLocalization()
        defer { restoreOriginalLocalization(originalLanguages: originalLanguages) }

        let underlyingError = TestError(message: "The network connection was lost.")
        let expectedNetworkMessage = "Network error: The network connection was lost."
        #expect(AppError.networkError(underlyingError: underlyingError).errorDescription == expectedNetworkMessage)
    }
    
    private struct TestError: LocalizedError {
        var message: String?
        var errorDescription: String? { message }
        
        init(message: String = "Generic Test Error") {
            self.message = message
        }
    }
}