import XCTest

final class twintrackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testThreeTabShell() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        XCTAssertEqual(tabBar.buttons.count, 3)
        XCTAssertTrue(app.staticTexts["pageTitle.Home"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["pageTitle.Home"].label, "Home")
        XCTAssertTrue(app.staticTexts["Your habits. Your data. Your academic twin."].exists)
        XCTAssertTrue(tabBar.buttons["Home"].isSelected)

        // Repeat the full cycle to catch navigation that works only on the first visit.
        for _ in 0..<3 {
            for title in ["TwinTrack AI", "Profile", "Home"] {
                let tab = tabBar.buttons[title]
                XCTAssertTrue(tab.exists)
                tab.tap()
                // Headers now live in scroll content so they can grow with Dynamic Type.
                let header = app.staticTexts["pageTitle.\(title)"]
                XCTAssertTrue(header.waitForExistence(timeout: 5))
                XCTAssertEqual(header.label, title)
                XCTAssertTrue(tab.isSelected)
                XCTAssertEqual(tabBar.buttons.count, 3)
            }
        }
    }

    @MainActor
    func testWhatIfUnavailableBaselineAndTabExit() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        XCTAssertTrue(app.staticTexts["pageTitle.TwinTrack AI"].waitForExistence(timeout: 5))
        // The simulator has no complete HealthKit baseline; never seed production data.
        let unavailable = app.otherElements["whatIfUnavailable"]
        let unavailableText = app.staticTexts["What-If unavailable"]
        XCTAssertTrue(unavailable.exists || unavailableText.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["whatIfRun"].exists)
        XCTAssertFalse(app.buttons["whatIfRun"].isEnabled)
        XCTAssertFalse(app.otherElements["whatIfResult"].exists)
        XCTAssertTrue(app.staticTexts["whatIfDisclaimer"].exists)
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["pageTitle.Home"].waitForExistence(timeout: 5))
        app.tabBars.buttons["TwinTrack AI"].tap()
        XCTAssertFalse(app.buttons["whatIfRun"].isEnabled)
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
    }

    @MainActor
    func testHomePullToRefreshAndBottomAction() throws {
        let app = XCUIApplication()
        app.launch()
        let home = app.scrollViews["homeScrollView"]
        XCTAssertTrue(home.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Refresh"].exists)
        home.swipeDown()
        XCTAssertTrue(app.staticTexts["pageTitle.Home"].exists)

        let openAI = app.buttons["openTwinTrackAI"]
        for _ in 0..<8 {
            if openAI.isHittable { break }
            home.swipeUp()
        }
        XCTAssertTrue(openAI.isHittable, "The last Home button must be reachable above the tab bar.")
        openAI.tap()
        XCTAssertTrue(app.staticTexts["pageTitle.TwinTrack AI"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["TwinTrack AI"].isSelected)
        XCTAssertTrue(app.staticTexts["Ask questions. Explore scenarios. Understand your twin."].exists)
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Your data. Your preferences. Your control."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPredictionHistoryHonestEmptyState() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        let privacy = app.buttons["dataPrivacyButton"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 10))
        privacy.tap()

        XCTAssertTrue(app.navigationBars["Data & Privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No saved predictions"].exists)
        XCTAssertFalse(app.buttons["clearPredictionHistoryButton"].isEnabled)

        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["7-DAY TREND"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No prediction history yet"].exists)
        XCTAssertFalse(app.otherElements["predictionTrendChart"].exists)
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
    }
}
