import XCTest

@MainActor
final class TorrentFileSelectionUITests: BitProwlerUITestsBase {

    func testFileSelectionAndDeselection() throws {
        launch(scenario: .torrentsSuccess, servers: .qbittorrent, mockDataFile: "torrent-success")

        app.tabBars.buttons["Torrent"].tap()

        let ubuntuRow = app.descendants(matching: .any).matchingByIdentifier("torrent_row_abc123hash_ubuntu").firstMatch
        XCTAssertTrue(ubuntuRow.waitForExistence(timeout: 10), "The torrent row for Ubuntu was not found.")
        ubuntuRow.tap()

        let actionsView = app.navigationBars["Torrent Details"]
        XCTAssertTrue(actionsView.waitForExistence(timeout: 5), "TorrentActionsView did not appear.")
        
        let showFilesButton = app.buttons["action_button_show_files"]
        XCTAssertTrue(showFilesButton.exists)
        showFilesButton.tap()
        
        let filesSheet = app.navigationBars["Torrent Files"]
        XCTAssertTrue(filesSheet.waitForExistence(timeout: 5), "The file list sheet did not appear.")
        
        let mkvFileRow = app.descendants(matching: .any).matchingByIdentifier("file_row_file-0").firstMatch
        XCTAssertTrue(mkvFileRow.waitForExistence(timeout: 5), "The row for the MKV file (index 0) did not appear.")
        
        let posterFileRow = app.descendants(matching: .any).matchingByIdentifier("file_row_file-3").firstMatch
        XCTAssertTrue(posterFileRow.waitForExistence(timeout: 5), "The row for the Poster file (index 3) did not appear.")

        let mkvToggleButton = mkvFileRow.descendants(matching: .any).matchingByIdentifier("file_toggle_file-0").firstMatch
        let posterToggleButton = posterFileRow.descendants(matching: .any).matchingByIdentifier("file_toggle_file-3").firstMatch
        
        XCTAssertTrue(mkvToggleButton.exists, "Toggle button for MKV file not found.")
        XCTAssertTrue(posterToggleButton.exists, "Toggle button for Poster file not found.")
        
        XCTAssertEqual(mkvToggleButton.value as? String, "Selected", "MKV file should be selected by default.")
        XCTAssertEqual(posterToggleButton.value as? String, "Not Selected", "Poster file should be unselected by default.")
        
        mkvToggleButton.tap()
        posterToggleButton.tap()
        
        XCTAssertEqual(mkvToggleButton.value as? String, "Not Selected", "MKV file should now be unselected.")
        XCTAssertEqual(posterToggleButton.value as? String, "Selected", "Poster file should now be selected.")
                
        let saveButton = app.buttons["save_files_button"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()
        
        XCTAssertTrue(filesSheet.waitForNonExistence(timeout: 5), "File list sheet did not dismiss after saving.")
        XCTAssertTrue(actionsView.exists, "Should return to the TorrentActionsView.")
    }
}

extension XCUIElementQuery {
    func matchingByIdentifier(_ identifier: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return self.matching(predicate)
    }
}