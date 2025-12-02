import Testing
import Foundation
@testable import BitProwler

struct StringExtensionsTests {
    
    @Test
    func testAsSanitizedURL() {
        #expect(
            "http://example.com".asSanitizedURL() == "http://example.com/",
            "Deve aggiungere uno slash finale se mancante"
        )
        
        #expect(
            "http://example.com/".asSanitizedURL() == "http://example.com/",
            "Non deve aggiungere uno slash se già presente"
        )
        
        #expect(
            "  http://example.com  ".asSanitizedURL() == "http://example.com/",
            "Deve rimuovere gli spazi bianchi all'inizio e alla fine e aggiungere lo slash"
        )
        
        #expect(
            "  http://example.com/  ".asSanitizedURL() == "http://example.com/",
            "Deve rimuovere gli spazi bianchi anche se lo slash è già presente"
        )
        
        #expect(
            "http://example.com/api/v1".asSanitizedURL() == "http://example.com/api/v1/",
            "Deve funzionare correttamente con URL che includono un percorso"
        )
        
        #expect(
            "".asSanitizedURL() == "/",
            "Una stringa vuota deve restituire solo uno slash"
        )
        
        #expect(
            "   ".asSanitizedURL() == "/",
            "Una stringa di soli spazi deve restituire solo uno slash"
        )
    }
}