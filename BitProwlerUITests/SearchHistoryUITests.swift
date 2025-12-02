import XCTest

@MainActor
final class SearchHistoryUITests: BitProwlerUITestsBase {

    func testSearchHistoryFunctionality() throws {
        launch(
            scenario: .searchSuccessWithResults,
            servers: .all,
            mockDataFile: "search-success",
            clearUserDefaults: true
        )

        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        let firstSearchTerm = "Ubuntu"
        searchField.tap()
        searchField.typeText(firstSearchTerm)
        app.buttons["search_button"].tap()

        let resultsList = app.descendants(matching: .any).matching(identifier: "search_results_list").firstMatch
        XCTAssertTrue(resultsList.waitForExistence(timeout: 10))

        app.terminate()
        
        app.launchArguments.removeAll(where: { $0 == "-shouldClearUserDefaults" })
        app.launch()

        let historyList = app.descendants(matching: .any).matching(identifier: "search_history_list").firstMatch
        XCTAssertTrue(historyList.waitForExistence(timeout: 10))
        
        let firstHistoryItem = app.buttons["history_item_\(firstSearchTerm)"]
        XCTAssertTrue(firstHistoryItem.exists)

        let secondSearchTerm = "Debian"
        let searchFieldAfterRestart = app.textFields["search_field"]
        XCTAssertTrue(searchFieldAfterRestart.waitForExistence(timeout: 5))
        searchFieldAfterRestart.tap()
        searchFieldAfterRestart.typeText(secondSearchTerm)
        app.buttons["search_button"].tap()
        XCTAssertTrue(resultsList.waitForExistence(timeout: 10))
        
        app.terminate()
        app.launch()

        XCTAssertTrue(historyList.waitForExistence(timeout: 10))
        let reloadedFirstHistoryItem = app.buttons["history_item_\(firstSearchTerm)"]
        XCTAssertTrue(reloadedFirstHistoryItem.exists)
        reloadedFirstHistoryItem.tap()

        XCTAssertTrue(resultsList.waitForExistence(timeout: 10))
        let finalSearchField = app.textFields["search_field"]
        guard let searchFieldValue = finalSearchField.value as? String else {
            XCTFail()
            return
        }
        XCTAssertEqual(searchFieldValue, firstSearchTerm)

        app.terminate()
        app.launch()

        XCTAssertTrue(historyList.waitForExistence(timeout: 10))
        let clearButton = app.buttons["clear_history_button"]
        XCTAssertTrue(clearButton.exists)
        clearButton.tap()
        
        app.terminate()
        app.launch()
        
        XCTAssertTrue(historyList.waitForNonExistence(timeout: 5))
    }
}