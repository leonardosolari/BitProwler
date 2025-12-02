import XCTest

@MainActor
final class FullFlowUITests: BitProwlerUITestsBase {

    func testFullSearchToAddFlow() throws {
        launch(scenario: .searchAndAddSuccess, servers: .all, mockDataFile: "search-and-add-flow")

        let searchField = app.textFields["search_field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field did not appear.")
        
        searchField.tap()
        searchField.typeText("Ubuntu")
        app.buttons["search_button"].tap()

        let loadingIndicator = app.staticTexts["Searching..."]
        XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 5))
        XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10), "Loading indicator did not disappear.")

        let resultRowIdentifier = "torrent_result_row_magnet:?xt=urn:btih:11111"
        let resultRow = app.descendants(matching: .any).matching(identifier: resultRowIdentifier).firstMatch
        XCTAssertTrue(resultRow.waitForExistence(timeout: 5), "The search result row was not found.")
        resultRow.tap()

        let detailView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "The torrent detail view did not appear.")

        let addButton = app.buttons["Add to qBittorrent"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()

        let successAlert = app.alerts["Download Started"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5), "Success alert did not appear.")
        successAlert.buttons["OK"].tap()

        detailView.buttons["Close"].tap()
        XCTAssertTrue(detailView.waitForNonExistence(timeout: 5), "Detail view did not close.")

        app.tabBars.buttons["Torrent"].tap()

        let newTorrentIdentifier = "torrent_row_hash_ubuntu_from_search"
        let newTorrentRow = app.descendants(matching: .any).matching(identifier: newTorrentIdentifier).firstMatch
        XCTAssertTrue(newTorrentRow.waitForExistence(timeout: 10), "The newly added torrent did not appear in the torrents list.")

        XCTAssertTrue(newTorrentRow.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)
        XCTAssertTrue(newTorrentRow.staticTexts["Downloading"].exists, "The new torrent should have 'Downloading' status.")
    }
}