import XCTest

/// Cross-feature integration with synthetic Health and isolated stores; not a model-quality test.
final class StudentJourneyUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run { XCUIDevice.shared.orientation = .portrait }
    }

    @MainActor
    func testSyntheticJourneyPredictionWhatIfTrendsChatEditExportAndRelaunch() throws {
        let app = launch()
        let run = app.buttons["runPrediction"]
        XCTAssertTrue(run.waitForExistence(timeout: 10))
        assertThreeTabs(in: app)

        openProfile(app)
        reveal(app.buttons["manualInputsButton"], in: app)
        app.buttons["manualInputsButton"].tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["v2Subject"].value as? String, "Synthetic maths")
        XCTAssertEqual(app.buttons["Study Time"].value as? String, "2h 0m")
        let confirmation = app.switches["v2ConfirmContext"]
        reveal(confirmation, in: app)
        XCTAssertEqual(confirmation.value as? String, "0", "Opening the form must not silently reconfirm inputs.")
        confirmation.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Manual details complete"].waitForExistence(timeout: 3))
        app.buttons["saveManualInputsButton"].tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForNonExistence(timeout: 5))

        tab("Home", in: app).tap()
        XCTAssertTrue(run.waitForExistence(timeout: 5))
        run.tap()
        let stateLine = app.staticTexts["homePredictionState"]
        expectLabel("Saved estimate · Inputs match", on: stateLine)
        XCTAssertFalse(run.exists, "Unchanged inputs must not offer a duplicate explicit run.")
        app.buttons["homePredictionDetails"].tap()
        let savedScore = element("historyDetailPrediction", in: app)
        XCTAssertTrue(savedScore.waitForExistence(timeout: 5))
        let savedScoreLabel = savedScore.label
        XCTAssertFalse(savedScoreLabel.isEmpty)
        XCTAssertEqual(app.staticTexts["historyModelVersion"].label, "TwinTrack Ridge V2 · 2.0-final.1")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Prediction Details"].waitForNonExistence(timeout: 5))
        let historyBeforeScenario = historyCount(in: app)

        tab("TwinTrack AI", in: app).tap()
        app.buttons["assistantManualWhatIf"].tap()
        let adjust = app.buttons["whatIfAdjust"]
        XCTAssertTrue(adjust.waitForExistence(timeout: 5))
        XCTAssertFalse(element("whatIfUnavailable", in: app).exists, "A just-saved complete baseline must support What-If.")
        reveal(adjust, in: app)
        adjust.tap()
        let increase = app.buttons["Increase scenario Study"]
        XCTAssertTrue(increase.waitForExistence(timeout: 5), "Expanding a valid scenario must expose its Study control.")
        reveal(increase, in: app)
        increase.tap()
        reveal(app.buttons["whatIfRun"], in: app)
        app.buttons["whatIfRun"].tap()
        let result = element("whatIfResult", in: app)
        reveal(result, in: app, direction: .down)
        XCTAssertTrue(result.exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["whatIfAdjust"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(historyCount(in: app), historyBeforeScenario, "What-If must not create a saved prediction.")

        openProfile(app)
        let trends = app.buttons["wellbeingTrendsButton"]
        reveal(trends, in: app)
        trends.tap()
        XCTAssertTrue(app.navigationBars["Trends & History"].waitForExistence(timeout: 5))
        let range = app.segmentedControls["wellbeingTrendRange"]
        XCTAssertTrue(range.waitForExistence(timeout: 5))
        XCTAssertTrue(range.buttons["7 days"].isSelected)
        range.buttons["30 days"].tap()
        XCTAssertTrue(range.buttons["30 days"].isSelected)
        XCTAssertEqual(app.staticTexts["wellbeingTrendCount"].label, "1 recorded observations")
        let missing = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "No recorded value")).firstMatch
        XCTAssertTrue(missing.exists)
        app.navigationBars.buttons.firstMatch.tap()

        openProfile(app)
        reveal(app.buttons["bodyWellbeingButton"], in: app)
        app.buttons["bodyWellbeingButton"].tap()
        XCTAssertTrue(app.navigationBars["Body & Wellbeing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["bmiEmptyState"].waitForExistence(timeout: 5))
        let editBody = app.buttons["editBodyMeasurements"]
        XCTAssertTrue(editBody.waitForExistence(timeout: 5))
        reveal(editBody, in: app)
        editBody.tap()
        XCTAssertTrue(app.navigationBars["Wellbeing Profile"].waitForExistence(timeout: 5))
        app.textFields["bodyHeight"].tap()
        app.textFields["bodyHeight"].typeText("160")
        app.textFields["bodyWeight"].tap()
        app.textFields["bodyWeight"].typeText("64")
        app.buttons["saveBodyMeasurements"].tap()
        XCTAssertTrue(app.navigationBars["Wellbeing Profile"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Body & Wellbeing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["bmiValue"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["bmiValue"].label, "25.0")
        let consent = app.switches["bodyAssistantConsent"]
        reveal(consent, in: app)
        XCTAssertEqual(consent.value as? String, "0")
        consent.tap()
        XCTAssertEqual(consent.value as? String, "1")
        consent.tap()
        XCTAssertEqual(consent.value as? String, "0")
        app.navigationBars.buttons.firstMatch.tap()

        openProfile(app)
        let ridge = app.staticTexts["Ridge Regression"]
        reveal(ridge, in: app)
        let foundation = app.staticTexts["Apple Foundation Models"]
        XCTAssertTrue(foundation.exists)
        XCTAssertLessThan(ridge.frame.minY, foundation.frame.minY)
        let appearance = app.segmentedControls["appearancePicker"]
        reveal(appearance, in: app)
        appearance.buttons["Dark"].tap()
        tab("TwinTrack AI", in: app).tap()
        let field = composer(in: app)
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "The first tap should focus the composer.")
        field.typeText("Synthetic journey conversation")
        app.buttons["assistantSend"].tap()
        XCTAssertTrue(app.staticTexts["assistantReplyMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        let original = app.staticTexts["Synthetic journey conversation"]
        original.press(forDuration: 1)
        app.buttons["Edit"].tap()
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Synthetic journey conversation".count) + "Edited synthetic journey")
        app.buttons["assistantEditSave"].tap()
        XCTAssertTrue(app.staticTexts["Edited synthetic journey"].waitForExistence(timeout: 5))
        XCTAssertFalse(original.exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        XCTAssertTrue(app.staticTexts["assistantReplyMessage"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantReplyMessage").count, 1)
        app.buttons["assistantChatOptions"].tap()
        app.buttons["Export Chat"].tap()
        dismissExport(in: app)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["homePredictionDetails"].waitForExistence(timeout: 10))
        app.buttons["homePredictionDetails"].tap()
        XCTAssertEqual(element("historyDetailPrediction", in: app).label, savedScoreLabel)
        app.buttons["Done"].tap()
        XCTAssertEqual(historyCount(in: app), historyBeforeScenario)
        tab("TwinTrack AI", in: app).tap()
        app.buttons["assistantLibrary"].tap()
        let savedChat = app.buttons.containing(.staticText, identifier: "Synthetic journey conversation").firstMatch
        XCTAssertTrue(savedChat.waitForExistence(timeout: 5))
        savedChat.tap()
        XCTAssertTrue(app.staticTexts["Edited synthetic journey"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Synthetic journey conversation"].exists)
        openProfile(app)
        reveal(appearance, in: app)
        XCTAssertTrue(appearance.buttons["Dark"].isSelected)
        assertThreeTabs(in: app)
    }

    @MainActor
    private func assertThreeTabs(in app: XCUIApplication) {
        var buttons = app.tabBars.firstMatch.buttons.allElementsBoundByIndex
        if buttons.isEmpty {
            // iPad duplicates each floating tab in accessibility and lacks a usable TabBar query.
            // Count all distinct controls in that row, including any unexpected fourth tab.
            let home = app.buttons.matching(identifier: "house.fill").firstMatch
            XCTAssertTrue(home.exists)
            let rowY = home.frame.midY
            var seen = Set<String>()
            buttons = app.buttons.allElementsBoundByIndex.filter { button in
                let frame = button.frame
                guard abs(frame.midY - rowY) < 1, frame.width > 0 else { return false }
                return seen.insert("\(button.label)|\(frame)").inserted
            }
        }
        XCTAssertEqual(buttons.count, 3)
        XCTAssertEqual(Set(buttons.map(\.label)), ["Home", "TwinTrack AI", "Profile"])
    }

    @MainActor
    func testSyntheticMissingHealthNeverBecomesZerosOrAReadyPrediction() throws {
        let app = launch(scenario: "missing-health")
        XCTAssertTrue(app.buttons["homePredictionDetails"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["runPrediction"].exists)
        openProfile(app)
        let review = app.buttons["healthPermissionsButton"]
        reveal(review, in: app)
        review.tap()
        XCTAssertTrue(app.navigationBars["Health Permissions"].waitForExistence(timeout: 5))
        let missing = app.staticTexts.matching(NSPredicate(format: "label == %@", "No accessible recent value")).firstMatch
        reveal(missing, in: app)
        XCTAssertTrue(missing.exists)
        XCTAssertFalse(app.staticTexts["Health permission denied"].exists)
        let refresh = app.buttons["Refresh"]
        reveal(refresh, in: app, direction: .down)
        refresh.tap()
        reveal(missing, in: app)
        XCTAssertTrue(missing.waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        tab("Home", in: app).tap()
        XCTAssertFalse(app.buttons["runPrediction"].exists)
    }

    @MainActor
    func testSyntheticMissingManualReviewDoesNotSilentlyConfirmOrSave() throws {
        let app = launch(scenario: "missing-manual")
        let update = app.buttons["homeUpdateManualInputs"]
        XCTAssertTrue(update.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["runPrediction"].exists)
        update.tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        let directedReview = element("manualReview.study", in: app)
        XCTAssertTrue(directedReview.waitForExistence(timeout: 5))
        XCTAssertTrue(directedReview.isHittable, "Directed entry must immediately reveal the missing Study field.")
        let cueText = ([directedReview.label] + directedReview.staticTexts.allElementsBoundByIndex.map(\.label)).joined(separator: " ")
        XCTAssertTrue(cueText.localizedCaseInsensitiveContains("study"), "The visible cue must explain which input needs review.")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "Reviewing an input must not auto-focus the keyboard.")
        let confirmation = app.switches["v2ConfirmContext"]
        reveal(confirmation, in: app)
        XCTAssertEqual(confirmation.value as? String, "0")
        // Saving an incomplete draft is allowed; only prediction eligibility is blocked.
        XCTAssertTrue(app.buttons["saveManualInputsButton"].isEnabled)
        reveal(app.staticTexts["manualEligibilityStatus"], in: app)
        XCTAssertEqual(app.staticTexts["manualEligibilityStatus"].label, "Prediction unavailable")
        app.buttons["Cancel"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(update.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["runPrediction"].exists)
        update.tap()
        XCTAssertEqual(app.buttons["Study Time"].value as? String, "Not entered")
        XCTAssertEqual(app.buttons["Recreational Screen Time"].value as? String, "Not entered")
        app.buttons["saveManualInputsButton"].tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(update.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["runPrediction"].exists, "Explicit partial Save must not invent missing inputs.")
    }

    @MainActor
    private func launch(scenario: String = "complete") -> XCUIApplication {
        let app = XCUIApplication(), session = UUID().uuidString
        // All stores share this synthetic session identity. V2 always supplies HealthDataProviding.
        app.launchArguments = ["--synthetic-v2-ui-tests", session,
            "--synthetic-profile-ui-tests", session, "--synthetic-appearance-ui-tests", session,
            "--synthetic-chat-ui-tests", "--synthetic-chat-export-ui-tests", "--synthetic-chat-library", session,
            "--synthetic-journey-scenario", scenario]
        app.launch()
        return app
    }

    @MainActor
    private func dismissExport(in app: XCUIApplication) {
        // UIKit adapts this native presentation between a sheet and an iPad popover.
        // Only dismiss controls are queried; no share destination is chosen.
        let popoverDismiss = app.otherElements["PopoverDismissRegion"]
        if popoverDismiss.waitForExistence(timeout: 5) {
            popoverDismiss.tap()
        } else if app.buttons["Close"].isHittable {
            app.buttons["Close"].tap()
        } else if app.buttons["Cancel"].isHittable {
            app.buttons["Cancel"].tap()
        } else {
            XCTFail("Native export presentation has no supported dismiss control; inspect this platform before extending the selector.")
            return
        }
        let returned = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["assistantChatOptions"])
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 5), .completed)
    }

    @MainActor
    private func historyCount(in app: XCUIApplication) -> String {
        openProfile(app)
        let privacy = app.buttons["dataPrivacyButton"]
        reveal(privacy, in: app)
        privacy.tap()
        let count = app.staticTexts["predictionHistoryCount"]
        reveal(count, in: app)
        let result = count.label
        app.navigationBars.buttons.firstMatch.tap()
        return result
    }

    @MainActor
    private func openProfile(_ app: XCUIApplication) {
        tab("Profile", in: app).tap()
        let title = app.staticTexts["pageTitle.Profile"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        reveal(title, in: app, direction: .down)
    }

    private enum Direction { case up, down }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, direction: Direction = .up) {
        for _ in 0..<14 {
            if element.isHittable { return }
            guard scrollContent(in: app, down: direction == .down) else { return }
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func scrollContent(in app: XCUIApplication, down: Bool) -> Bool {
        let candidates: [XCUIElement]
        if app.buttons["whatIfAdjust"].exists {
            // The presented scenario and underlying chat can both expose a ScrollView.
            candidates = app.scrollViews.containing(.button, identifier: "whatIfAdjust").allElementsBoundByIndex
        } else if app.scrollViews["assistantMessages"].exists {
            candidates = [app.scrollViews["assistantMessages"]]
        } else if app.scrollViews["homeScrollView"].exists {
            candidates = [app.scrollViews["homeScrollView"]]
        } else {
            candidates = app.scrollViews.allElementsBoundByIndex
                + app.collectionViews.allElementsBoundByIndex + app.tables.allElementsBoundByIndex
        }
        // A List's container need not itself be a hittable accessibility control.
        // Scroll its visible viewport; the requested destination must still become hittable.
        let visible = candidates.compactMap { content -> (XCUIElement, CGRect)? in
            let frame = content.frame.intersection(app.frame)
            guard !frame.isNull, frame.width > 80, frame.height > 100 else { return nil }
            return (content, frame)
        }
        guard let (content, viewport) = visible.max(by: {
            $0.1.width * $0.1.height < $1.1.width * $1.1.height
        }) else {
            XCTFail("No scroll container intersects the current destination viewport.")
            return false
        }
        var bounds = viewport
        let tabs = app.tabBars.firstMatch
        if tabs.exists, tabs.frame.minY > bounds.minY {
            bounds.size.height = min(bounds.height, tabs.frame.minY - bounds.minY)
        }
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists, keyboard.frame.minY > bounds.minY {
            bounds.size.height = min(bounds.height, keyboard.frame.minY - bounds.minY)
        }
        guard !bounds.isNull, bounds.height > 80 else {
            XCTFail("Scrollable content has no usable viewport.")
            return false
        }
        let origin = content.coordinate(withNormalizedOffset: .zero)
        let x = bounds.midX - content.frame.minX
        let startY = bounds.minY + bounds.height * (down ? 0.3 : 0.7) - content.frame.minY
        let endY = bounds.minY + bounds.height * (down ? 0.7 : 0.3) - content.frame.minY
        origin.withOffset(CGVector(dx: x, dy: startY)).press(forDuration: 0.05,
            thenDragTo: origin.withOffset(CGVector(dx: x, dy: endY)))
        return true
    }

    @MainActor
    private func tab(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.tabBars.buttons[title].exists ? app.tabBars.buttons[title] : app.buttons[title].firstMatch
    }

    @MainActor
    private func composer(in app: XCUIApplication) -> XCUIElement {
        app.textFields["assistantComposer"].exists ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func expectLabel(_ label: String, on element: XCUIElement) {
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: 10), .completed)
    }
}
