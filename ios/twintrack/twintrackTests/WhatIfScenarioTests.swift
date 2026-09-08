import Foundation
import XCTest
@testable import twintrack

@MainActor
final class WhatIfScenarioTests: XCTestCase {
    // Synthetic fixtures only; these values do not come from a person's Health store.
    private var baseline: TwinTrackProfile {
        TwinTrackProfile(sleepHours: 7, steps: 6500, exerciseMinutes: 30,
                         restingHeartRate: 68, studyMinutes: 120,
                         screenTimeMinutes: 240, previousScore: 75)
    }

    private func values(_ profile: TwinTrackProfile) -> [Double] {
        TwinTrackFeature.allCases.map { WhatIfScenario.value($0, in: profile) }
    }

    func testBaselineRemainsImmutableAfterAllSevenChanges() throws {
        let original = baseline
        let before = values(original)
        var scenario = try WhatIfScenario(baseline: original)
        for feature in TwinTrackFeature.allCases {
            try scenario.set(scenario.currentValue(for: feature) + 1, for: feature)
        }
        _ = scenario.evaluate()
        XCTAssertEqual(values(original), before)
        XCTAssertEqual(values(scenario.baseline), before)
        XCTAssertEqual(scenario.changes.count, 7)
    }

    func testOneVariableUsesExistingProductionPredictor() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        try scenario.set(180, for: .studyMinutes)
        let expected = TwinTrackProfile(sleepHours: 7, steps: 6500, exerciseMinutes: 30,
                                       restingHeartRate: 68, studyMinutes: 180,
                                       screenTimeMinutes: 240, previousScore: 75)
        let result = scenario.evaluate()
        XCTAssertEqual(result.baselinePrediction, TwinTrackModel.predict(baseline))
        XCTAssertEqual(result.scenarioPrediction, TwinTrackModel.predict(expected))
        XCTAssertEqual(result.delta, TwinTrackModel.predict(expected) - TwinTrackModel.predict(baseline))
        XCTAssertEqual(result.changedFeatures, [.studyMinutes])
    }

    func testMultipleChangesAreEvaluatedTogetherNotSummedAtClamp() throws {
        var combined = try WhatIfScenario(baseline: baseline)
        var studyOnly = combined
        var screenOnly = combined
        try combined.set(10_000, for: .studyMinutes)
        try combined.set(100_000, for: .screenTimeMinutes)
        try studyOnly.set(10_000, for: .studyMinutes)
        try screenOnly.set(100_000, for: .screenTimeMinutes)
        let expected = TwinTrackProfile(sleepHours: 7, steps: 6500, exerciseMinutes: 30,
                                       restingHeartRate: 68, studyMinutes: 10_000,
                                       screenTimeMinutes: 100_000, previousScore: 75)
        let result = combined.evaluate()
        XCTAssertEqual(result.scenarioPrediction, TwinTrackModel.predict(expected))
        XCTAssertEqual(result.delta, result.scenarioPrediction - result.baselinePrediction)
        XCTAssertNotEqual(result.delta, studyOnly.evaluate().delta + screenOnly.evaluate().delta)
        XCTAssertEqual(result.changedFeatures, [.studyMinutes, .screenTimeMinutes])
    }

    func testEachMissingCurrentInputRejectsBaseline() async throws {
        for missing in TwinTrackFeature.allCases {
            let name = "WhatIfScenarioTests.missing.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
            defer { defaults.removePersistentDomain(forName: name) }
            let service = WhatIfTestHealthService()
            switch missing {
            case .sleepHours: service.readings.sleep = .missing
            case .steps: service.readings.steps = .missing
            case .exerciseMinutes: service.readings.exercise = .missing
            case .restingHeartRate: service.readings.restingHeartRate = .missing
            default: break
            }
            let state = TwinTrackState(defaults: defaults, healthService: service)
            XCTAssertTrue(state.saveManualInputs(studyMinutes: missing == .studyMinutes ? nil : 120,
                screenTimeMinutes: missing == .screenTimeMinutes ? nil : 240,
                previousScore: missing == .previousScore ? nil : 75))
            await state.requestHealthAccess()
            XCTAssertThrowsError(try WhatIfScenario(baseline: state.completeProfile)) {
                XCTAssertEqual($0 as? WhatIfError, .missingBaseline)
            }
            XCTAssertNil(state.currentPrediction)
        }
    }

    func testPreviousScoreEndpointsAcceptedAndOutsideBoundsRejected() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        for score in [0.0, 100.0] {
            try scenario.set(score, for: .previousScore)
            XCTAssertEqual(scenario.scenarioValue(for: .previousScore), score)
        }
        for score in [-1.0, 100.01] {
            XCTAssertThrowsError(try scenario.set(score, for: .previousScore))
            XCTAssertEqual(scenario.scenarioValue(for: .previousScore), 100)
        }
    }

    func testNegativeValuesRejectedWithoutChangingScenario() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        for feature in TwinTrackFeature.allCases {
            XCTAssertThrowsError(try scenario.set(-1, for: feature))
            XCTAssertEqual(scenario.scenarioValue(for: feature), scenario.currentValue(for: feature))
        }
        XCTAssertTrue(scenario.changes.isEmpty)
    }

    func testZeroAllowedExceptRestingHeartRate() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        for feature in TwinTrackFeature.allCases where feature != .restingHeartRate {
            try scenario.set(0, for: feature)
            XCTAssertEqual(scenario.scenarioValue(for: feature), 0)
        }
        XCTAssertThrowsError(try scenario.set(0, for: .restingHeartRate))
        try scenario.set(0.1, for: .restingHeartRate)
    }

    func testNonfiniteAndUncomputablyLargeValuesAreRejected() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        for feature in TwinTrackFeature.allCases {
            for value in [Double.nan, .infinity, -.infinity, .greatestFiniteMagnitude] {
                XCTAssertThrowsError(try scenario.set(value, for: feature))
            }
        }
        XCTAssertTrue(scenario.changes.isEmpty)
    }

    func testClampedDeltaAtBothBoundaries() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        try scenario.set(10_000, for: .studyMinutes)
        let high = scenario.evaluate()
        XCTAssertGreaterThan(TwinTrackModel.predictRaw(high.scenario), 100)
        XCTAssertEqual(high.scenarioPrediction, 100)
        XCTAssertEqual(high.delta, 100 - TwinTrackModel.predict(baseline))
        scenario.reset()
        try scenario.set(100_000, for: .screenTimeMinutes)
        let low = scenario.evaluate()
        XCTAssertLessThan(TwinTrackModel.predictRaw(low.scenario), 0)
        XCTAssertEqual(low.scenarioPrediction, 0)
        XCTAssertEqual(low.delta, -TwinTrackModel.predict(baseline))
        var alreadyClamped = try WhatIfScenario(baseline: high.scenario)
        try alreadyClamped.set(20_000, for: .studyMinutes)
        XCTAssertEqual(alreadyClamped.evaluate().delta, 0)
    }

    func testCancelAndExitLeaveRealStateAndPersistenceUnchanged() async throws {
        let name = "WhatIfScenarioTests.persistence.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let service = WhatIfTestHealthService()
        let state = TwinTrackState(defaults: defaults, healthService: service)
        XCTAssertTrue(state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await state.requestHealthAccess()
        let original = try XCTUnwrap(state.completeProfile)
        let persisted = defaults.persistentDomain(forName: name)! as NSDictionary
        let originalPrediction = state.currentPrediction
        var temporary: WhatIfScenario? = try WhatIfScenario(baseline: original)
        for feature in TwinTrackFeature.allCases {
            try temporary?.set(WhatIfScenario.value(feature, in: original) + 1, for: feature)
        }
        _ = temporary?.evaluate()
        temporary?.reset()
        XCTAssertEqual(temporary?.evaluate().delta, 0)
        temporary = nil // The same ownership boundary used on cancel/tab exit.
        XCTAssertEqual(values(try XCTUnwrap(state.completeProfile)), values(original))
        XCTAssertEqual(state.currentPrediction, originalPrediction)
        XCTAssertEqual(defaults.persistentDomain(forName: name)! as NSDictionary, persisted)
        XCTAssertEqual(service.readCount, 1)
        let recreated = TwinTrackState(defaults: defaults, healthService: service)
        XCTAssertEqual(recreated.studyMinutes, 120)
        XCTAssertEqual(recreated.screenTimeMinutes, 240)
        XCTAssertEqual(recreated.previousScore, 75)
        XCTAssertNil(recreated.completeProfile)
    }

    func testResetAndReturningToCurrentValueRemoveOverrides() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        try scenario.set(180, for: .studyMinutes)
        try scenario.set(120, for: .studyMinutes)
        XCTAssertTrue(scenario.changes.isEmpty)
        try scenario.set(8000, for: .steps)
        scenario.reset()
        XCTAssertEqual(values(scenario.scenarioProfile), values(baseline))
        XCTAssertEqual(scenario.evaluate().delta, 0)
    }

    func testDurationEditorPreservesFrozenUnits() {
        for feature in [TwinTrackFeature.studyMinutes, .screenTimeMinutes, .sleepHours] {
            var draft = WhatIfInputDraft(feature: feature, value: 7)
            draft.hours = "2"
            draft.minutes = "30"
            XCTAssertEqual(draft.parsedValue, feature == .sleepHours ? 2.5 : 150)
        }
    }

    func testDurationEditorRejectsInvalidComponents() {
        for feature in [TwinTrackFeature.sleepHours, .studyMinutes, .screenTimeMinutes] {
            for (hours, minutes) in [("-1", "0"), ("1", "-1"), ("1", "60"), ("1.5", "0"), ("", "0"), ("inf", "0")] {
                var draft = WhatIfInputDraft(feature: feature, value: 7)
                draft.hours = hours
                draft.minutes = minutes
                XCTAssertNil(draft.parsedValue)
            }
        }
    }

    func testUntouchedEditorDoesNotRoundPreciseBaseline() {
        let precise = 7.123456789123
        for feature in TwinTrackFeature.allCases {
            XCTAssertEqual(WhatIfInputDraft(feature: feature, value: precise).parsedValue, precise)
        }
        XCTAssertEqual(WhatIfDisplay.value(119.9999, feature: .studyMinutes), "2h 0m")
        XCTAssertEqual(WhatIfInputDraft(feature: .studyMinutes, value: 119.9999).minutes, "0")
    }

    func testScenarioCopiesDoNotShareEdits() throws {
        let first = try WhatIfScenario(baseline: baseline)
        var second = first
        try second.set(200, for: .studyMinutes)
        XCTAssertTrue(first.changes.isEmpty)
        XCTAssertEqual(first.scenarioValue(for: .studyMinutes), 120)
        XCTAssertEqual(second.scenarioValue(for: .studyMinutes), 200)
    }

    func testInvalidCompleteBaselineIsRejected() {
        for invalid in [0.0, -1.0, .nan, .infinity] {
            let profile = TwinTrackProfile(sleepHours: 7, steps: 6500, exerciseMinutes: 30,
                                          restingHeartRate: invalid, studyMinutes: 120,
                                          screenTimeMinutes: 240, previousScore: 75)
            XCTAssertThrowsError(try WhatIfScenario(baseline: profile))
        }
    }

    func testLargeValidScenarioRemainsFiniteAndDeltaFormattingAvoidsNegativeZero() throws {
        var scenario = try WhatIfScenario(baseline: baseline)
        try scenario.set(Double.greatestFiniteMagnitude.squareRoot(), for: .steps)
        let result = scenario.evaluate()
        XCTAssertTrue(result.scenarioPrediction.isFinite)
        XCTAssertTrue(result.delta.isFinite)
        XCTAssertEqual(WhatIfDisplay.delta(-0.001), "0.0")
    }
}

@MainActor
private final class WhatIfTestHealthService: HealthDataProviding {
    var isAvailable = true
    var readings = HealthReadings(sleep: .available(7), steps: .available(6500),
                                 exercise: .available(30), restingHeartRate: .available(68))
    var readCount = 0
    func requestAccess() async throws {}
    func read(window: HealthDataWindow) async -> HealthReadings {
        readCount += 1
        return readings
    }
}
