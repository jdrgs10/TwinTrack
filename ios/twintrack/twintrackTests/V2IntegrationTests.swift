import Foundation
import XCTest
@testable import twintrack

@MainActor
final class V2IntegrationTests: XCTestCase {
    func testV2MatchesAll176PythonGoldenProfiles() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "golden_v2_final_1", withExtension: "json"))
        let file = try JSONDecoder().decode(V2Golden.self, from: Data(contentsOf: url))
        XCTAssertEqual(file.feature_order, TwinTrackFeature.allCases.map(\.key))
        XCTAssertEqual(file.model_version, TwinTrackModel.version)
        XCTAssertEqual(file.profiles.count, 176)
        var maximum = 0.0
        for fixture in file.profiles {
            let v = try TwinTrackFeature.allCases.map { try XCTUnwrap(fixture.inputs[$0.key]) }
            let p = TwinTrackProfile(sleepHours: v[0], steps: v[1], exerciseMinutes: v[2], restingHeartRate: v[3], studyMinutes: v[4], screenTimeMinutes: v[5], previousScore: v[6])
            let raw = TwinTrackModel.predictRaw(p), clipped = TwinTrackModel.predict(p)
            XCTAssertTrue(raw.isFinite && clipped.isFinite)
            XCTAssertEqual(raw, fixture.expected_raw, accuracy: file.tolerance, fixture.name)
            XCTAssertEqual(clipped, fixture.expected_clamped, accuracy: file.tolerance, fixture.name)
            XCTAssertEqual(TwinTrackFeature.allCases.allSatisfy { WhatIfScenario.isValid(v[$0.rawValue], for: $0) }, fixture.allowed)
            maximum = max(maximum, abs(raw - fixture.expected_raw), abs(clipped - fixture.expected_clamped))
        }
        print("V2 GOLDEN PARITY: 176/176; maximum absolute error: \(maximum)")
    }

    func testHorizonPriorAgeAndManualDayBoundaries() {
        let now = Date(), calendar = Calendar.current
        for (horizon, valid) in [(0, false), (1, true), (7, true), (8, false)] {
            XCTAssertEqual(V2PredictionContext.fixture(now: now, horizon: horizon).issue(now: now, calendar: calendar) == nil, valid)
        }
        for (age, valid) in [(0, false), (1, true), (90, true), (91, false)] {
            XCTAssertEqual(V2PredictionContext.fixture(now: now, priorAge: age).issue(now: now, calendar: calendar) == nil, valid)
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        XCTAssertNotNil(V2PredictionContext.fixture(now: now).issue(now: tomorrow, calendar: calendar))
    }

    func testLegacyManualEntryCannotPredictUntilReconfirmed() async throws {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        await state.requestHealthAccess()
        XCTAssertTrue(state.saveManualInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80))
        XCTAssertFalse(state.runPrediction())
        XCTAssertNotNil(state.v2EligibilityIssue())
        XCTAssertTrue(state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80))
        XCTAssertTrue(state.runPrediction())
        XCTAssertEqual(state.lastPrediction?.modelVersion, TwinTrackModel.version)
    }

    func testPersistenceKeepsContextAndVersionAndDoesNotRelabelV1() async throws {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertTrue(state.runPrediction())
        let restored = TwinTrackState(defaults: defaults, healthService: V2HealthFixture())
        XCTAssertEqual(restored.predictionContext, state.predictionContext)
        XCTAssertEqual(restored.predictionHistory, state.predictionHistory)
        let saved = try XCTUnwrap(state.lastPrediction)
        let legacy = PredictionSnapshot(createdAt: saved.createdAt, prediction: 63.25, inputs: saved.inputs, healthWindow: saved.healthWindow)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any])
        json.removeValue(forKey: "modelVersion"); json.removeValue(forKey: "predictionContext")
        let decoded = try JSONDecoder().decode(PredictionSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.modelVersion)
        XCTAssertTrue(decoded.modelLabel.contains("V1"))
        XCTAssertEqual(decoded.prediction, 63.25)
        XCTAssertFalse(decoded.hasSameSourceIdentity(as: saved))
    }

    func testTargetIdentityAndReconfirmationInvalidateReuse() async throws {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        state.runPrediction()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80, context: .fixture(assessmentName: "Another synthetic quiz"))
        XCTAssertEqual(state.predictionStatus(), .stale)
        state.runPrediction()
        XCTAssertEqual(state.predictionHistory.count, 2)
    }

    func testUnavailableHealthStaleScoreAndUnsupportedValuesNeverGenerate() async {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertFalse(state.runPrediction())
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80, context: .fixture(priorAge: 91))
        XCTAssertFalse(state.runPrediction())
        state.saveV2TestInputs(studyMinutes: 400, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertFalse(state.runPrediction())
        XCTAssertEqual(state.studyMinutes, 400)
        XCTAssertTrue(state.predictionHistory.isEmpty)
    }

    func testAssistantCurrentAndWhatIfUseSameEligibleV2Baseline() async throws {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        state.runPrediction()
        let run = AssistantToolRun(snapshot: AssistantSnapshot(state: state), userMessage: "add 30 minutes of study")
        _ = try run.readCurrent()
        XCTAssertEqual(run.cards.last?.prediction, state.lastPrediction?.prediction)
        _ = try run.runScenario(.init(changes: [.init(feature: .study_minutes, operation: .increase, unit: .minutes, value: 30, evidence: "add 30 minutes of study")]))
        XCTAssertEqual(run.cards.last?.kind, .scenario)
        XCTAssertEqual(run.cards.last?.baseline, state.lastPrediction?.prediction)
        XCTAssertEqual(try XCTUnwrap(run.cards.last?.delta), 30 * TwinTrackModel.coefficient[4] / TwinTrackModel.scale[4], accuracy: 1e-10)
        XCTAssertEqual(state.studyMinutes, 90)
        XCTAssertEqual(state.predictionHistory.count, 1)
    }

    func testScenarioRejectsOutsideSupportAndAllSevenBoundsAreFinite() throws {
        for feature in TwinTrackFeature.allCases {
            let range = TwinTrackModel.bounds[feature.rawValue]
            XCTAssertTrue(WhatIfScenario.isValid(range.lowerBound, for: feature))
            XCTAssertTrue(WhatIfScenario.isValid(range.upperBound, for: feature))
            for bad in [Double.nan, .infinity, range.lowerBound - 1, range.upperBound + 1] {
                XCTAssertFalse(WhatIfScenario.isValid(bad, for: feature))
            }
        }
    }

    func testCalendarDSTAndTimezoneReconfirmation() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let now = calendar.date(from: .init(year: 2026, month: 11, day: 1, hour: 12))!
        let context = V2PredictionContext.fixture(now: now, calendar: calendar)
        XCTAssertNil(context.issue(now: now, calendar: calendar))
        calendar.timeZone = TimeZone(identifier: "Asia/Dubai")!
        XCTAssertNotNil(context.issue(now: now, calendar: calendar))
    }

    func testLegacyDefaultsRemainVisibleButCorruptV2NeverFallsBack() async {
        let (_, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        defaults.set(90, forKey: "twintrack.manual.study_minutes")
        defaults.set(120, forKey: "twintrack.manual.screen_time_minutes")
        defaults.set(80, forKey: "twintrack.manual.previous_score")
        let legacy = TwinTrackState(defaults: defaults, healthService: V2HealthFixture())
        await legacy.requestHealthAccess()
        XCTAssertEqual(legacy.studyMinutes, 90)
        XCTAssertNil(legacy.predictionContext)
        XCTAssertFalse(legacy.runPrediction())
        defaults.set(Data("invalid V2 payload".utf8), forKey: "twintrack.manual.v2.entry")
        let corrupt = TwinTrackState(defaults: defaults, healthService: V2HealthFixture())
        XCTAssertNil(corrupt.studyMinutes)
        XCTAssertNil(corrupt.previousScore)
        XCTAssertFalse(corrupt.runPrediction())
    }

    func testNewDayRefreshCannotSilentlyRedateManualInputs() async {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        let now = Date(), calendar = Calendar.current
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80, now: now)
        XCTAssertTrue(state.runPrediction(now: now))
        let saved = state.lastPrediction
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        await state.refreshHealth(now: tomorrow, calendar: calendar)
        XCTAssertFalse(state.runPrediction(now: tomorrow, calendar: calendar))
        XCTAssertEqual(state.lastPrediction, saved)
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80, now: tomorrow)
        XCTAssertTrue(state.runPrediction(now: tomorrow, calendar: calendar))
        XCTAssertEqual(state.predictionHistory.count, 2)
    }

    func testMixedVersionTrendAndAssistantHistoryDoNotCompareScores() async throws {
        let (state, defaults, key) = fixture(); defer { defaults.removePersistentDomain(forName: key) }
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        state.runPrediction()
        let v2 = try XCTUnwrap(state.lastPrediction)
        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: v2.createdAt)!
        let v1 = PredictionSnapshot(createdAt: previousDay, prediction: 63.25, inputs: v2.inputs, healthWindow: nil)
        let points = PredictionHistoryTrend.points(from: [v1, v2], now: v2.createdAt, calendar: calendar)
        XCTAssertEqual(points.count, 2)
        XCTAssertNil(PredictionTrendPresentation.summary(points: points).delta)
        let tool = AssistantToolRun(snapshot: AssistantSnapshot(history: [v1, v2], capturedAt: v2.createdAt), userMessage: "Show my history")
        _ = try tool.readHistory(.init(scope: .sevenDays, localDate: ""))
        XCTAssertNil(tool.cards.last?.delta)
        XCTAssertTrue(tool.cards.last?.fields.contains { $0.value.contains("V1") } == true)
        XCTAssertTrue(tool.cards.last?.fields.contains { $0.value.contains(TwinTrackModel.version) } == true)
    }

    private func fixture() -> (TwinTrackState, UserDefaults, String) {
        let key = "V2IntegrationTests.\(UUID())"
        let isolated = UserDefaults(suiteName: key)!
        return (TwinTrackState(defaults: isolated, healthService: V2HealthFixture()), isolated, key)
    }
}

extension V2PredictionContext {
    static func fixture(now: Date = Date(), calendar: Calendar = .current, horizon: Int = 3, priorAge: Int = 14, assessmentName: String = "Synthetic quiz") -> Self {
        let today = calendar.startOfDay(for: now)
        return Self(subject: "Synthetic maths", assessmentName: assessmentName,
            assessmentDate: calendar.date(byAdding: .day, value: horizon, to: today)!, previousDate: calendar.date(byAdding: .day, value: -priorAge, to: today)!,
            manualDay: calendar.date(byAdding: .day, value: -1, to: today)!, timeZoneIdentifier: calendar.timeZone.identifier,
            sameSubjectConfirmed: true, nextIndividualAssessmentConfirmed: true, latestComparablePriorConfirmed: true)
    }
}

extension TwinTrackState {
    @discardableResult
    func saveV2TestInputs(studyMinutes: Int?, screenTimeMinutes: Int?, previousScore: Double?, now: Date = Date(), context: V2PredictionContext? = nil) -> Bool {
        saveManualInputs(studyMinutes: studyMinutes, screenTimeMinutes: screenTimeMinutes, previousScore: previousScore, now: now, context: context ?? .fixture(now: now))
    }
}

@MainActor
private final class V2HealthFixture: HealthDataProviding {
    var isAvailable = true
    func requestAccess() async throws {}
    func read(window: HealthDataWindow) async -> HealthReadings {
        HealthReadings(sleep: .available(7.5), steps: .available(7000), exercise: .available(30), restingHeartRate: .available(65), restingHeartRateSampleDate: window.day.start)
    }
}

private struct V2Golden: Decodable {
    let model_version: String
    let feature_order: [String]
    let tolerance: Double
    let profiles: [Entry]
    struct Entry: Decodable {
        let name: String
        let inputs: [String: Double]
        let expected_raw: Double
        let expected_clamped: Double
        let allowed: Bool
    }
}
