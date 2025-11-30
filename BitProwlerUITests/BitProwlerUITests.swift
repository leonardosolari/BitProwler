import XCTest

final class BitProwlerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testColdStartAndConfiguration() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()

        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 10), "La TabBar non è apparsa in tempo")
        XCTAssertTrue(searchTab.isSelected)
        
        let emptyState = app.descendants(matching: .any)["search_empty_state_no_server"].firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "La schermata di configurazione richiesta non è apparsa")
        
        let torrentTab = app.tabBars.buttons["Torrent"]
        torrentTab.tap()
        
        let torrentEmptyState = app.descendants(matching: .any)["torrents_error_view"].firstMatch
        XCTAssertTrue(torrentEmptyState.waitForExistence(timeout: 5), "La schermata vuota dei torrent non è apparsa")

        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        
        let prowlarrLink = app.buttons["link_prowlarr_servers"]
        XCTAssertTrue(prowlarrLink.waitForExistence(timeout: 5))
        prowlarrLink.tap()
        
        app.buttons["Add Server"].tap()
        
        let nameField = app.textFields["server_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        
        nameField.tap()
        nameField.typeText("My Mock Prowlarr")
        
        let urlField = app.textFields["server_url_field"]
        urlField.tap()
        urlField.typeText("http://prowlarr.local")
        
        let keyField = app.secureTextFields["server_apikey_field"]
        keyField.tap()
        keyField.typeText("1234567890")
        
        app.buttons["server_save_button"].tap()
        
        let serverCell = app.buttons["My Mock Prowlarr"]
        XCTAssertTrue(serverCell.waitForExistence(timeout: 2))
        
        app.navigationBars.buttons.firstMatch.tap()
        
        let qbLink = app.buttons["link_qbittorrent_servers"]
        XCTAssertTrue(qbLink.waitForExistence(timeout: 2))
        qbLink.tap()
        
        app.buttons["Add Server"].tap()
        
        let qbName = app.textFields["server_name_field"]
        XCTAssertTrue(qbName.waitForExistence(timeout: 2))
        
        qbName.tap()
        qbName.typeText("My Mock qBittorrent")
        
        let qbUrl = app.textFields["server_url_field"]
        qbUrl.tap()
        qbUrl.typeText("http://qb.local")
        
        let qbUser = app.textFields["server_username_field"]
        qbUser.tap()
        qbUser.typeText("admin")
        
        let qbPass = app.secureTextFields["server_password_field"]
        qbPass.tap()
        qbPass.typeText("password")
        
        app.buttons["server_save_button"].tap()
        
        XCTAssertTrue(app.staticTexts["My Mock qBittorrent"].waitForExistence(timeout: 2))
        
        app.navigationBars.buttons.firstMatch.tap()
        
        XCTAssertTrue(app.staticTexts["My Mock Prowlarr"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["My Mock qBittorrent"].exists)
    }
}