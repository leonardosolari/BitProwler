import XCTest

@MainActor
final class PathManagementUITests: BitProwlerUITestsBase {

    func testRecentPathCreationAndDeletion() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let ubuntuRow = app.descendants(matching: .any).matching(identifier: "torrent_row_abc123hash_ubuntu").firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10), "The torrent row for Ubuntu was not found.")
        ubuntuRow.tap()

        let actionsView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5), "TorrentActionsView did not appear.")

        let moveButton = app.buttons["action_button_move"]
        XCTAssertTrue(moveButton.exists)
        moveButton.tap()

        let locationPicker = app.navigationBars["Move Torrent"]
        XCTAssertTrue(locationPicker.waitForExistence(timeout: 5))
        
        let newPath = "/downloads/new-linux-distros"
        let pathTextField = app.textFields["location_picker_path_field"]
        XCTAssertTrue(pathTextField.exists)
        pathTextField.tap()
        pathTextField.typeText(newPath)

        app.buttons["picker_move_button"].tap()

        XCTAssertTrue(locationPicker.waitForNonExistence(timeout: 5), "Location picker sheet should dismiss.")
        XCTAssertTrue(actionsView.waitForNonExistence(timeout: 5), "Actions sheet should dismiss after move.")

        app.tabBars.buttons["Settings"].tap()
        
        let settingsList = app.descendants(matching: .any).matching(identifier: "settings_list").firstMatch
        XCTAssertTrue(settingsList.waitForExistence(timeout: 5))
        
        settingsList.buttons["Manage Paths"].tap()
        
        let pathsList = app.descendants(matching: .any).matching(identifier: "paths_list").firstMatch
        XCTAssertTrue(pathsList.waitForExistence(timeout: 5))
        
        let newPathRowIdentifier = "path_row_\(newPath)"
        let newPathRow = app.descendants(matching: .any).matching(identifier: newPathRowIdentifier).firstMatch
        XCTAssertTrue(newPathRow.waitForExistence(timeout: 5), "The new path did not appear in the management list.")
        
        newPathRow.swipeLeft()
        
        let deleteButton = pathsList.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()
        
        XCTAssertTrue(newPathRow.waitForNonExistence(timeout: 5), "The path row was not deleted.")
    }
}