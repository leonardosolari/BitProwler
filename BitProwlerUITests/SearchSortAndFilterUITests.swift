import XCTest

@MainActor
final class SearchSortAndFilterUITests: BitProwlerUITestsBase {

    override func tearDownWithError() throws {
        let sortMenuButton = app.buttons["sort_menu_button"]
        
        if sortMenuButton.exists && !sortMenuButton.label.contains("Default") {
            sortMenuButton.tap()
            let defaultSortButton = app.buttons["sort_option_Default"]
            if defaultSortButton.waitForExistence(timeout: 2) {
                defaultSortButton.tap()
            }
        }
        
        try super.tearDownWithError()
    }

    func testSearchResultSorting() throws {
        launch(scenario: .searchSuccessWithResults, servers: .all, mockDataFile: "search-sorting")
        
        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        searchField.tap()
        searchField.typeText("Linux")
        app.buttons["search_button"].tap()
        
        let loadingIndicator = app.staticTexts["Searching..."]
        XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 5))
        XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10))
        
        let resultsList = app.descendants(matching: .any).matching(identifier: "search_results_list").firstMatch
        XCTAssertTrue(resultsList.waitForExistence(timeout: 5))
        
        var firstCell = resultsList.cells.element(boundBy: 0)
        
        let sortMenuButton = app.buttons["sort_menu_button"]
        XCTAssertTrue(sortMenuButton.exists)
        sortMenuButton.tap()
        
        let sizeSortButton = app.buttons["sort_option_Size"]
        XCTAssertTrue(sizeSortButton.waitForExistence(timeout: 2))
        sizeSortButton.tap()
        
        firstCell = resultsList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.staticTexts["OpenSUSE Leap 15.6"].waitForExistence(timeout: 5))
        
        sortMenuButton.tap()
        XCTAssertTrue(sizeSortButton.waitForExistence(timeout: 2))
        sizeSortButton.tap()
        
        firstCell = resultsList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.staticTexts["Debian 13 'Trixie' Netinstall"].waitForExistence(timeout: 5))
    }
    
    func testSearchResultFilteringByIndexer() throws {
        launch(scenario: .searchSuccessWithResults, servers: .all, mockDataFile: "search-sorting")
        
        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        searchField.tap()
        searchField.typeText("Linux")
        app.buttons["search_button"].tap()
        
        let loadingIndicator = app.staticTexts["Searching..."]
        XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 5))
        XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10))
        
        let resultsList = app.descendants(matching: .any).matching(identifier: "search_results_list").firstMatch
        XCTAssertTrue(resultsList.waitForExistence(timeout: 5))
        
        let initialCellsQuery = resultsList.cells
        var expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 6"), object: initialCellsQuery)
        wait(for: [expectation], timeout: 5)
        
        let indexerMenuButton = app.buttons["indexer_filter_menu_button"]
        XCTAssertTrue(indexerMenuButton.exists)
        indexerMenuButton.tap()
        
        let linuxTrackerFilter = app.buttons["indexer_filter_option_LinuxTracker"]
        XCTAssertTrue(linuxTrackerFilter.waitForExistence(timeout: 2))
        linuxTrackerFilter.tap()
        
        let filteredCellsQuery = resultsList.cells
        expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: filteredCellsQuery)
        wait(for: [expectation], timeout: 5)
        
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)
        XCTAssertTrue(app.staticTexts["Arch Linux 2025.05.01"].exists)
        XCTAssertFalse(app.staticTexts["Debian 13 'Trixie' Netinstall"].exists)
        
        indexerMenuButton.tap()
        XCTAssertTrue(linuxTrackerFilter.waitForExistence(timeout: 2))
        linuxTrackerFilter.tap()
        
        let finalCellsQuery = resultsList.cells
        expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 6"), object: finalCellsQuery)
        wait(for: [expectation], timeout: 5)
    }
}

extension XCUIElementQuery {
    func matching(identifier: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return self.matching(predicate)
    }
}