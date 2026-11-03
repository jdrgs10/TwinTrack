import XCTest

final class FinalProductPassUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run { XCUIDevice.shared.orientation = .portrait }
    }

    @MainActor
    func testSelectedHistoricalExplanationPreservesDraftAndReopensWithoutDuplicates() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["runPrediction"].waitForExistence(timeout: 10))
        app.buttons["runPrediction"].tap()
        let currentResult = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Saved estimate · Inputs match"),
            object: app.staticTexts["homePredictionState"])
        XCTAssertEqual(XCTWaiter.wait(for: [currentResult], timeout: 5), .completed,
            "Run must establish the current V2 result before opening its details.")
        XCTAssertTrue(app.buttons["homePredictionDetails"].waitForExistence(timeout: 5))
        app.buttons["homePredictionDetails"].tap()
        let currentScore = try decimalScore(from: element("historyDetailPrediction", in: app).label)
        XCTAssertEqual(app.staticTexts["historyModelVersion"].label, "TwinTrack Ridge V2 · 2.0-final.1")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Prediction Details"].waitForNonExistence(timeout: 5))

        tab("TwinTrack AI", in: app).tap()
        let field = composer(in: app)
        field.tap()
        field.typeText("Original synthetic conversation")
        app.buttons["assistantSend"].tap()
        XCTAssertTrue(app.staticTexts["assistantReplyMessage"].waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Unsent question to preserve")
        app.buttons["assistantDismissKeyboard"].tap()

        profileRoot(app)
        let trends = app.buttons["wellbeingTrendsButton"]
        reveal(trends, in: app)
        trends.tap()
        XCTAssertTrue(app.navigationBars["Trends & History"].waitForExistence(timeout: 5))
        let legacy = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Legacy assessment · Context not recorded")).firstMatch
        reveal(legacy, in: app)
        legacy.tap()
        XCTAssertTrue(app.navigationBars["Prediction Details"].waitForExistence(timeout: 5))
        let model = app.staticTexts["historyModelVersion"]
        XCTAssertTrue(model.waitForExistence(timeout: 5))
        XCTAssertTrue(model.label.contains("TwinTrack Ridge V1"))
        let selectedModel = model.label
        let selectedScore = try decimalScore(from: element("historyDetailPrediction", in: app).label)
        let explain = app.buttons["explainSavedEstimate"]
        reveal(explain, in: app)
        explain.tap()
        XCTAssertTrue(app.navigationBars["Prediction Details"].waitForNonExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["pageTitle.TwinTrack AI"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Prediction Details"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        XCTAssertNotEqual(composer(in: app).value as? String, "Unsent question to preserve")
        let card = element("assistantResultCard.history", in: app)
        reveal(card, in: app, down: true)
        XCTAssertTrue(card.staticTexts[selectedScore].exists, {
            let children = card.staticTexts.allElementsBoundByIndex.map { "\($0.identifier): \($0.label)" }
            return "The card must show the selected historical score. Synthetic diagnostic: matched type=\(card.elementType.rawValue), exact-score text count=\(app.staticTexts.matching(NSPredicate(format: "label == %@", selectedScore)).count), children=\(children)"
        }())
        let sources = card.buttons["Inputs and source details"]
        reveal(sources, in: app)
        sources.tap()
        let storedModel = card.staticTexts[selectedModel]
        reveal(storedModel, in: app)
        XCTAssertTrue(storedModel.isHittable, "The older V1 record must not be substituted with current V2.")
        let back = app.buttons["returnFromSavedExplanation"]
        reveal(back, in: app, down: true)
        back.tap()
        XCTAssertEqual(composer(in: app).value as? String, "Unsent question to preserve")
        XCTAssertTrue(app.staticTexts["Original synthetic conversation"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        composer(in: app).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        app.buttons["assistantDismissKeyboard"].tap()

        app.buttons["assistantLibrary"].tap()
        let explanations = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Saved estimate ·"))
        XCTAssertTrue(explanations.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(explanations.count, 1, "One Explain action must create one conversation.")
        let explanationTitle = explanations.firstMatch.label
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Chat Library"].waitForNonExistence(timeout: 5))
        tab("Home", in: app).tap()
        app.buttons["homePredictionDetails"].tap()
        XCTAssertEqual(try decimalScore(from: element("historyDetailPrediction", in: app).label), currentScore)
        XCTAssertEqual(app.staticTexts["historyModelVersion"].label, "TwinTrack Ridge V2 · 2.0-final.1")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Prediction Details"].waitForNonExistence(timeout: 5))
        profileRoot(app)
        let privacy = app.buttons["dataPrivacyButton"]
        reveal(privacy, in: app)
        privacy.tap()
        let historyCount = app.staticTexts["predictionHistoryCount"]
        reveal(historyCount, in: app)
        XCTAssertEqual(historyCount.label, "2 saved predictions", "Explaining a record cannot create a prediction.")

        app.terminate()
        app.launch()
        tab("TwinTrack AI", in: app).tap()
        app.buttons["assistantLibrary"].tap()
        let savedTitle = app.staticTexts[explanationTitle]
        XCTAssertTrue(savedTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(explanations.count, 1)
        savedTitle.tap()
        XCTAssertTrue(app.navigationBars["Chat Library"].waitForNonExistence(timeout: 5))
        let reopenedCard = element("assistantResultCard.history", in: app)
        reveal(reopenedCard, in: app, down: true)
        XCTAssertTrue(reopenedCard.staticTexts[selectedScore].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantReplyMessage").count, 1)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testComposerLightDarkFocusAndDraftSurviveTabReturn() throws {
        try checkComposer(large: false)
    }

    @MainActor
    func testComposerLightDarkLargestTextFocusAndControlsRemainReachable() throws {
        try checkComposer(large: true)
    }

    @MainActor
    func testDarkComposerSendStopAndRetryPreserveNewDraft() throws {
        let app = launch(slow: true)
        setAppearance("Dark", in: app)
        tab("TwinTrack AI", in: app).tap()
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        let field = composer(in: app)
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        field.typeText("Synthetic pending response")
        app.buttons["assistantSend"].tap()
        let stop = app.buttons["assistantStop"]
        XCTAssertTrue(stop.waitForExistence(timeout: 3))
        XCTAssertTrue(stop.isHittable)
        XCTAssertGreaterThanOrEqual(stop.frame.height + 1e-6, 44, "44-point target, allowing only floating-point rounding.")
        XCTAssertNotEqual(field.value as? String, "Synthetic pending response")
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        stop.tap()
        let retry = app.buttons["assistantRetry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 3))
        retry.tap()
        XCTAssertTrue(stop.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("New unsent draft")
        app.buttons["assistantDismissKeyboard"].tap()
        tab("Home", in: app).tap()
        tab("TwinTrack AI", in: app).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        XCTAssertEqual(composer(in: app).value as? String, "New unsent draft")
        XCTAssertFalse(stop.exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
    }

    @MainActor
    private func checkComposer(large: Bool) throws {
        let app = launch(large: large)
        for mode in ["Light", "Dark"] {
            setAppearance(mode, in: app)
            tab("TwinTrack AI", in: app).tap()
            XCTAssertTrue(app.staticTexts["pageTitle.TwinTrack AI"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
            let field = composer(in: app)
            XCTAssertTrue(field.isHittable)
            field.tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "A single tap must focus in \(mode).")
            let draft = "Unsent \(mode) draft"
            field.typeText(draft)
            XCTAssertEqual(field.value as? String, draft)
            let send = app.buttons["assistantSend"]
            XCTAssertTrue(send.isEnabled)
            XCTAssertTrue(send.isHittable)
            XCTAssertGreaterThanOrEqual(send.frame.height + 1e-6, 44, "44-point target, allowing only floating-point rounding.")
            let dismiss = app.buttons["assistantDismissKeyboard"]
            XCTAssertTrue(dismiss.isHittable)
            XCTAssertGreaterThanOrEqual(dismiss.frame.height + 1e-6, 44, "44-point target, allowing only floating-point rounding.")
            dismiss.tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
            XCTAssertTrue(app.buttons["assistantManualWhatIf"].isHittable)
            tab("Home", in: app).tap()
            tab("TwinTrack AI", in: app).tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "Returning must not auto-focus.")
            XCTAssertEqual(composer(in: app).value as? String, draft)
            composer(in: app).tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "The first tap after return must work.")
            app.buttons["assistantSend"].tap()
            XCTAssertTrue(app.staticTexts["assistantReplyMessage"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
            XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
            app.buttons["assistantNewChat"].tap()
        }
    }

    @MainActor
    private func launch(large: Bool = false, slow: Bool = false) -> XCUIApplication {
        let app = XCUIApplication(), session = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", session, "--synthetic-profile-ui-tests", session,
            "--synthetic-appearance-ui-tests", session, "--synthetic-chat-library", session,
            "--synthetic-chat-ui-tests", "--synthetic-chat-export-ui-tests"]
        if slow { app.launchArguments += ["--synthetic-chat-slow-error"] }
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    @MainActor
    private func setAppearance(_ mode: String, in app: XCUIApplication) {
        profileRoot(app)
        let picker = app.segmentedControls["appearancePicker"]
        reveal(picker, in: app)
        picker.buttons[mode].tap()
    }

    @MainActor
    private func profileRoot(_ app: XCUIApplication) {
        tab("Profile", in: app).tap()
        let title = app.staticTexts["pageTitle.Profile"]
        for _ in 0..<3 {
            if title.exists { break }
            let back = app.navigationBars.buttons.firstMatch
            guard back.isHittable else { break }
            back.tap()
        }
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        reveal(title, in: app, down: true)
    }

    @MainActor
    private func reveal(_ target: XCUIElement, in app: XCUIApplication, down: Bool = false,
                        file: StaticString = #filePath, line: UInt = #line) {
        func visibleAboveComposer() -> Bool {
            guard target.isHittable else { return false }
            // A result-card container may extend past the viewport; its specific
            // actionable descendants are checked separately before interaction.
            guard target.elementType != .other,
                  app.scrollViews["assistantMessages"].exists else { return true }
            let field = composer(in: app)
            // XCTest can call an inset-covered disclosure hittable. Require its
            // visible bounds above its 10-point top + 12-point field padding.
            return !field.exists || target.frame.maxY <= field.frame.minY - 22
        }
        for _ in 0..<16 {
            if visibleAboveComposer() { return }
            guard scrollContent(in: app, down: down) else { return }
        }
        XCTAssertTrue(visibleAboveComposer(), "The requested control must be visible above the chat composer.", file: file, line: line)
    }

    @MainActor
    private func decimalScore(from label: String) throws -> String {
        let pattern = try NSRegularExpression(pattern: #"\d+\.\d"#)
        let match = try XCTUnwrap(pattern.firstMatch(in: label, range: NSRange(label.startIndex..., in: label)))
        return String(label[try XCTUnwrap(Range(match.range, in: label))])
    }

    @MainActor
    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor
    private func composer(in app: XCUIApplication) -> XCUIElement {
        app.textFields["assistantComposer"].exists ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
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
        if app.scrollViews["assistantMessages"].exists {
            let field = composer(in: app)
            if field.exists, field.frame.minY > bounds.minY {
                bounds.size.height = min(bounds.height, field.frame.minY - 22 - bounds.minY)
            }
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
}
