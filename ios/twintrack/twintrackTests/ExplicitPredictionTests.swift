import Foundation
import XCTest
@testable import twintrack

@MainActor
final class ExplicitPredictionTests: XCTestCase {
    func testSeventhInputAndRefreshNeverRunOrSave() async throws {
        let (state, health, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        await state.requestHealthAccess()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        XCTAssertNil(state.currentPrediction)
        XCTAssertTrue(state.predictionHistory.isEmpty)
        XCTAssertTrue(state.runPrediction())
        let saved = try XCTUnwrap(state.lastPrediction)
        XCTAssertEqual(saved.provenance, "explicitRun.v1")
        XCTAssertEqual(saved.prediction, TwinTrackModel.predict(try XCTUnwrap(state.completeProfile)), accuracy: 1e-12)
        state.runPrediction()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        await state.refreshHealth()
        _ = state.currentPrediction
        XCTAssertEqual(state.predictionHistory, [saved])
        XCTAssertEqual(health.authorizations, 1)
    }

    func testChangedMissingAndExpiredInputsDoNotReplaceOldScore() async throws {
        let (state, health, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        await state.requestHealthAccess()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        state.runPrediction()
        let original = try XCTUnwrap(state.lastPrediction)
        state.setStudyTime(hours: 3, minutes: 0)
        XCTAssertEqual(state.predictionStatus(), .stale)
        XCTAssertNil(state.currentPrediction)
        XCTAssertEqual(state.lastPrediction, original)
        XCTAssertEqual(state.predictionHistory, [original])
        XCTAssertTrue(state.runPrediction())
        XCTAssertEqual(state.predictionHistory.count, 2)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(state.predictionStatus(now: tomorrow), .needsRefresh)
        XCTAssertFalse(state.runPrediction(now: tomorrow))
        health.readings.sleep = .missing
        await state.refreshHealth()
        XCTAssertEqual(state.predictionStatus(), .missing)
        XCTAssertFalse(state.runPrediction())
        XCTAssertEqual(state.predictionHistory.count, 2)
    }

    func testInFlightRefreshDisablesRunAndKeepsCommittedResult() async throws {
        let (state, health, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        await state.requestHealthAccess()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        state.runPrediction()
        let saved = state.lastPrediction
        health.hold = true
        let refresh = Task { await state.refreshHealth() }
        for _ in 0..<1000 { if health.pending != nil { break }; await Task.yield() }
        XCTAssertEqual(state.predictionStatus(), .refreshing)
        XCTAssertFalse(state.runPrediction())
        XCTAssertEqual(state.lastPrediction, saved)
        let pending = try XCTUnwrap(health.pending)
        pending.resume(returning: health.readings)
        await refresh.value
        XCTAssertEqual(state.predictionStatus(), .fresh)
    }

    func testClearHistoryDoesNotRecreateEquivalentRun() async {
        let (state, _, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        await state.requestHealthAccess()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        state.runPrediction()
        XCTAssertTrue(state.clearPredictionHistory())
        await state.refreshHealth()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        state.runPrediction()
        XCTAssertTrue(state.predictionHistory.isEmpty)
    }

    func testRestoreRequiresReestablishingHealthFreshness() async {
        let (state, health, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        await state.requestHealthAccess()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        state.runPrediction()
        let restored = TwinTrackState(defaults: defaults, healthService: health)
        XCTAssertNotNil(restored.lastPrediction)
        XCTAssertNil(restored.currentPrediction)
        await restored.refreshHealth()
        XCTAssertEqual(restored.predictionStatus(), .fresh)
        XCTAssertEqual(restored.predictionHistory.count, 1)
    }

    func testCorruptHistoryIsNotOverwrittenByRunOrClear() async {
        let (state, health, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        _ = state
        let corrupt = Data("not history".utf8)
        defaults.set(corrupt, forKey: "twintrack.prediction.history.v1")
        let restored = TwinTrackState(defaults: defaults, healthService: health)
        await restored.requestHealthAccess()
        restored.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        XCTAssertFalse(restored.runPrediction())
        XCTAssertFalse(restored.clearPredictionHistory())
        XCTAssertNotNil(restored.predictionIssue)
        XCTAssertEqual(defaults.data(forKey: "twintrack.prediction.history.v1"), corrupt)
    }

    func testReadToolDoesNotComputeAndScenarioRequiresExplicitRun() async throws {
        let (state, _, defaults, name) = fixture()
        defer { defaults.removePersistentDomain(forName: name) }
        await state.requestHealthAccess()
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let run = AssistantToolRun(snapshot: AssistantSnapshot(state: state), userMessage: "What if I sleep 8 hours?")
        _ = try run.readCurrent()
        XCTAssertNil(run.cards.last?.prediction)
        _ = try run.runScenario(AssistantScenarioArguments(changes: [AssistantChange(feature: .sleep_hours,
            operation: .set, unit: .hours, value: 8, evidence: "sleep 8 hours")]))
        XCTAssertEqual(run.cards.last?.title, "Run Prediction first")
        XCTAssertTrue(state.predictionHistory.isEmpty)
    }

    private func fixture() -> (TwinTrackState, ExplicitHealthFixture, UserDefaults, String) {
        let name = "ExplicitPredictionTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        let health = ExplicitHealthFixture()
        return (TwinTrackState(defaults: defaults, healthService: health), health, defaults, name)
    }
}

@MainActor
private final class ExplicitHealthFixture: HealthDataProviding {
    var isAvailable = true
    var authorizations = 0
    var hold = false
    var pending: CheckedContinuation<HealthReadings, Never>?
    var readings = HealthReadings(sleep: .available(7), steps: .available(5000), exercise: .available(30), restingHeartRate: .available(60))
    func requestAccess() async throws { authorizations += 1 }
    func read(window: HealthDataWindow) async -> HealthReadings {
        if hold { return await withCheckedContinuation { pending = $0 } }
        return readings
    }
}
