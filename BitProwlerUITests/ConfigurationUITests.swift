import XCTest

@MainActor
final class ConfigurationUITests: BitProwlerUITestsBase {

    func testColdStartAndFullConfiguration() throws {
        launch(scenario: .coldStart, servers: .none)

        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 10), "La TabBar non è apparsa in tempo")
        XCTAssertTrue(searchTab.isSelected)
        
        let emptyState = app.descendants(matching: .any)["search_empty_state_no_server"].firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "La schermata di configurazione richiesta non è apparsa")
        
        let torrentTab = app.tabBars.buttons["Torrent"]
        torrentTab.tap()
        
        let torrentEmptyState = app.descendants(matching: .any)["torrents_error_view"].firstMatch
        XCTAssertTrue(torrentEmptyState.waitForExistence(timeout: 5), "La schermata di errore dei torrent non è apparsa")

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
        
        let serverCell = app.cells.containing(.staticText, identifier: "My Mock Prowlarr").firstMatch
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
        
        XCTAssertTrue(app.cells.containing(.staticText, identifier: "My Mock qBittorrent").firstMatch.waitForExistence(timeout: 2))
        
        app.navigationBars.buttons.firstMatch.tap()
        
        XCTAssertTrue(app.staticTexts["My Mock Prowlarr"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["My Mock qBittorrent"].exists)
    }

    func testEditAndVerifyServers() throws {
        launch(scenario: .searchSuccessWithResults, servers: .all, mockDataFile: "search-success")

        app.tabBars.buttons["Settings"].tap()

        let prowlarrLink = app.buttons["link_prowlarr_servers"]
        XCTAssertTrue(prowlarrLink.waitForExistence(timeout: 5))
        prowlarrLink.tap()

        let originalProwlarrServerCell = app.cells.containing(.staticText, identifier: "Mock Prowlarr").firstMatch
        XCTAssertTrue(originalProwlarrServerCell.waitForExistence(timeout: 2))
        originalProwlarrServerCell.tap()

        let nameField = app.textFields["server_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        
        nameField.tap()
        guard let originalName = nameField.value as? String else {
            XCTFail("Impossibile ottenere il valore originale del nome del server")
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: originalName.count)
        nameField.typeText(deleteString)
        nameField.typeText("Edited Prowlarr")

        app.buttons["server_save_button"].tap()

        XCTAssertTrue(app.cells.containing(.staticText, identifier: "Edited Prowlarr").firstMatch.waitForExistence(timeout: 2))
        XCTAssertFalse(originalProwlarrServerCell.exists)
        
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Edited Prowlarr"].waitForExistence(timeout: 2))

        let qbLink = app.buttons["link_qbittorrent_servers"]
        XCTAssertTrue(qbLink.waitForExistence(timeout: 2))
        qbLink.tap()

        let originalQbServerCell = app.cells.containing(.staticText, identifier: "Mock qBittorrent").firstMatch
        XCTAssertTrue(originalQbServerCell.waitForExistence(timeout: 2))
        originalQbServerCell.tap()

        let qbNameField = app.textFields["server_name_field"]
        XCTAssertTrue(qbNameField.waitForExistence(timeout: 2))

        qbNameField.tap()
        guard let originalQbName = qbNameField.value as? String else {
            XCTFail("Impossibile ottenere il valore originale del nome del server qBittorrent")
            return
        }
        let qbDeleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: originalQbName.count)
        qbNameField.typeText(qbDeleteString)
        qbNameField.typeText("Edited qBittorrent")

        app.buttons["server_save_button"].tap()

        XCTAssertTrue(app.cells.containing(.staticText, identifier: "Edited qBittorrent").firstMatch.waitForExistence(timeout: 2))
        XCTAssertFalse(originalQbServerCell.exists)
        
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Edited qBittorrent"].waitForExistence(timeout: 2))
    }
}