import Foundation
import XCTest
@testable import twintrack

final class TwinTrackStateTests: XCTestCase {
    func testStudyTimeConvertsHoursAndMinutesToTotalMinutes() {
        XCTAssertEqual(ManualDuration.totalMinutes(hours: 0, minutes: 0), 0)
        XCTAssertEqual(ManualDuration.totalMinutes(hours: 1, minutes: 30), 90)
        XCTAssertEqual(ManualDuration.totalMinutes(hours: 2, minutes: 45), 165)
    }

    func testScreenTimeConvertsHoursAndMinutesToTotalMinutes() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(state.setScreenTime(hours: 0, minutes: 0))
        XCTAssertEqual(state.screenTimeMinutes, 0)
        XCTAssertTrue(state.setScreenTime(hours: 1, minutes: 30))
        XCTAssertEqual(state.screenTimeMinutes, 90)
        XCTAssertTrue(state.setScreenTime(hours: 2, minutes: 45))
        XCTAssertEqual(state.screenTimeMinutes, 165)
    }

    func testPreviousScoreAcceptsZeroMidpointAndOneHundred() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        for value in [0.0, 50.0, 100.0] {
            XCTAssertTrue(state.setPreviousScore(value))
            XCTAssertEqual(state.previousScore, value)
        }
    }

    func testPreviousScoreRejectsOutOfRangeAndNonNumericValues() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertFalse(state.setPreviousScore(-1))
        XCTAssertFalse(state.setPreviousScore(101))
        XCTAssertNil(PreviousScoreInput.parse("not a number"))
        XCTAssertFalse(PreviousScoreInput.isValidDraft("not a number"))
        XCTAssertNil(state.previousScore)
    }

    func testMissingValuesRemainNilRatherThanZero() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(state.sleepHours)
        XCTAssertNil(state.steps)
        XCTAssertNil(state.exerciseMinutes)
        XCTAssertNil(state.restingHeartRate)
        XCTAssertNil(state.studyMinutes)
        XCTAssertNil(state.screenTimeMinutes)
        XCTAssertNil(state.previousScore)
    }

    func testManualValuesSurviveStateRecreation() throws {
        let (_, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstState = TwinTrackState(defaults: defaults)
        XCTAssertTrue(firstState.setStudyTime(hours: 2, minutes: 45))
        XCTAssertTrue(firstState.setScreenTime(hours: 4, minutes: 24))
        XCTAssertTrue(firstState.setPreviousScore(81.4))

        let recreatedState = TwinTrackState(defaults: defaults)
        XCTAssertEqual(recreatedState.studyMinutes, 165)
        XCTAssertEqual(recreatedState.screenTimeMinutes, 264)
        XCTAssertEqual(recreatedState.previousScore, 81.4)
    }

    func testPredictionRemainsUnavailableWithoutHealthValues() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(
            state.saveManualInputs(
                studyMinutes: 165,
                screenTimeMinutes: 264,
                previousScore: 81.4
            )
        )
        XCTAssertNil(state.completeProfile)
    }

    private func makeState() -> (TwinTrackState, UserDefaults, String) {
        let suiteName = "TwinTrackStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (TwinTrackState(defaults: defaults), defaults, suiteName)
    }
}
