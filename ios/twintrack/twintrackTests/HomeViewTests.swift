import Foundation
import XCTest
@testable import twintrack

@MainActor
final class HomeViewTests: XCTestCase {
    func testDurationFormattingUsesHoursAndMinutes() async {
        XCTAssertEqual(HomeDisplay.duration(minutes: 0), "0 min")
        XCTAssertEqual(HomeDisplay.duration(minutes: 45), "45 min")
        XCTAssertEqual(HomeDisplay.duration(minutes: 60), "1h")
        XCTAssertEqual(HomeDisplay.duration(minutes: 165), "2h 45m")
        XCTAssertNil(HomeDisplay.duration(minutes: nil))
    }

    func testHealthAndScoreFormattingUsesCorrectUnits() async {
        XCTAssertEqual(HomeDisplay.sleep(7 + 10.0 / 60), "7h 10m")
        XCTAssertEqual(HomeDisplay.steps(8420), "8,420")
        XCTAssertEqual(HomeDisplay.exercise(34), "34 min")
        XCTAssertEqual(HomeDisplay.restingHeartRate(62), "62 bpm")
        XCTAssertEqual(HomeDisplay.previousScore(81.4), "81.4")
        XCTAssertEqual(HomeDisplay.prediction(84.64), "84.6")
    }

    func testInvalidOrMissingValuesDoNotFormatAsZero() async {
        XCTAssertNil(HomeDisplay.sleep(nil))
        XCTAssertNil(HomeDisplay.steps(nil))
        XCTAssertNil(HomeDisplay.exercise(nil))
        XCTAssertNil(HomeDisplay.restingHeartRate(nil))
        XCTAssertNil(HomeDisplay.previousScore(nil))
        XCTAssertNil(HomeDisplay.sleep(.nan))
        XCTAssertNil(HomeDisplay.steps(-1))
    }

    func testCompleteSharedStateUsesTheFrozenRidgePrediction() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }

        fixture.service.result = completeHealth
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 165,
            screenTimeMinutes: 264,
            previousScore: 81.4
        ))
        await fixture.state.requestHealthAccess()

        let profile = try XCTUnwrap(fixture.state.completeProfile)
        let prediction = try XCTUnwrap(fixture.state.currentPrediction)
        XCTAssertEqual(prediction, TwinTrackModel.predict(profile), accuracy: 1e-12)
    }

    func testEverySingleMissingInputKeepsPredictionUnavailable() async {
        for missing in TwinTrackFeature.allCases {
            let fixture = makeFixture()
            defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }

            fixture.service.result = healthReadings(missing: missing)
            XCTAssertTrue(fixture.state.saveManualInputs(
                studyMinutes: missing == .studyMinutes ? nil : 165,
                screenTimeMinutes: missing == .screenTimeMinutes ? nil : 264,
                previousScore: missing == .previousScore ? nil : 81.4
            ))
            await fixture.state.requestHealthAccess()

            XCTAssertNil(fixture.state.completeProfile, "\(missing.key) must remain required")
            XCTAssertNil(fixture.state.currentPrediction, "\(missing.key) must not receive a fallback")
            XCTAssertTrue(fixture.state.missingInputs.contains(missing))
        }
    }

    private var completeHealth: HealthReadings {
        HealthReadings(
            sleep: .available(7.2),
            steps: .available(8420),
            exercise: .available(34),
            restingHeartRate: .available(62)
        )
    }

    private func healthReadings(missing: TwinTrackFeature) -> HealthReadings {
        var readings = completeHealth
        switch missing {
        case .sleepHours: readings.sleep = .missing
        case .steps: readings.steps = .missing
        case .exerciseMinutes: readings.exercise = .missing
        case .restingHeartRate: readings.restingHeartRate = .missing
        case .studyMinutes, .screenTimeMinutes, .previousScore: break
        }
        return readings
    }

    private func makeFixture() -> (
        state: TwinTrackState,
        service: HomeTestHealthService,
        defaults: UserDefaults,
        name: String
    ) {
        let name = "HomeViewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let service = HomeTestHealthService()
        return (TwinTrackState(defaults: defaults, healthService: service), service, defaults, name)
    }
}

@MainActor
private final class HomeTestHealthService: HealthDataProviding {
    var isAvailable = true
    var result = HealthReadings()

    func requestAccess() async throws {}

    func read(window: HealthDataWindow) async -> HealthReadings {
        result
    }
}
