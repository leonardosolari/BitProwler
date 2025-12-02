import XCTest

@MainActor
final class TorrentFlowUITests: BitProwlerUITestsBase {

    func testTorrentListAndPauseAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        let torrentTab = app.tabBars.buttons["Torrent"]
        XCTAssertTrue(torrentTab.waitForExistence(timeout: 5), "Torrent tab did not appear in time.")
        torrentTab.tap()

        let torrentsList = app.descendants(matching: .any).matching(identifier: "torrents_list").firstMatch
        XCTAssertTrue(torrentsList.waitForExistence(timeout: 10), "The torrents list did not appear.")

        let ubuntuRowIdentifier = "torrent_row_abc123hash_ubuntu"
        let ubuntuRow = app.descendants(matching: .any).matching(identifier: ubuntuRowIdentifier).firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 5), "The torrent row for Ubuntu was not found.")
        XCTAssertTrue(ubuntuRow.staticTexts["Downloading"].exists, "Initial status should be 'Downloading'.")

        ubuntuRow.tap()

        let actionsViewNavigationBar = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsViewNavigationBar.waitForExistence(timeout: 5), "TorrentActionsView did not appear.")
        
        let pauseButton = app.buttons["action_button_toggle_pause"]
        XCTAssertTrue(pauseButton.exists, "Pause button not found.")
        XCTAssertTrue(pauseButton.staticTexts["Pause"].exists)
        pauseButton.tap()

        XCTAssertTrue(actionsViewNavigationBar.waitForNonExistence(timeout: 5), "TorrentActionsView did not dismiss after action.")
        
        let pausedBadge = ubuntuRow.staticTexts["Paused (DL)"]
        XCTAssertTrue(pausedBadge.waitForExistence(timeout: 5), "Status badge did not update to 'Paused (DL)'.")
    }
    
    func testDeleteTorrentAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let ubuntuRowIdentifier = "torrent_row_abc123hash_ubuntu"
        let ubuntuRow = app.descendants(matching: .any).matching(identifier: ubuntuRowIdentifier).firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10))
        ubuntuRow.tap()

        let actionsViewNavigationBar = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsViewNavigationBar.waitForExistence(timeout: 5))

        app.buttons["action_button_delete"].tap()

        let alert = app.alerts["Delete Torrent"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        
        let confirmDeleteButton = alert.buttons["Delete"]
        XCTAssertTrue(confirmDeleteButton.exists)
        confirmDeleteButton.tap()
        
        XCTAssertTrue(actionsViewNavigationBar.waitForNonExistence(timeout: 5), "TorrentActionsView did not dismiss after delete.")
        XCTAssertTrue(ubuntuRow.waitForNonExistence(timeout: 5), "Torrent row should be removed from the list after deletion.")
    }
    
    func testDeleteTorrentAndDataAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let ubuntuRowIdentifier = "torrent_row_abc123hash_ubuntu"
        let ubuntuRow = app.descendants(matching: .any).matching(identifier: ubuntuRowIdentifier).firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10))
        ubuntuRow.tap()

        let actionsViewNavigationBar = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsViewNavigationBar.waitForExistence(timeout: 5))

        app.buttons["action_button_delete_data"].tap()

        let alert = app.alerts["Delete Torrent and Data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        
        let confirmDeleteButton = alert.buttons["Delete"]
        XCTAssertTrue(confirmDeleteButton.exists)
        confirmDeleteButton.tap()
        
        XCTAssertTrue(actionsViewNavigationBar.waitForNonExistence(timeout: 5), "TorrentActionsView did not dismiss after delete.")
        XCTAssertTrue(ubuntuRow.waitForNonExistence(timeout: 5), "Torrent row should be removed from the list after deletion.")
    }

    func testAddTorrentManually() throws {
        launch(scenario: .torrentsEmpty, servers: .qbittorrent)

        app.tabBars.buttons["Torrent"].tap()

        let addTorrentButton = app.buttons["add_torrent_button"]
        XCTAssertTrue(addTorrentButton.waitForExistence(timeout: 5))
        addTorrentButton.tap()

        let addTorrentSheet = app.navigationBars["Add Torrent"]
        XCTAssertTrue(addTorrentSheet.waitForExistence(timeout: 5))

        let magnetLinkField = app.textFields["Enter magnet Link"]
        XCTAssertTrue(magnetLinkField.exists)

        magnetLinkField.tap()
        magnetLinkField.typeText("magnet:?xt=urn:btih:dummytesthash12345")

        app.buttons["Add Torrent"].tap()

        XCTAssertTrue(addTorrentSheet.waitForNonExistence(timeout: 5), "Add Torrent sheet did not dismiss.")
    }

    func testEmptyTorrentList() throws {
        launch(scenario: .torrentsEmpty, servers: .qbittorrent)

        app.tabBars.buttons["Torrent"].tap()

        let emptyState = app.descendants(matching: .any).matching(identifier: "torrents_empty_state").firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10), "The empty state view for torrents did not appear.")

        XCTAssertTrue(app.staticTexts["No Torrents"].exists)
    }

    func testTorrentListError() throws {
        launch(scenario: .torrentsError, servers: .qbittorrent)

        app.tabBars.buttons["Torrent"].tap()

        let errorView = app.descendants(matching: .any).matching(identifier: "torrents_error_view").firstMatch
        XCTAssertTrue(errorView.waitForExistence(timeout: 10), "The error view for torrents did not appear.")

        XCTAssertTrue(app.staticTexts["Connection Error"].exists)
        XCTAssertTrue(app.buttons["Try Again"].exists)
    }

    func testResumeAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let archRow = app.descendants(matching: .any).matching(identifier: "torrent_row_ghi789hash_arch").firstMatch
        XCTAssertTrue(archRow.waitForExistence(timeout: 10))
        XCTAssertTrue(archRow.staticTexts["Paused (DL)"].exists)

        archRow.tap()

        let actionsView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5))

        let resumeButton = app.buttons["action_button_toggle_pause"]
        XCTAssertTrue(resumeButton.exists)
        XCTAssertTrue(resumeButton.staticTexts["Resume"].exists)
        resumeButton.tap()

        XCTAssertTrue(actionsView.waitForNonExistence(timeout: 5))
        
        let downloadingBadge = archRow.staticTexts["Downloading"]
        XCTAssertTrue(downloadingBadge.waitForExistence(timeout: 5), "Status badge did not update to 'Downloading'.")
    }

    func testForceAndUnforceAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let ubuntuRow = app.descendants(matching: .any).matching(identifier: "torrent_row_abc123hash_ubuntu").firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10))
        ubuntuRow.tap()

        let actionsView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5))

        let forceButton = app.buttons["action_button_toggle_force"]
        XCTAssertTrue(forceButton.exists)
        XCTAssertTrue(forceButton.staticTexts["Force"].exists)
        forceButton.tap()

        XCTAssertTrue(actionsView.waitForNonExistence(timeout: 5))
        XCTAssertTrue(ubuntuRow.staticTexts["Forced (DL)"].waitForExistence(timeout: 5))
        
        ubuntuRow.tap()
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5))
        
        let unforceButton = app.buttons["action_button_toggle_force"]
        XCTAssertTrue(unforceButton.exists)
        XCTAssertTrue(unforceButton.staticTexts["Unforce"].exists)
        unforceButton.tap()
        
        XCTAssertTrue(actionsView.waitForNonExistence(timeout: 5))
        XCTAssertTrue(ubuntuRow.staticTexts["Downloading"].waitForExistence(timeout: 5))
    }

    func testRecheckAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()
        let ubuntuRow = app.descendants(matching: .any).matching(identifier: "torrent_row_abc123hash_ubuntu").firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10))
        ubuntuRow.tap()

        let actionsView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5))

        app.buttons["action_button_recheck"].tap()

        XCTAssertTrue(actionsView.waitForNonExistence(timeout: 5))
        XCTAssertTrue(ubuntuRow.staticTexts["Checking (DL)"].waitForExistence(timeout: 5))
    }

    func testMoveAction() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()
        let ubuntuRow = app.descendants(matching: .any).matching(identifier: "torrent_row_abc123hash_ubuntu").firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10))
        ubuntuRow.tap()

        let actionsView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5))

        app.buttons["action_button_move"].tap()

        let locationPicker = app.navigationBars["Move Torrent"]
        XCTAssertTrue(locationPicker.waitForExistence(timeout: 5))
        
        let pathTextField = app.textFields["Full Path"]
        XCTAssertTrue(pathTextField.exists)
        pathTextField.tap()
        pathTextField.typeText("/new/downloads/linux")

        app.buttons["picker_move_button"].tap()

        XCTAssertTrue(locationPicker.waitForNonExistence(timeout: 5), "Location picker sheet should dismiss.")
        XCTAssertTrue(actionsView.waitForNonExistence(timeout: 5), "Actions sheet should dismiss after move.")
    }
}