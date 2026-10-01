import XCTest

final class FocusedRegressionUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run { XCUIDevice.shared.orientation = .portrait }
    }

    @MainActor
    func testCompactHomeFreshSavedRefreshAndProfileRidgeCard() throws {
        let app = launch(large: false)
        let run = app.buttons["runPrediction"]
        XCTAssertTrue(run.waitForExistence(timeout: 10))
        run.tap()
        let status = app.staticTexts["homePredictionState"]
        let completedRun = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Saved estimate · Inputs match"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [completedRun], timeout: 10), .completed)
        XCTAssertFalse(run.exists)
        let inputs = app.staticTexts["TODAY'S INPUTS"]
        XCTAssertTrue(inputs.isHittable, "Today's Inputs must be visible without scrolling at standard size")
        let card = app.otherElements["homePredictionCard"]
        XCTAssertLessThan(card.frame.height, 320, "Standard saved result should be compact")
        print("FOCUSED Home saved card height: \(card.frame.height); inputs y: \(inputs.frame.minY)")
        app.scrollViews["homeScrollView"].swipeDown()
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        let matched = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Saved estimate · Inputs match"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [matched], timeout: 10), .completed)
        app.terminate(); app.launch()
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        app.buttons["homePredictionDetails"].tap()
        XCTAssertTrue(app.staticTexts["historyModelVersion"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["predictionCurrentInputDetails"].exists)
        app.buttons["Done"].tap()
        tab("Profile", app).tap()
        let ridgeText = app.staticTexts["Ridge Regression"]
        for _ in 0..<8 { if ridgeText.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(ridgeText.isHittable)
        let model = app.staticTexts["Apple Foundation Models"]
        XCTAssertTrue(model.exists)
        XCTAssertLessThan(ridgeText.frame.minY, model.frame.minY)
    }

    @MainActor
    func testHomeLightDarkAndLargestTypeDetailsReachable() throws {
        let app = launch(large: true)
        for mode in ["Light", "Dark"] {
            tab("Profile", app).tap()
            let picker = app.segmentedControls["appearancePicker"]
            for _ in 0..<20 { if picker.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(picker.isHittable); picker.buttons[mode].tap()
            tab("Home", app).tap()
            let details = app.buttons["homePredictionDetails"]
            for _ in 0..<12 { if details.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(details.isHittable)
            XCTAssertGreaterThanOrEqual(details.frame.height, 44)
            details.tap()
            XCTAssertTrue(app.navigationBars["Prediction Details"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["Done"].isHittable)
            app.buttons["Done"].tap()
            XCTAssertTrue(tab("Profile", app).isHittable)
        }
    }

    @MainActor
    func testUnavailableHomeHasActionableManualLinkAndNoDisabledRun() throws {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-profile-ui-tests", id]
        app.launch()
        let update = app.buttons["homeUpdateManualInputs"]
        XCTAssertTrue(update.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["runPrediction"].exists)
        update.tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(update.isHittable)
    }

    @MainActor
    private func launch(large: Bool) -> XCUIApplication {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", id, "--synthetic-profile-ui-tests", id,
                               "--synthetic-appearance-ui-tests", id]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }
    @MainActor
    private func tab(_ title: String, _ app: XCUIApplication) -> XCUIElement {
        app.tabBars.buttons[title].exists ? app.tabBars.buttons[title] : app.buttons[title].firstMatch
    }
}
