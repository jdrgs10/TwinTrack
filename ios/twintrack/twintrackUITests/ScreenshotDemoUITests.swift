import XCTest

final class ScreenshotDemoUITests: XCTestCase {
    @MainActor
    func testScreenshotReadingsManualAccessRefreshAndDisable() throws {
        continueAfterFailure = false
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--screenshot-mode", "--screenshot-session", id,
                               "--synthetic-profile-ui-tests", id]
        app.launch()
        let home = app.scrollViews["homeScrollView"]
        XCTAssertTrue(home.waitForExistence(timeout: 10))
        for (metric, value) in [("Sleep", "7h 42m"), ("Steps", "7,850"), ("Exercise", "42 min"), ("Resting Heart Rate", "62 bpm")] {
            let reading = home.descendants(matching: .any).matching(
                NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", metric, value)).firstMatch
            for _ in 0..<5 { if reading.isHittable { break }; home.swipeUp() }
            XCTAssertTrue(reading.isHittable, value)
        }
        for _ in 0..<5 { if app.staticTexts["pageTitle.Home"].isHittable { break }; home.swipeDown() }
        home.swipeDown()
        XCTAssertFalse(app.buttons["runPrediction"].exists)
        let manual = app.buttons["homeUpdateManualInputs"]
        XCTAssertTrue(manual.isHittable); manual.tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Study Time"].isEnabled)
        XCTAssertTrue(app.buttons["Recreational Screen Time"].isEnabled)
        app.buttons["Cancel"].tap()
        app.terminate()
        // Disabling the flag uses the normal, isolated empty test state again.
        app.launchArguments = ["--synthetic-profile-ui-tests", id]
        app.launch()
        XCTAssertTrue(app.scrollViews["homeScrollView"].waitForExistence(timeout: 10))
        for value in ["7h 42m", "7,850", "42 min", "62 bpm"] {
            XCTAssertFalse(home.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", value)).firstMatch.exists)
        }
    }
}
