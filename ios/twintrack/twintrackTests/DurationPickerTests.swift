import XCTest
@testable import twintrack

@MainActor
final class DurationPickerTests: XCTestCase {
    func testSleepConvertsHoursAndMinutesToDecimalHours() {
        var draft = WhatIfDurationDraft(feature: .sleepHours, value: 7)
        draft.hours = 7; draft.minutes = 30
        XCTAssertEqual(draft.value, 7.5)
        draft.hours = 8; draft.minutes = 15
        XCTAssertEqual(draft.value, 8.25)
    }

    func testStudyAndScreenConvertToModelMinutes() {
        var study = WhatIfDurationDraft(feature: .studyMinutes, value: 120)
        study.hours = 2; study.minutes = 15
        XCTAssertEqual(study.value, 135)
        var screen = WhatIfDurationDraft(feature: .screenTimeMinutes, value: 240)
        screen.hours = 3; screen.minutes = 45
        XCTAssertEqual(screen.value, 225)
    }

    func testSetIncreaseAndDecreaseAreDistinctOperations() {
        var sleep = WhatIfDurationDraft(feature: .sleepHours, value: 7)
        sleep.hours = 8; sleep.minutes = 30
        XCTAssertEqual(sleep.value, 8.5)
        var study = WhatIfDurationDraft(feature: .studyMinutes, value: 120)
        study.select(.increase); study.hours = 1; study.minutes = 30
        XCTAssertEqual(study.value, 210)
        var screen = WhatIfDurationDraft(feature: .screenTimeMinutes, value: 240)
        screen.select(.decrease); screen.minutes = 45
        XCTAssertEqual(screen.value, 195)
    }

    func testZeroFiftyNineAndHourRollover() {
        var draft = WhatIfDurationDraft(feature: .studyMinutes, value: 0)
        draft.hours = 0; draft.minutes = 0
        XCTAssertEqual(draft.value, 0)
        draft.minutes = 59
        XCTAssertEqual(draft.value, 59)
        draft.hours = 1; draft.minutes = 0
        XCTAssertEqual(draft.value, 60)
        draft.select(.increase); draft.minutes = 0
        XCTAssertEqual(draft.value, 0)
    }

    func testWheelBoundsAndNegativeScenarioRejected() {
        var draft = WhatIfDurationDraft(feature: .screenTimeMinutes, value: 30)
        draft.hours = ManualDuration.maximumHours; draft.minutes = 59
        XCTAssertNil(draft.value, "The existing wheel range does not override V2 support.")
        draft.hours = 12; draft.minutes = 0
        XCTAssertEqual(draft.value, 720)
        draft.minutes = 60; XCTAssertNil(draft.value)
        draft.minutes = 0; draft.hours = -1; XCTAssertNil(draft.value)
        draft.hours = ManualDuration.maximumHours + 1; XCTAssertNil(draft.value)
        draft.select(.decrease); draft.hours = 1
        XCTAssertNil(draft.value)
    }

    func testUntouchedPrecisionAndLargeValuesArePreserved() {
        for (feature, value) in [(TwinTrackFeature.sleepHours, 7.123456789), (.studyMinutes, 123.123456), (.screenTimeMinutes, 600.123)] {
            let draft = WhatIfDurationDraft(feature: feature, value: value)
            XCTAssertEqual(draft.value, value)
            XCTAssertFalse(draft.edited)
        }
        XCTAssertNil(WhatIfDurationDraft(feature: .sleepHours, value: .infinity).value)
        XCTAssertNil(WhatIfDurationDraft(feature: .screenTimeMinutes, value: 2000.123).value)
    }

    func testCancelDraftHasNoConnectionToBaselineOrHistory() throws {
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60, studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let scenario = try WhatIfScenario(baseline: profile)
        let original = scenario.evaluate().scenarioPrediction
        var draft = WhatIfDurationDraft(feature: .sleepHours, value: scenario.scenarioValue(for: .sleepHours))
        draft.select(.increase); draft.hours = 2
        XCTAssertEqual(draft.value, 9)
        // Cancel dismisses the value draft without calling the editor's onDone.
        XCTAssertTrue(scenario.changes.isEmpty)
        XCTAssertEqual(scenario.evaluate().scenarioPrediction, original)
    }

    func testOperationSwitchStartsRelativeAmountAtZero() {
        var draft = WhatIfDurationDraft(feature: .studyMinutes, value: 120)
        draft.select(.increase)
        XCTAssertEqual(draft.hours, 0); XCTAssertEqual(draft.minutes, 0)
        XCTAssertEqual(draft.value, 120)
        draft.hours = 1
        draft.select(.decrease)
        XCTAssertEqual(draft.value, 120)
        draft.select(.set)
        XCTAssertEqual(draft.hours, 2)
        XCTAssertEqual(draft.value, 120)
    }

    func testOtherFeaturesDoNotUseDurationDrafts() {
        for feature: TwinTrackFeature in [.steps, .exerciseMinutes, .restingHeartRate, .previousScore] {
            XCTAssertNil(WhatIfDurationDraft(feature: feature, value: 20).value)
            XCTAssertFalse(WhatIfInputDraft(feature: feature, value: 20).usesDuration)
        }
    }
}
