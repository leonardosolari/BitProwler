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
}