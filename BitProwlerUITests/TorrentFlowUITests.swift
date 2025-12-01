import XCTest

@MainActor
final class TorrentFlowUITests: BitProwlerUITestsBase {

    func testTorrentListHappyPath() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        let torrentTab = app.tabBars.buttons["Torrent"]
        XCTAssertTrue(torrentTab.waitForExistence(timeout: 5), "Torrent tab did not appear in time.")
        torrentTab.tap()

        let torrentsList = app.descendants(matching: .any).matching(identifier: "torrents_list").firstMatch
        XCTAssertTrue(torrentsList.waitForExistence(timeout: 10), "The torrents list did not appear.")

        let ubuntuRowIdentifier = "torrent_row_abc123hash_ubuntu"
        let ubuntuRow = app.descendants(matching: .any).matching(identifier: ubuntuRowIdentifier).firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 5), "The torrent row for Ubuntu was not found.")
        XCTAssertTrue(ubuntuRow.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists, "Torrent name is incorrect.")
        XCTAssertTrue(ubuntuRow.staticTexts["85% of 5 GB"].exists, "Progress text is incorrect.")

        ubuntuRow.tap()

        let actionsViewNavigationBar = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsViewNavigationBar.waitForExistence(timeout: 5), "TorrentActionsView did not appear.")
        
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04.1 Desktop (LTS)"].exists)
        XCTAssertTrue(app.staticTexts["Downloading"].exists, "Status badge is incorrect.")
        XCTAssertTrue(app.staticTexts["1.2 MB/s"].exists, "Download speed is incorrect.")
        XCTAssertTrue(app.staticTexts["5 GB"].exists, "Size is incorrect.")
        XCTAssertTrue(app.staticTexts["Time Remaining"].exists)

        let pauseButton = app.buttons["action_button_toggle_pause"]
        XCTAssertTrue(pauseButton.exists, "Pause button not found.")
        XCTAssertTrue(pauseButton.staticTexts["Pause"].exists)
        pauseButton.tap()

        XCTAssertTrue(actionsViewNavigationBar.waitForNonExistence(timeout: 5), "TorrentActionsView did not dismiss after action.")
    }
    
    func testDeleteTorrentAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        let torrentTab = app.tabBars.buttons["Torrent"]
        XCTAssertTrue(torrentTab.waitForExistence(timeout: 5))
        torrentTab.tap()

        let ubuntuRow = app.descendants(matching: .any).matching(identifier: "torrent_row_abc123hash_ubuntu").firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10))
        ubuntuRow.tap()

        let actionsViewNavigationBar = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsViewNavigationBar.waitForExistence(timeout: 5))

        let deleteButton = app.buttons["action_button_delete"]
        XCTAssertTrue(deleteButton.exists)
        deleteButton.tap()

        let alert = app.alerts["Delete Torrent"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        
        let confirmDeleteButton = alert.descendants(matching: .button).matching(identifier: "alert_button_confirm_delete").firstMatch
        XCTAssertTrue(confirmDeleteButton.exists)
        
        confirmDeleteButton.tap()
        
        XCTAssertTrue(actionsViewNavigationBar.waitForNonExistence(timeout: 5), "TorrentActionsView did not dismiss after delete.")
    }
    
    func testAddTorrentManually() throws {
        launch(scenario: .torrentsEmpty, servers: .qbittorrent)

        let torrentTab = app.tabBars.buttons["Torrent"]
        XCTAssertTrue(torrentTab.waitForExistence(timeout: 5))
        torrentTab.tap()

        let addTorrentButton = app.buttons["add_torrent_button"]
        XCTAssertTrue(addTorrentButton.waitForExistence(timeout: 5))
        addTorrentButton.tap()

        let addTorrentSheet = app.navigationBars["Add Torrent"]
        XCTAssertTrue(addTorrentSheet.waitForExistence(timeout: 5))

        let magnetLinkField = app.textFields["Enter magnet Link"]
        XCTAssertTrue(magnetLinkField.exists)

        magnetLinkField.tap()
        magnetLinkField.typeText("magnet:?xt=urn:btih:dummytesthash12345")

        let addButton = app.buttons["Add Torrent"]
        XCTAssertTrue(addButton.isEnabled)
        addButton.tap()

        XCTAssertTrue(addTorrentSheet.waitForNonExistence(timeout: 5), "Add Torrent sheet did not dismiss.")
    }

    func testEmptyTorrentList() throws {
        launch(scenario: .torrentsEmpty, servers: .qbittorrent)

        let torrentTab = app.tabBars.buttons["Torrent"]
        XCTAssertTrue(torrentTab.waitForExistence(timeout: 5))
        torrentTab.tap()

        let emptyState = app.descendants(matching: .any).matching(identifier: "torrents_empty_state").firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10), "The empty state view for torrents did not appear.")

        XCTAssertTrue(app.staticTexts["No Torrents"].exists)
    }

    func testTorrentListError() throws {
        launch(scenario: .torrentsError, servers: .qbittorrent)

        let torrentTab = app.tabBars.buttons["Torrent"]
        XCTAssertTrue(torrentTab.waitForExistence(timeout: 5))
        torrentTab.tap()

        let errorView = app.descendants(matching: .any).matching(identifier: "torrents_error_view").firstMatch
        XCTAssertTrue(errorView.waitForExistence(timeout: 10), "The error view for torrents did not appear.")

        XCTAssertTrue(app.staticTexts["Connection Error"].exists)
        XCTAssertTrue(app.buttons["Try Again"].exists)
    }
}