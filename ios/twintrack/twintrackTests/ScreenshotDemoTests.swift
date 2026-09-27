#if DEBUG && targetEnvironment(simulator)
import XCTest
@testable import twintrack

@MainActor
final class ScreenshotDemoTests: XCTestCase {
    func testOnlyFourHealthValuesArePopulated() async {
        let state = ScreenshotDemo.state(arguments: arguments())
        await state.refreshHealth()
        XCTAssertEqual(state.sleepHours, 7.7)
        XCTAssertEqual(state.steps, 7850)
        XCTAssertEqual(state.exerciseMinutes, 42)
        XCTAssertEqual(state.restingHeartRate, 62)
        XCTAssertEqual(HomeDisplay.sleep(state.sleepHours), "7h 42m")
        XCTAssertNil(state.studyMinutes)
        XCTAssertNil(state.screenTimeMinutes)
        XCTAssertNil(state.previousScore)
        XCTAssertNil(state.predictionContext)
        XCTAssertNil(state.restingHeartRateTrend)
        XCTAssertNil(state.lastPrediction)
        XCTAssertTrue(state.predictionHistory.isEmpty)
        XCTAssertFalse(state.runPrediction())
    }

    func testManualEditsUseRealRidgeAndRefreshDoesNotFabricatePrediction() async throws {
        let state = ScreenshotDemo.state(arguments: arguments())
        await state.refreshHealth()
        state.saveV2TestInputs(studyMinutes: 120, screenTimeMinutes: 90, previousScore: 80)
        XCTAssertNil(state.lastPrediction)
        XCTAssertTrue(state.runPrediction())
        let profile = try XCTUnwrap(state.completeProfile)
        let score = try XCTUnwrap(state.lastPrediction?.prediction)
        XCTAssertEqual(score, TwinTrackModel.predict(profile), accuracy: 1e-10)
        XCTAssertEqual(state.lastPrediction?.inputs, PredictionInputs(profile: profile))
        state.saveV2TestInputs(studyMinutes: 150, screenTimeMinutes: 90, previousScore: 80)
        XCTAssertEqual(state.lastPrediction?.prediction, score)
        XCTAssertEqual(state.predictionStatus(), .stale)
        XCTAssertTrue(state.runPrediction())
        XCTAssertEqual(state.lastPrediction?.prediction, TwinTrackModel.predict(try XCTUnwrap(state.completeProfile)))
        let count = state.predictionHistory.count
        await state.refreshHealth()
        XCTAssertEqual(state.studyMinutes, 150)
        XCTAssertEqual(state.predictionHistory.count, count)
    }

    func testRelaunchPreservesOnlyDemoManualEntriesAndNeverWritesHistory() async throws {
        let args = arguments()
        let session = args.last!
        let defaults = UserDefaults(suiteName: ScreenshotDemo.suiteName(session: session))!
        let state = ScreenshotDemo.state(arguments: args)
        await state.refreshHealth()
        state.saveV2TestInputs(studyMinutes: 120, screenTimeMinutes: 90, previousScore: 80)
        XCTAssertTrue(state.runPrediction())
        XCTAssertTrue(try UserDefaultsPredictionHistoryStore(defaults: defaults).load().isEmpty)
        let reopened = ScreenshotDemo.state(arguments: args)
        await reopened.refreshHealth()
        XCTAssertEqual(reopened.studyMinutes, 120)
        XCTAssertEqual(reopened.screenTimeMinutes, 90)
        XCTAssertEqual(reopened.previousScore, 80)
        XCTAssertEqual(reopened.predictionContext, state.predictionContext)
        XCTAssertTrue(reopened.predictionHistory.isEmpty)
        XCTAssertNil(reopened.lastPrediction)
        let other = ScreenshotDemo.state(arguments: arguments())
        XCTAssertNil(other.studyMinutes)
        XCTAssertTrue(other.predictionHistory.isEmpty)
    }

    private func arguments() -> [String] {
        let id = UUID().uuidString
        let name = ScreenshotDemo.suiteName(session: id)
        addTeardownBlock { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        return [ScreenshotDemo.launchArgument, "--screenshot-session", id]
    }
}
#endif
