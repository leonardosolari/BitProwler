import XCTest

@MainActor
final class SearchFilterFunctionalityUITests: BitProwlerUITestsBase {

    func testAddAndApplySingleFilter() throws {
        launch(scenario: .searchSuccessWithResults, servers: .all, mockDataFile: "search-sorting")

        app.tabBars.buttons["Settings"].tap()
        app.collectionViews.buttons["Manage Filters"].tap()
        addFilter(name: "Debian Filter", keyword: "Debian")

        let filterRowIdentifier = "filter_row_Debian-Filter"
        let filterRow = app.descendants(matching: .any).matching(identifier: filterRowIdentifier).firstMatch
        XCTAssertTrue(filterRow.waitForExistence(timeout: 2), "The filter row itself was not found.")
        
        let filterToggleIdentifier = "toggle_filter_Debian-Filter"
        let filterToggle = app.switches[filterToggleIdentifier]
        XCTAssertTrue(filterToggle.waitForExistence(timeout: 2), "The toggle switch for the filter was not found directly.")
        XCTAssertEqual(filterToggle.value as? String, "1", "The filter should be enabled by default.")
        
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Linux")
        app.buttons["search_button"].tap()

        let resultsList = app.descendants(matching: .any).matching(identifier: "search_results_list").firstMatch
        
        let filteredResultsExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 1"), object: resultsList.cells)
        wait(for: [filteredResultsExpectation], timeout: 10)
        XCTAssertTrue(app.staticTexts["Debian 13 'Trixie' Netinstall"].exists)

        let filtersMenu = app.buttons["filters_menu_button"]
        XCTAssertTrue(filtersMenu.exists)
        filtersMenu.tap()
        
        let menuFilterToggle = app.buttons["Debian Filter"]
        XCTAssertTrue(menuFilterToggle.waitForExistence(timeout: 2))
        menuFilterToggle.tap()

        let unfilteredResultsExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 6"), object: resultsList.cells)
        wait(for: [unfilteredResultsExpectation], timeout: 5)
    }
    
    func testFilterAndOrLogic() throws {
        launch(scenario: .searchSuccessWithResults, servers: .all, mockDataFile: "search-sorting")

        app.tabBars.buttons["Settings"].tap()
        app.collectionViews.buttons["Manage Filters"].tap()
        
        addFilter(name: "Ubuntu Filter", keyword: "Ubuntu")
        addFilter(name: "Debian Filter", keyword: "Debian")

        app.tabBars.buttons["Search"].tap()
        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Linux")
        app.buttons["search_button"].tap()

        let emptyStateFiltered = app.descendants(matching: .any).matching(identifier: "search_empty_state_filtered_out").firstMatch
        XCTAssertTrue(emptyStateFiltered.waitForExistence(timeout: 10), "The empty state for filtered results did not appear.")

        app.tabBars.buttons["Settings"].tap()
        let logicPicker = app.buttons["filter_logic_picker"]
        XCTAssertTrue(logicPicker.waitForExistence(timeout: 2))
        logicPicker.tap()
        app.buttons["Match any filter"].tap()
        
        app.tabBars.buttons["Search"].tap()
        
        let resultsList = app.descendants(matching: .any).matching(identifier: "search_results_list").firstMatch
        let orResultsExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: resultsList.cells)
        wait(for: [orResultsExpectation], timeout: 5)
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)
        XCTAssertTrue(app.staticTexts["Debian 13 'Trixie' Netinstall"].exists)
    }

    private func addFilter(name: String, keyword: String) {
        app.buttons["add_filter_button"].tap()
        
        let nameField = app.textFields["filter_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText(name)

        let keywordField = app.textFields["filter_keyword_field"]
        keywordField.tap()
        keywordField.typeText(keyword)

        app.buttons["save_filter_button"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "filter_row_\(name.replacingOccurrences(of: " ", with: "-"))").firstMatch.waitForExistence(timeout: 2))
    }
}