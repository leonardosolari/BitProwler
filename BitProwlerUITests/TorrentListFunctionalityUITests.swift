import XCTest

@MainActor
final class TorrentListFunctionalityUITests: BitProwlerUITestsBase {

    func testTorrentListSorting() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let torrentsList = app.descendants(matching: .any).matching(identifier: "torrents_list").firstMatch
        XCTAssertTrue(torrentsList.waitForExistence(timeout: 10), "The torrents list did not appear.")
        
        var firstCell = torrentsList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.staticTexts["Arch Linux ISO"].waitForExistence(timeout: 5), "Initial sort order by progress is incorrect.")

        let sortMenu = app.buttons["torrents_sort_menu"]
        XCTAssertTrue(sortMenu.waitForExistence(timeout: 5))
        sortMenu.tap()

        let sortByNameButton = app.buttons["sort_option_Name"]
        XCTAssertTrue(sortByNameButton.waitForExistence(timeout: 2))
        sortByNameButton.tap()
        
        firstCell = torrentsList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.staticTexts["Arch Linux ISO"].waitForExistence(timeout: 5), "Sort by name is incorrect.")
        
        let secondCell = torrentsList.cells.element(boundBy: 1)
        XCTAssertTrue(secondCell.staticTexts["Debian 13 'Trixie' Netinstall"].waitForExistence(timeout: 5), "Sort by name is incorrect.")

        sortMenu.tap()

        let sortBySizeButton = app.buttons["sort_option_Size"]
        XCTAssertTrue(sortBySizeButton.waitForExistence(timeout: 2))
        sortBySizeButton.tap()

        firstCell = torrentsList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.staticTexts["Debian 13 'Trixie' Netinstall"].waitForExistence(timeout: 5), "Sort by size is incorrect.")
    }

    func testTorrentListSearching() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let torrentsList = app.descendants(matching: .any).matching(identifier: "torrents_list").firstMatch
        XCTAssertTrue(torrentsList.waitForExistence(timeout: 10))
        
        let initialCountExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 4"), object: torrentsList.cells)
        wait(for: [initialCountExpectation], timeout: 5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Ubuntu")

        let filteredCountExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 1"), object: torrentsList.cells)
        wait(for: [filteredCountExpectation], timeout: 5)
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)

        let clearButton = searchField.buttons["Clear text"]
        XCTAssertTrue(clearButton.exists)
        clearButton.tap()

        let clearedCountExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 4"), object: torrentsList.cells)
        wait(for: [clearedCountExpectation], timeout: 5)

        searchField.tap()
        searchField.typeText("NonExistentTorrent")
        
        XCTAssertTrue(app.staticTexts["No Results for “NonExistentTorrent”"].waitForExistence(timeout: 5))
    }
}