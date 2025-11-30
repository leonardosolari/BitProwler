import XCTest

@MainActor
final class SearchFlowUITests: BitProwlerUITestsBase {

    func testSearchHappyPath() throws {
        launch(scenario: .searchSuccessWithResults, servers: .all)
        
        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Il campo di ricerca non è apparso")
        
        searchField.tap()
        searchField.typeText("Linux Distro")
        
        let searchButton = app.buttons["search_button"]
        XCTAssertTrue(searchButton.isEnabled, "Il pulsante di ricerca dovrebbe essere abilitato")
        searchButton.tap()
        
        let loadingText = app.staticTexts["Searching..."]
        XCTAssertTrue(loadingText.waitForExistence(timeout: 5), "Il testo di caricamento 'Searching...' non è apparso")
        XCTAssertTrue(loadingText.waitForNonExistence(timeout: 10), "Il testo di caricamento non è scomparso")
        
    
        let resultsList = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == 'search_results_list'")).firstMatch
        XCTAssertTrue(resultsList.waitForExistence(timeout: 5), "La lista dei risultati non è visibile")
        
        
        let rowQuery = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'torrent_result_row_'"))
        

        expectation(for: NSPredicate(format: "count == 3"), evaluatedWith: rowQuery)
        waitForExpectations(timeout: 5)
        
        let firstResultId = "magnet:?xt=urn:btih:11111"
        let expectedIdentifier = "torrent_result_row_\(firstResultId)"
        let firstResultRow = rowQuery.matching(NSPredicate(format: "identifier == %@", expectedIdentifier)).firstMatch
        
        XCTAssertTrue(firstResultRow.exists, "La prima riga di risultato non è stata trovata")
        
        XCTAssertTrue(firstResultRow.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)
        XCTAssertTrue(firstResultRow.staticTexts["1502"].exists)
        
        firstResultRow.tap()
        
        XCTAssertTrue(app.navigationBars["Torrent Details"].waitForExistence(timeout: 5), "La vista di dettaglio non è apparsa")
        
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)
        
        app.navigationBars["Torrent Details"].buttons["Close"].tap()
        
        XCTAssertFalse(app.navigationBars["Torrent Details"].exists, "La vista di dettaglio non si è chiusa")
        XCTAssertTrue(resultsList.exists, "La lista dei risultati non è più visibile dopo aver chiuso il dettaglio")
    }
}

extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}