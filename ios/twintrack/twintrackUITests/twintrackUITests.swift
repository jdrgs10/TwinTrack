import XCTest

final class twintrackUITests: XCTestCase {

    @MainActor
    func testSendClearsImmediatelyAndLateFailurePreservesNewDraft() throws {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-chat-ui-tests", "--synthetic-chat-slow-error",
                               "--synthetic-chat-library", id, "--synthetic-profile-ui-tests", id]
        app.launch(); app.tabBars.buttons["TwinTrack AI"].tap()
        let field = app.textFields["assistantComposer"].exists ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        field.tap(); field.typeText("Synthetic pending request")
        app.buttons["assistantSend"].tap()
        XCTAssertTrue(app.buttons["assistantStop"].waitForExistence(timeout: 3))
        XCTAssertNotEqual(field.value as? String, "Synthetic pending request")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        field.tap(); field.typeText("New draft")
        XCTAssertTrue(app.buttons["assistantRetry"].waitForExistence(timeout: 20))
        XCTAssertEqual(field.value as? String, "New draft")
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        app.buttons["assistantDismissKeyboard"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].isHittable)
    }

    @MainActor
    func testTrendsHistoryLightDarkLargestTextAndTabReachability() throws {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-profile-ui-tests", id, "--synthetic-v2-ui-tests", id,
                               "--synthetic-appearance-ui-tests", id,
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        for mode in ["Light", "Dark"] {
            let profile = app.tabBars.buttons["Profile"].exists ? app.tabBars.buttons["Profile"] : app.buttons["Profile"].firstMatch
            profile.tap()
            let appearance = app.segmentedControls["appearancePicker"]
            for _ in 0..<20 { if appearance.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(appearance.isHittable); appearance.buttons[mode].tap()
            let trends = app.buttons["wellbeingTrendsButton"]
            for _ in 0..<20 { if trends.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(trends.isHittable); trends.tap()
            let range = app.segmentedControls["wellbeingTrendRange"]
            for _ in 0..<8 { if range.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(range.isHittable)
            XCTAssertTrue(range.buttons["7 days"].isSelected)
            range.buttons["30 days"].tap()
            XCTAssertTrue(range.buttons["30 days"].isSelected)
            XCTAssertEqual(app.staticTexts["wellbeingTrendCount"].label, "0 recorded observations")
            let footer = app.staticTexts["Body & Wellbeing keeps your latest saved measurements only. No body-measurement history is inferred from predictions or chat."]
            for _ in 0..<45 { if footer.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(footer.isHittable, "Last content must scroll clear of the tab bar")
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    func testBodyWellbeingEmptySaveEditCancelRelaunchAndRemove() throws {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-profile-ui-tests", id, "--synthetic-v2-ui-tests", id]
        func openBody() {
            let profile = app.tabBars.buttons["Profile"].exists ? app.tabBars.buttons["Profile"] : app.buttons["Profile"].firstMatch
            profile.tap()
            let link = app.buttons["bodyWellbeingButton"]
            for _ in 0..<6 { if link.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(link.isHittable); link.tap()
            XCTAssertTrue(app.buttons["editBodyMeasurements"].waitForExistence(timeout: 5))
        }
        app.launch(); openBody()
        XCTAssertTrue(app.staticTexts["bmiEmptyState"].exists)
        app.buttons["editBodyMeasurements"].tap()
        XCTAssertFalse(app.buttons["saveBodyMeasurements"].isEnabled)
        app.textFields["bodyHeight"].tap(); app.textFields["bodyHeight"].typeText("160")
        app.textFields["bodyWeight"].tap(); app.textFields["bodyWeight"].typeText("64")
        XCTAssertEqual(app.staticTexts["bmiDraftValue"].label, "BMI: 25.0")
        app.buttons["saveBodyMeasurements"].tap()
        XCTAssertEqual(app.staticTexts["bmiValue"].label, "25.0")
        XCTAssertTrue(app.staticTexts["bmiCategoryUnavailable"].exists)
        let consent = app.switches["bodyAssistantConsent"]
        for _ in 0..<8 { if consent.isHittable { break }; app.swipeUp() }
        XCTAssertEqual(consent.value as? String, "0")
        consent.tap()
        XCTAssertEqual(consent.value as? String, "1")
        for _ in 0..<8 { if app.buttons["editBodyMeasurements"].isHittable { break }; app.swipeDown() }
        app.buttons["editBodyMeasurements"].tap()
        let height = app.textFields["bodyHeight"]
        height.tap()
        let count = (height.value as? String)?.count ?? 0
        height.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count) + "200")
        app.buttons["cancelBodyMeasurements"].tap()
        XCTAssertEqual(app.staticTexts["bmiValue"].label, "25.0")
        app.buttons["editBodyMeasurements"].tap()
        height.tap()
        height.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (height.value as? String)?.count ?? 0) + "200")
        app.buttons["saveBodyMeasurements"].tap()
        XCTAssertEqual(app.staticTexts["bmiValue"].label, "16.0")
        app.terminate(); app.launch(); openBody()
        XCTAssertEqual(app.staticTexts["bmiValue"].label, "16.0")
        for _ in 0..<8 { if consent.isHittable { break }; app.swipeUp() }
        XCTAssertEqual(consent.value as? String, "1")
        consent.tap()
        XCTAssertEqual(consent.value as? String, "0")
        let remove = app.buttons["removeBodyMeasurements"]
        for _ in 0..<6 { if remove.isHittable { break }; app.swipeUp() }
        remove.tap()
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["bmiValue"].exists)
        remove.tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Remove Wellbeing Profile", "removeBodyMeasurements")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["bmiEmptyState"].exists)
    }

    @MainActor
    func testBodyWellbeingLightDarkAndLargestText() throws {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-profile-ui-tests", id, "--synthetic-v2-ui-tests", id,
                               "--synthetic-appearance-ui-tests", id,
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        for mode in ["Light", "Dark"] {
            let profile = app.tabBars.buttons["Profile"].exists ? app.tabBars.buttons["Profile"] : app.buttons["Profile"].firstMatch
            profile.tap()
            let picker = app.segmentedControls["appearancePicker"]
            for _ in 0..<20 { if picker.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(picker.isHittable); picker.buttons[mode].tap()
            let body = app.buttons["bodyWellbeingButton"]
            for _ in 0..<20 { if body.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(body.isHittable); body.tap()
            let gauge = app.otherElements["bmiGauge"]
            XCTAssertTrue(gauge.waitForExistence(timeout: 5))
            XCTAssertEqual(gauge.value as? String, "No measurements")
            let edit = app.buttons["editBodyMeasurements"]
            for _ in 0..<8 { if edit.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(edit.isHittable); edit.tap()
            XCTAssertTrue(app.buttons["cancelBodyMeasurements"].isHittable)
            let birthField = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Add date of birth")).firstMatch
            for _ in 0..<8 { if birthField.exists { break }; app.swipeUp() }
            XCTAssertTrue(birthField.exists)
            let sexField = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Sex used by CDC growth reference")).firstMatch
            for _ in 0..<8 { if sexField.exists { break }; app.swipeUp() }
            XCTAssertTrue(sexField.exists)
            app.buttons["cancelBodyMeasurements"].tap()
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    func testCurrentProfileDoesNotPresentRewardsAsAvailable() throws {
        let app = XCUIApplication(), id = UUID().uuidString
        app.launchArguments = ["--synthetic-profile-ui-tests", id, "--synthetic-v2-ui-tests", id]
        app.launch()
        let profile = app.tabBars.buttons["Profile"].exists ? app.tabBars.buttons["Profile"] : app.buttons["Profile"].firstMatch
        profile.tap()
        XCTAssertFalse(app.staticTexts["Rewards"].exists)
        XCTAssertFalse(app.buttons["Rewards"].exists)
        XCTAssertFalse(app.staticTexts["Badges"].exists)
        XCTAssertFalse(app.buttons["Badges"].exists)
        XCTAssertFalse(app.staticTexts["Points"].exists)
        XCTAssertFalse(app.buttons["Points"].exists)
    }


    @MainActor
    func testExportCurrentAndSavedChatCancelPreservesConversation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests", "--synthetic-chat-export-ui-tests",
                               "--synthetic-chat-library", UUID().uuidString,
                               "--synthetic-profile-ui-tests", UUID().uuidString]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        app.buttons["assistantChatOptions"].tap()
        XCTAssertFalse(app.buttons["Export Chat"].isEnabled)
        app.tap()
        let field = app.textFields["assistantComposer"].exists ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        field.tap()
        field.typeText("Synthetic export test")
        app.buttons["assistantSend"].tap()
        XCTAssertTrue(app.staticTexts["assistantReplyMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        app.buttons["assistantChatOptions"].tap()
        app.buttons["Export Chat"].tap()
        let dismissShare = app.otherElements["PopoverDismissRegion"]
        XCTAssertTrue(dismissShare.waitForExistence(timeout: 5), "Native share panel must open.")
        dismissShare.tap()
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantReplyMessage").count, 1)
        app.buttons["assistantLibrary"].tap()
        app.buttons["Chat options for Synthetic export test"].tap()
        app.buttons["Export Chat"].tap()
        XCTAssertTrue(dismissShare.waitForExistence(timeout: 5))
        dismissShare.tap()
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        app.buttons["assistantLibrary"].tap()
        app.buttons.containing(.staticText, identifier: "Synthetic export test").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["assistantReplyMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["assistantUserMessage"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantReplyMessage").count, 1)
    }

    @MainActor
    func testAssistantBuildMarkerIsVisibleInAbout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests"]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        app.buttons["About on-device chat"].tap()
        let build = app.staticTexts["assistantBuild"]
        XCTAssertTrue(build.waitForExistence(timeout: 5))
        XCTAssertEqual(build.label, "Build · FMQ-2026-09-24-A")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["assistantNewChat"].isHittable)
    }

    @MainActor
    func testAccessibleChatComposerAndTabsAtLargeDynamicType() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        XCTAssertFalse(app.buttons["assistantSend"].isEnabled)
        let field = app.textFields["assistantComposer"].exists
            ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        XCTAssertTrue(field.isHittable)
        field.tap()
        field.typeText("Synthetic accessibility check")
        XCTAssertTrue(app.buttons["assistantSend"].isEnabled)
        XCTAssertTrue(app.buttons["assistantDismissKeyboard"].isHittable)
        app.buttons["assistantDismissKeyboard"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["assistantManualWhatIf"].isHittable)
        XCTAssertLessThanOrEqual(app.buttons["assistantManualWhatIf"].frame.maxY, app.tabBars.firstMatch.frame.minY)
        for title in ["Home", "Profile", "TwinTrack AI"] {
            XCTAssertTrue(app.tabBars.buttons[title].isHittable)
            app.tabBars.buttons[title].tap()
            XCTAssertTrue(app.staticTexts["pageTitle.\(title)"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testChatKeyboardEscapeWithShortContentAndTabNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests"]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        let field = app.textFields["assistantComposer"].exists
            ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        field.tap()
        field.typeText("Short draft")
        let dismiss = app.buttons["assistantDismissKeyboard"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 5))
        XCTAssertTrue(dismiss.isHittable)
        dismiss.tap()
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        app.buttons["assistantLibrary"].tap()
        app.navigationBars["Chat Library"].buttons["New Chat"].tap()
        XCTAssertFalse(app.buttons["assistantSend"].isEnabled, "Library New Chat must discard an unsent draft too.")
        XCTAssertTrue(app.tabBars.buttons["Home"].isHittable)
        for title in ["Home", "Profile", "TwinTrack AI"] {
            app.tabBars.buttons[title].tap()
            XCTAssertTrue(app.staticTexts["pageTitle.\(title)"].waitForExistence(timeout: 5))
            for other in ["Home", "Profile", "TwinTrack AI"] where other != title {
                XCTAssertFalse(app.staticTexts["pageTitle.\(other)"].exists)
            }
        }
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
        XCTAssertTrue(app.buttons["assistantManualWhatIf"].isHittable)
        app.buttons["assistantManualWhatIf"].tap()
        XCTAssertTrue(app.buttons["whatIfRun"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    @MainActor
    func testFirstEntryTimingWithRealAvailabilityAndIsolatedHistory() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--assistant-performance-audit", "--synthetic-chat-library", UUID().uuidString,
                               "--synthetic-profile-ui-tests", UUID().uuidString]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        let field = app.textFields["assistantComposer"].exists ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        let began = ProcessInfo.processInfo.systemUptime
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        print("AUDIT UI tap-and-keyboard-wait seconds: \(ProcessInfo.processInfo.systemUptime - began)")
        field.typeText("Synthetic typing without generation")
        XCTAssertEqual(field.value as? String, "Synthetic typing without generation")
        app.buttons["assistantDismissKeyboard"].tap()
        app.buttons["About on-device chat"].tap()
        app.buttons["Performance timings (DEBUG)"].tap()
        let timings = app.staticTexts["assistantPerformanceTimings"]
        XCTAssertTrue(timings.waitForExistence(timeout: 3))
        print("AUDIT TIMINGS\n" + timings.label)
        XCTAssertTrue(timings.label.contains("composerFocused"))
        XCTAssertTrue(timings.label.contains("keyboardVisible"))
        XCTAssertTrue(timings.label.contains("keyboardWillShow"))
        XCTAssertTrue(timings.label.contains("historyLoad"))
        XCTAssertFalse(timings.label.contains("sessionInit"), "Typing must not initialize a model session.")
    }

    @MainActor
    func testAssistantComposerFocusesOnFirstTap() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests"]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        let field = app.textFields["assistantComposer"].exists
            ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]

        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3),
                      "One tap on the visible composer must focus it and show the keyboard.")
        field.typeText("First tap accepted")
        XCTAssertEqual(field.value as? String, "First tap accepted")
        app.buttons["assistantDismissKeyboard"].tap()
        app.tabBars.buttons["Home"].tap()
        app.tabBars.buttons["TwinTrack AI"].tap()
        let reopenedField = app.textFields["assistantComposer"].exists
            ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        reopenedField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3),
                      "Returning to the chat must also focus the composer on the first tap.")
    }

    @MainActor
    func testUserMessageEditCancelAndSave() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests", "--synthetic-chat-library", UUID().uuidString]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        let field = app.textFields["assistantComposer"].exists
            ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        field.tap()
        field.typeText("Original editable message")
        app.buttons["assistantSend"].tap()
        let original = app.staticTexts["Original editable message"]
        XCTAssertTrue(original.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Synthetic response:")).firstMatch.waitForExistence(timeout: 5))
        if app.buttons["assistantDismissKeyboard"].exists { app.buttons["assistantDismissKeyboard"].tap() }

        original.press(forDuration: 1)
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3))
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["assistantEditCancel"].waitForExistence(timeout: 3))
        XCTAssertEqual(field.value as? String, "Original editable message")
        app.buttons["assistantEditCancel"].tap()
        XCTAssertTrue(original.exists)

        original.press(forDuration: 1)
        app.buttons["Edit"].tap()
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue,
                              count: "Original editable message".count) + "Edited message")
        app.buttons["assistantEditSave"].tap()

        XCTAssertTrue(app.staticTexts["Edited message"].waitForExistence(timeout: 5))
        XCTAssertFalse(original.exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantUserMessage").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantReplyMessage").count, 1)
    }

    @MainActor
    func testChatLibraryRenameDeleteConfirmationAndNewChat() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests", "--synthetic-chat-library", UUID().uuidString]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        let field = app.textFields["assistantComposer"].exists
            ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        field.tap()
        field.typeText("Synthetic plan")
        app.buttons["assistantSend"].tap()
        let response = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Synthetic response:")).firstMatch
        XCTAssertTrue(response.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["How can I help?"].exists)
        XCTAssertFalse(app.staticTexts["Ask about studying, habits and wellbeing, or explore your TwinTrack data."].exists)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "Send dismisses focus")
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        field.typeText("Unsent keyboard test")
        XCTAssertTrue(app.buttons["assistantDismissKeyboard"].isHittable)
        // Drag through the keyboard edge; a swipe confined to the scroll view
        // can end before native interactive dismissal has completed.
        let start = app.scrollViews["assistantMessages"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        app.buttons["assistantLibrary"].tap()
        XCTAssertTrue(app.navigationBars["Chat Library"].waitForExistence(timeout: 5))
        app.buttons["Chat options for Synthetic plan"].tap()
        app.buttons["Rename"].tap()
        let title = app.alerts.textFields.firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Synthetic plan".count) + "Renamed plan")
        app.alerts.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Renamed plan"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        app.buttons["assistantLibrary"].tap()
        XCTAssertTrue(app.staticTexts["Renamed plan"].waitForExistence(timeout: 5))
        app.staticTexts["Renamed plan"].tap()
        XCTAssertTrue(response.waitForExistence(timeout: 5))
        app.buttons["assistantNewChat"].tap()
        XCTAssertTrue(app.staticTexts["How can I help?"].waitForExistence(timeout: 5))
        XCTAssertFalse(response.exists)
        app.buttons["assistantLibrary"].tap()
        app.buttons["Chat options for Renamed plan"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.alerts.buttons["Delete Chat"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Renamed plan"].exists)
        app.buttons["Chat options for Renamed plan"].tap()
        app.buttons["Delete"].tap()
        app.buttons["Delete Chat"].tap()
        XCTAssertTrue(app.staticTexts["No saved chats"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
    }
    @MainActor
    func testAppearanceChangesAllTabsAndPersistsLightDarkSystem() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests", "--synthetic-appearance-ui-tests", UUID().uuidString]
        app.launch()
        let initialHeader = app.staticTexts["pageTitle.Home"]
        XCTAssertTrue(initialHeader.waitForExistence(timeout: 5))
        let systemAppearance = try XCTUnwrap(initialHeader.value as? String)
        func appearancePicker() -> XCUIElement {
            app.tabBars.buttons["Profile"].tap()
            let picker = app.segmentedControls["appearancePicker"]
            for _ in 0..<8 { if picker.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(picker.waitForExistence(timeout: 5))
            XCTAssertTrue(picker.isHittable)
            return picker
        }
        func choose(_ title: String) {
            let option = appearancePicker().buttons[title]
            XCTAssertTrue(option.waitForExistence(timeout: 5))
            option.tap()
            XCTAssertTrue(option.isSelected)
        }
        func checkTabs(_ expected: String) {
            for tab in ["Home", "TwinTrack AI", "Profile"] {
                app.tabBars.buttons[tab].tap()
                let header = app.staticTexts["pageTitle.\(tab)"]
                XCTAssertTrue(header.waitForExistence(timeout: 5))
                let predicate = NSPredicate(format: "value == %@", expected)
                let match = XCTNSPredicateExpectation(predicate: predicate, object: header)
                XCTAssertEqual(XCTWaiter.wait(for: [match], timeout: 5), .completed)
            }
            XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
        }
        XCTAssertTrue(appearancePicker().buttons["System"].isSelected)
        for mode in ["Light", "Dark"] {
            choose(mode)
            checkTabs("\(mode) appearance")
            app.terminate(); app.launch()
            checkTabs("\(mode) appearance")
            XCTAssertTrue(appearancePicker().buttons[mode].isSelected)
        }
        choose("System")
        checkTabs(systemAppearance)
        app.terminate(); app.launch()
        checkTabs(systemAppearance)
        XCTAssertTrue(appearancePicker().buttons["System"].isSelected)
        // System intentionally has no forced scheme; the unit test checks nil.
        let manualInputs = app.buttons["manualInputsButton"]
        for _ in 0..<6 { if manualInputs.isHittable { break }; app.swipeDown() }
        XCTAssertTrue(manualInputs.isHittable)
        manualInputs.tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["TwinTrack AI"].tap()
        app.buttons["assistantLibrary"].tap()
        XCTAssertTrue(app.navigationBars["Chat Library"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    @MainActor
    func testProfileEditCancelSaveRelaunchAndApprovedDestinations() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-profile-ui-tests", UUID().uuidString]
        app.launch()
        app.tabBars.buttons["Profile"].tap()

        XCTAssertEqual(app.staticTexts["profileDisplayName"].label, "Student")
        app.buttons["editProfileButton"].tap()
        let name = app.textFields["profileNameField"]
        let grade = app.textFields["profileGradeField"]
        name.tap()
        name.typeText("Synthetic Student")
        grade.tap()
        grade.typeText("Grade 12")
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.staticTexts["profileDisplayName"].label, "Student")

        app.buttons["editProfileButton"].tap()
        app.textFields["profileNameField"].tap()
        app.textFields["profileNameField"].typeText("Synthetic Student")
        app.textFields["profileGradeField"].tap()
        app.textFields["profileGradeField"].typeText("Grade 12")
        app.buttons["saveProfileButton"].tap()
        XCTAssertEqual(app.staticTexts["profileDisplayName"].label, "Synthetic Student")
        XCTAssertEqual(app.staticTexts["profileDisplayGrade"].label, "Grade 12")

        app.terminate()
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        XCTAssertEqual(app.staticTexts["profileDisplayName"].label, "Synthetic Student")
        XCTAssertEqual(app.staticTexts["profileDisplayGrade"].label, "Grade 12")
        app.buttons["editProfileButton"].tap()
        XCTAssertTrue(app.buttons["profilePhotoPicker"].exists)
        XCTAssertEqual(app.buttons["profilePhotoPicker"].label, "Choose Photo")
        XCTAssertFalse(app.buttons["editProfilePhotoButton"].exists)
        XCTAssertFalse(app.buttons["removeProfilePhotoButton"].exists)
        app.buttons["Cancel"].tap()

        let about = app.buttons["profileDetail.about"]
        for _ in 0..<10 { if about.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(about.isHittable)
        about.tap()
        XCTAssertTrue(app.staticTexts["Understand your habits. Build a better routine."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["More than a predicted score"].exists)
        XCTAssertTrue(app.staticTexts["Developed as a Grade 12 graduation project."].exists)
        app.navigationBars["About TwinTrack AI"].buttons.firstMatch.tap()
        XCTAssertFalse(app.staticTexts["DRAFT"].exists)

        let methodology = app.buttons["predictionMethodologyButton"]
        for _ in 0..<8 { if methodology.isHittable { break }; app.swipeDown() }
        XCTAssertTrue(methodology.isHittable)
        methodology.tap()
        XCTAssertTrue(app.navigationBars["Prediction Methodology"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Seven inputs"].exists)
        app.navigationBars["Prediction Methodology"].buttons.firstMatch.tap()

        let privacy = app.buttons["dataPrivacyButton"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        privacy.tap()
        XCTAssertTrue(app.navigationBars["Data & Privacy"].waitForExistence(timeout: 5))
        let storedData = app.buttons["viewStoredDataButton"]
        for _ in 0..<8 { if storedData.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(storedData.waitForExistence(timeout: 5))
        XCTAssertTrue(storedData.isHittable)
        XCTAssertTrue(app.staticTexts["No saved predictions"].exists)
        XCTAssertFalse(app.buttons["clearPredictionHistoryButton"].isEnabled)
        storedData.tap()
        XCTAssertTrue(app.navigationBars["Stored Data"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No saved predictions"].exists)
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
    }

    @MainActor
    func testDurationWheelsSetIncreaseDecreaseAndCancel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-duration-ui-tests"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Synthetic duration controls"].waitForExistence(timeout: 5))
        func edit(_ feature: String, operation: String, hours: String, minutes: String) {
            app.buttons[feature].tap()
            XCTAssertTrue(app.staticTexts["Hours"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Minutes"].exists)
            XCTAssertEqual(app.pickerWheels.count, 2)
            app.segmentedControls.buttons[operation].tap()
            app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: hours)
            app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: minutes)
        }
        edit("Sleep", operation: "Set to", hours: "8", minutes: "30")
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["fixture.sleep_hours"].label, "8h 30m")
        edit("Study", operation: "Increase by", hours: "1", minutes: "30")
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["fixture.study_minutes"].label, "3h 30m")
        edit("Screen Time", operation: "Decrease by", hours: "0", minutes: "45")
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["fixture.screen_time_minutes"].label, "3h 15m")
        edit("Sleep", operation: "Set to", hours: "4", minutes: "00")
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.staticTexts["fixture.sleep_hours"].label, "8h 30m")
    }

    @MainActor
    func testInlineErrorRetryAndCompactWelcome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-chat-ui-tests", "--synthetic-chat-error"]
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        XCTAssertTrue(app.staticTexts["assistantWelcome"].exists)
        XCTAssertTrue(app.buttons["assistantManualWhatIf"].isHittable)
        XCTAssertEqual(app.buttons["assistantManualWhatIf"].label, "Manual What-If")
        let field = app.textFields["assistantComposer"].exists ? app.textFields["assistantComposer"] : app.textViews["assistantComposer"]
        field.tap(); field.typeText("Synthetic retry question")
        app.buttons["assistantSend"].tap()
        let retry = app.buttons["assistantRetry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["assistantWelcome"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        retry.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Synthetic response:")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(retry.exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "Synthetic retry question").count, 1)
    }

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
        XCTAssertFalse(app.staticTexts["pageTitle.TwinTrack AI"].exists)
        XCTAssertFalse(app.staticTexts["pageTitle.Profile"].exists)

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
                for hiddenTitle in ["Home", "TwinTrack AI", "Profile"] where hiddenTitle != title {
                    XCTAssertFalse(app.staticTexts["pageTitle.\(hiddenTitle)"].exists,
                                   "Only the selected tab page should be active.")
                }
            }
        }
    }

    @MainActor
    func testWhatIfUnavailableBaselineAndTabExit() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        XCTAssertTrue(app.staticTexts["pageTitle.TwinTrack AI"].waitForExistence(timeout: 5))
        app.buttons["assistantManualWhatIf"].tap()
        // The simulator has no complete HealthKit baseline; never seed production data.
        let unavailable = app.otherElements["whatIfUnavailable"]
        let unavailableText = app.staticTexts["What-If unavailable"]
        XCTAssertTrue(unavailable.exists || unavailableText.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["whatIfRun"].exists)
        XCTAssertFalse(app.buttons["whatIfRun"].isEnabled)
        XCTAssertFalse(app.otherElements["whatIfResult"].exists)
        XCTAssertTrue(app.staticTexts["whatIfDisclaimer"].exists)
        app.buttons["Done"].tap()
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["pageTitle.Home"].waitForExistence(timeout: 5))
        app.tabBars.buttons["TwinTrack AI"].tap()
        app.buttons["assistantManualWhatIf"].tap()
        XCTAssertFalse(app.buttons["whatIfRun"].isEnabled)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
    }

    @MainActor
    func testAssistantComposerAndUnavailableFallback() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["TwinTrack AI"].tap()
        XCTAssertTrue(app.textFields["assistantComposer"].exists || app.textViews["assistantComposer"].exists)
        XCTAssertTrue(app.buttons["assistantSend"].exists)
        XCTAssertFalse(app.buttons["assistantSend"].isEnabled)
        XCTAssertTrue(app.buttons["assistantManualWhatIf"].isHittable)
        app.buttons["assistantNewChat"].tap()
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
        // Model eligibility is independent of the core app. When unavailable, the
        // actual production status remains visible and manual What-If still opens.
        if app.otherElements["assistantUnavailable"].exists {
            XCTAssertTrue(app.buttons["Check availability"].exists)
            app.buttons["Check availability"].tap()
            XCTAssertFalse(app.buttons["assistantSend"].isEnabled)
        }
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
        XCTAssertFalse(app.staticTexts["Refreshing Apple Health…"].exists)

        let openAI = app.buttons["openTwinTrackAI"]
        for _ in 0..<8 {
            if openAI.isHittable { break }
            home.swipeUp()
        }
        XCTAssertTrue(openAI.isHittable, "The last Home button must be reachable above the tab bar.")
        openAI.tap()
        XCTAssertTrue(app.staticTexts["pageTitle.TwinTrack AI"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["TwinTrack AI"].isSelected)
        XCTAssertTrue(app.staticTexts["Ask about studying, habits and wellbeing, or explore your TwinTrack data."].exists)
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Your data. Your preferences. Your control."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testRHRWellbeingIsSecondaryAndReadableInLightAndDark() throws {
        let app = XCUIApplication(), fixtureID = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", fixtureID,
            "--synthetic-profile-ui-tests", fixtureID,
            "--synthetic-appearance-ui-tests", fixtureID, "--synthetic-rhr-ui-tests"]
        app.launch()
        for mode in ["Light", "Dark"] {
            app.tabBars.buttons["Profile"].tap()
            let picker = app.segmentedControls["appearancePicker"]
            for _ in 0..<8 { if picker.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(picker.isHittable)
            picker.buttons[mode].tap()
            app.tabBars.buttons["Home"].tap()
            let header = app.staticTexts["pageTitle.Home"]
            XCTAssertTrue(header.waitForExistence(timeout: 5))
            XCTAssertEqual(header.value as? String, "\(mode) appearance")
            let trend = app.staticTexts["rhrTrendState"]
            for _ in 0..<8 { if trend.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(trend.isHittable)
            XCTAssertEqual(trend.label, "Persistently different from your recent usual range")
            let disclosure = app.staticTexts.matching(NSPredicate(format: "label == %@",
                "Experimental wellbeing comparison, not a diagnosis. Comparison rules are development assumptions. No effect on your assessment prediction.")).firstMatch
            for _ in 0..<3 { if disclosure.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(disclosure.isHittable)
            XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
        }
    }

    @MainActor
    func testManualInputsPolishedLabelsFeedbackSaveCancelAndAppearance() throws {
        let app = XCUIApplication(), fixtureID = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", fixtureID,
            "--synthetic-profile-ui-tests", fixtureID,
            "--synthetic-appearance-ui-tests", fixtureID]
        app.launch()

        func openManualInputs() {
            app.tabBars.buttons["Profile"].tap()
            let button = app.buttons["manualInputsButton"]
            for _ in 0..<6 { if button.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(button.isHittable)
            button.tap()
            XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        }

        func replace(_ field: XCUIElement, with text: String) {
            field.tap()
            let currentValue = (field.value as? String) ?? ""
            field.typeText(
                String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count) + text
            )
        }

        func turnOn(_ toggle: XCUIElement) {
            XCTAssertTrue(toggle.isHittable)
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }

        openManualInputs()
        XCTAssertTrue(app.staticTexts["manualSection.YESTERDAY"].exists)
        XCTAssertTrue(app.buttons["Study Time"].exists)
        XCTAssertEqual(app.buttons["Study Time"].value as? String, "2h 0m")
        XCTAssertTrue(app.buttons["Recreational Screen Time"].exists)
        XCTAssertEqual(app.buttons["Recreational Screen Time"].value as? String, "4h 0m")

        let subject = app.textFields["v2Subject"]
        XCTAssertEqual(subject.value as? String, "Synthetic maths")
        XCTAssertTrue(app.staticTexts["Subject"].exists)
        XCTAssertTrue(app.staticTexts["Assessment Name"].exists)
        XCTAssertTrue(app.staticTexts["Next Assessment"].exists)
        XCTAssertTrue(app.staticTexts["Previous Score"].exists)
        XCTAssertTrue(app.staticTexts["Previous Result Date"].exists)

        let status = app.staticTexts["manualEligibilityStatus"]
        for _ in 0..<7 { if status.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(status.isHittable)
        XCTAssertEqual(status.label, "Prediction unavailable")
        XCTAssertTrue(app.staticTexts["• Confirm the assessment details."].exists)
        for otherReason in [
            "• Enter yesterday’s study time.",
            "• Enter yesterday’s recreational screen time.",
            "• Enter the subject.",
            "• Enter the next assessment name.",
            "• Enter a previous score from 0 to 100.",
            "• Next assessment must be within 1–7 days.",
            "• Previous result must be 1–90 days old.",
        ] {
            XCTAssertFalse(app.staticTexts[otherReason].exists, otherReason)
        }
        let confirmation = app.switches["v2ConfirmContext"]
        turnOn(confirmation)
        let confirmationOn = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "1"), object: confirmation
        )
        XCTAssertEqual(XCTWaiter.wait(for: [confirmationOn], timeout: 3), .completed)
        let readyStatus = app.staticTexts["Ready for V2 Prediction"]
        XCTAssertTrue(readyStatus.waitForExistence(timeout: 3))

        for _ in 0..<7 { if subject.isHittable { break }; app.swipeDown() }
        XCTAssertTrue(subject.isHittable)
        replace(subject, with: "Unsaved subject")
        for _ in 0..<7 { if status.isHittable { break }; app.swipeUp() }
        let unavailableStatus = app.staticTexts["Prediction unavailable"]
        XCTAssertTrue(unavailableStatus.waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        openManualInputs()
        XCTAssertEqual(app.textFields["v2Subject"].value as? String, "Synthetic maths")

        replace(app.textFields["v2Subject"], with: "Chemistry")
        for _ in 0..<7 { if app.switches["v2ConfirmContext"].isHittable { break }; app.swipeUp() }
        turnOn(app.switches["v2ConfirmContext"])
        let savedReadyStatus = app.staticTexts["Ready for V2 Prediction"]
        XCTAssertTrue(savedReadyStatus.waitForExistence(timeout: 3))
        app.buttons["saveManualInputsButton"].tap()
        app.terminate(); app.launch()
        openManualInputs()
        XCTAssertEqual(app.textFields["v2Subject"].value as? String, "Chemistry")
        app.buttons["Cancel"].tap()

        for mode in ["Light", "Dark"] {
            app.tabBars.buttons["Profile"].tap()
            let picker = app.segmentedControls["appearancePicker"]
            for _ in 0..<8 { if picker.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(picker.isHittable)
            picker.buttons[mode].tap()
            openManualInputs()
            XCTAssertTrue(app.staticTexts["manualSection.YESTERDAY"].exists)
            XCTAssertTrue(app.staticTexts["manualSection.ASSESSMENT"].exists)
            app.buttons["Cancel"].tap()
        }
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
    }

    @MainActor
    func testManualInputsLargestDynamicTypeRemainsReachable() throws {
        let app = XCUIApplication(), fixtureID = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", fixtureID,
            "--synthetic-profile-ui-tests", fixtureID,
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let profileTab = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Profile"))
            .firstMatch
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
        let manualInputs = app.buttons["manualInputsButton"]
        for _ in 0..<8 { if manualInputs.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(manualInputs.isHittable)
        manualInputs.tap()
        XCTAssertTrue(app.navigationBars["Manual Inputs"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["manualSection.YESTERDAY"].exists)
        XCTAssertTrue(app.buttons["Study Time"].isHittable)
        XCTAssertTrue(app.buttons["Recreational Screen Time"].isHittable)

        let assessment = app.staticTexts["manualSection.ASSESSMENT"]
        for _ in 0..<6 { if assessment.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(assessment.isHittable)
        XCTAssertTrue(app.textFields["v2Subject"].exists)
        XCTAssertTrue(app.textFields["v2Assessment"].exists)

        let status = app.staticTexts["manualEligibilityStatus"]
        for _ in 0..<10 { if status.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(status.isHittable)
        XCTAssertTrue(app.switches["v2ConfirmContext"].isHittable)
        XCTAssertTrue(app.buttons["saveManualInputsButton"].isHittable)
        XCTAssertTrue(app.buttons["Cancel"].isHittable)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["pageTitle.Profile"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testV2PredictionVersionManualMeaningAndHistoryPersist() throws {
        let app = XCUIApplication()
        let fixtureID = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", fixtureID, "--synthetic-profile-ui-tests", fixtureID]
        app.launch()
        let run = app.buttons["runPrediction"]
        XCTAssertTrue(run.waitForExistence(timeout: 10))
        let eligible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: run)
        XCTAssertEqual(XCTWaiter.wait(for: [eligible], timeout: 10), .completed)
        for _ in 0..<4 { if run.isHittable { break }; app.swipeUp() }
        run.tap()
        let details = app.buttons["homePredictionDetails"]
        XCTAssertTrue(details.waitForExistence(timeout: 5))
        details.tap()
        XCTAssertTrue(app.staticTexts["historyModelVersion"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["historyModelVersion"].label, "TwinTrack Ridge V2 · 2.0-final.1")
        app.buttons["Done"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(details.waitForExistence(timeout: 10))
        details.tap()
        XCTAssertTrue(app.staticTexts["historyModelVersion"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["historyModelVersion"].label, "TwinTrack Ridge V2 · 2.0-final.1")
        app.buttons["Done"].tap()
        app.tabBars.buttons["Profile"].tap()
        let manualInputs = app.buttons["manualInputsButton"]
        for _ in 0..<4 { if manualInputs.isHittable { break }; app.swipeUp() }
        manualInputs.tap()
        XCTAssertTrue(app.textFields["v2Subject"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["v2Subject"].value as? String, "Synthetic maths")
        XCTAssertTrue(app.staticTexts["Outside-class study for this subject yesterday."].exists)
        XCTAssertTrue(app.staticTexts["Recreational screen use yesterday, excluding study."].exists)
        app.buttons["Cancel"].tap()
        let privacy = app.buttons["dataPrivacyButton"]
        for _ in 0..<6 { if privacy.isHittable { break }; app.swipeUp() }
        privacy.tap()
        let stored = app.buttons["viewStoredDataButton"]
        for _ in 0..<8 { if stored.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(stored.isHittable)
        stored.tap()
        let v1 = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "TwinTrack Ridge V1 · Legacy")).firstMatch
        for _ in 0..<8 { if v1.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(v1.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "TwinTrack Ridge V2 · 2.0-final.1")).firstMatch.exists)
    }

    @MainActor
    func testPredictionHistoryHonestEmptyState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--synthetic-profile-ui-tests", UUID().uuidString]
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        let privacy = app.buttons["dataPrivacyButton"]
        for _ in 0..<6 { if privacy.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(privacy.waitForExistence(timeout: 10))
        XCTAssertTrue(privacy.isHittable)
        privacy.tap()

        XCTAssertTrue(app.navigationBars["Data & Privacy"].waitForExistence(timeout: 5))
        let storedData = app.buttons["viewStoredDataButton"]
        for _ in 0..<8 { if storedData.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(storedData.waitForExistence(timeout: 5))
        XCTAssertTrue(storedData.isHittable)
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
