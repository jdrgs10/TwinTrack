#if DEBUG
import XCTest
@testable import twintrack

@MainActor
final class StudentJourneyFixtureTests: XCTestCase {
    func testScenarioSelectionDefaultsToExistingCompleteFixture() {
        XCTAssertEqual(V2UITestFixture.Scenario.from(arguments: []), .complete)
        XCTAssertEqual(V2UITestFixture.Scenario.from(arguments: ["--synthetic-journey-scenario"]), .complete)
        XCTAssertEqual(V2UITestFixture.Scenario.from(arguments: ["--synthetic-journey-scenario", "unknown"]), .complete)
        for scenario in V2UITestFixture.Scenario.allCases {
            XCTAssertEqual(V2UITestFixture.Scenario.from(arguments: ["--synthetic-journey-scenario", scenario.rawValue]), scenario)
        }
    }

    func testMissingHealthKeepsUnavailableValuesAndCannotRunPrediction() async {
        let state = V2UITestFixture.state(id: session(), scenario: .missingHealth)
        let before = state.predictionHistory
        await state.refreshHealth()
        XCTAssertEqual(state.healthAccess, .completed)
        XCTAssertNil(state.sleepHours)
        XCTAssertNil(state.steps)
        XCTAssertNil(state.exerciseMinutes)
        XCTAssertNil(state.restingHeartRate)
        XCTAssertNil(state.healthReadings.restingHeartRateSampleDate)
        XCTAssertNil(state.restingHeartRateTrend)
        XCTAssertEqual(state.studyMinutes, 120)
        XCTAssertFalse(state.runPrediction())
        XCTAssertEqual(state.predictionHistory, before)
    }

    func testPartialHealthDoesNotSubstituteZerosOrDiscardAccessibleReadings() async {
        let state = V2UITestFixture.state(id: session(), scenario: .partialHealth)
        await state.refreshHealth()
        XCTAssertNil(state.sleepHours)
        XCTAssertNil(state.exerciseMinutes)
        XCTAssertEqual(state.steps, 5000)
        XCTAssertEqual(state.restingHeartRate, 60)
        XCTAssertNotNil(state.healthReadings.restingHeartRateSampleDate)
        XCTAssertFalse(state.runPrediction())
    }

    func testMissingManualStaysMissingAcrossRelaunchWhileHealthRemainsSynthetic() async {
        let id = session()
        let state = V2UITestFixture.state(id: id, scenario: .missingManual)
        await state.refreshHealth()
        XCTAssertEqual(state.sleepHours, 7)
        XCTAssertEqual(state.steps, 5000)
        XCTAssertNil(state.studyMinutes)
        XCTAssertNil(state.screenTimeMinutes)
        XCTAssertNil(state.previousScore)
        XCTAssertNil(state.predictionContext)
        XCTAssertFalse(state.runPrediction())
        let reopened = V2UITestFixture.state(id: id, scenario: .missingManual)
        await reopened.refreshHealth()
        XCTAssertNil(reopened.studyMinutes)
        XCTAssertNil(reopened.predictionContext)
        XCTAssertEqual(reopened.predictionHistory, state.predictionHistory)
    }

    func testCompleteFixtureUsesRealRidgeAndPersistsOnlyInItsSession() async throws {
        let id = session()
        let state = V2UITestFixture.state(id: id, scenario: .complete)
        await state.refreshHealth()
        let originalCount = state.predictionHistory.count
        XCTAssertTrue(state.runPrediction())
        let profile = try XCTUnwrap(state.completeProfile)
        XCTAssertEqual(try XCTUnwrap(state.lastPrediction?.prediction), TwinTrackModel.predict(profile), accuracy: 1e-10)
        XCTAssertEqual(state.predictionHistory.count, originalCount + 1)
        let saved = state.predictionHistory
        await state.refreshHealth()
        XCTAssertEqual(state.predictionHistory, saved)
        let reopened = V2UITestFixture.state(id: id, scenario: .complete)
        XCTAssertEqual(reopened.predictionHistory, saved)
        XCTAssertEqual(reopened.predictionContext, state.predictionContext)
        let separate = V2UITestFixture.state(id: session(), scenario: .missingManual)
        XCTAssertEqual(separate.predictionHistory.count, originalCount)
        XCTAssertNil(separate.studyMinutes)
    }

    private func session() -> UUID {
        let id = UUID()
        let suite = "TwinTrack.V2UITests.\(id.uuidString)"
        addTeardownBlock { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        return id
    }
}
#endif
