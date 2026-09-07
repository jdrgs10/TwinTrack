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
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(tabBar.buttons["Home"].isSelected)

        // Repeat the full cycle to catch navigation that works only on the first visit.
        for _ in 0..<3 {
            for title in ["TwinTrack AI", "Profile", "Home"] {
                let tab = tabBar.buttons[title]
                XCTAssertTrue(tab.exists)
                tab.tap()
                XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
                XCTAssertTrue(tab.isSelected)
                XCTAssertEqual(tabBar.buttons.count, 3)
            }
        }
    }
}
