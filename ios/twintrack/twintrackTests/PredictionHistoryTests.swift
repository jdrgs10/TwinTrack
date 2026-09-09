import Foundation
import XCTest
@testable import twintrack

@MainActor
final class PredictionHistoryTests: XCTestCase {
    func testHealthRefreshCreatesSnapshotOnlyAfterCompleteRealBaseline() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }

        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 120,
            screenTimeMinutes: 240,
            previousScore: 75
        ))
        XCTAssertTrue(fixture.state.predictionHistory.isEmpty)

        await fixture.state.requestHealthAccess()

        let snapshot = try XCTUnwrap(fixture.state.predictionHistory.only)
        let profile = try XCTUnwrap(fixture.state.completeProfile)
        XCTAssertEqual(snapshot.inputs, PredictionInputs(profile: profile))
        XCTAssertEqual(snapshot.prediction, TwinTrackModel.predict(profile), accuracy: 1e-12)
        XCTAssertNotNil(snapshot.healthWindow)
    }

    func testManualSaveCreatesSnapshotAfterHealthEstablishedBaseline() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        await fixture.state.requestHealthAccess()
        XCTAssertTrue(fixture.state.predictionHistory.isEmpty)

        let time = Date(timeIntervalSinceReferenceDate: 800_000_000)
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 120,
            screenTimeMinutes: 240,
            previousScore: 75,
            now: time
        ))

        XCTAssertEqual(fixture.state.predictionHistory.only?.createdAt, time)
    }

    func testEveryIncompleteBaselineDoesNotCreateSnapshot() async {
        for missing in TwinTrackFeature.allCases {
            let fixture = makeFixture()
            defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
            fixture.service.readings = healthReadings(missing: missing)
            XCTAssertTrue(fixture.state.saveManualInputs(
                studyMinutes: missing == .studyMinutes ? nil : 120,
                screenTimeMinutes: missing == .screenTimeMinutes ? nil : 240,
                previousScore: missing == .previousScore ? nil : 75
            ))

            await fixture.state.requestHealthAccess()

            XCTAssertTrue(fixture.state.predictionHistory.isEmpty, missing.key)
        }
    }

    func testSnapshotIsImmutableAfterLaterInputChanges() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await fixture.state.requestHealthAccess()
        let original = try XCTUnwrap(fixture.state.predictionHistory.only)

        XCTAssertTrue(fixture.state.setStudyTime(hours: 3, minutes: 0))

        XCTAssertEqual(fixture.state.predictionHistory.only, original)
        XCTAssertEqual(original.inputs.studyMinutes, 120)
    }

    func testWhatIfEvaluationNeverCreatesHistory() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await fixture.state.requestHealthAccess()
        let before = fixture.state.predictionHistory

        var scenario = try WhatIfScenario(baseline: fixture.state.completeProfile)
        try scenario.set(180, for: .studyMinutes)
        _ = scenario.evaluate()
        scenario.reset()

        XCTAssertEqual(fixture.state.predictionHistory, before)
    }

    func testLatestIdenticalInputsAndHealthWindowDoNotDuplicate() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 8, 10, calendar: calendar)
        fixture.defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75, now: now
        ))

        await fixture.state.refreshHealth(now: now, calendar: calendar)
        await fixture.state.refreshHealth(
            now: date(2026, 9, 8, 18, calendar: calendar),
            calendar: calendar
        )
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 120,
            screenTimeMinutes: 240,
            previousScore: 75,
            now: date(2026, 9, 8, 19, calendar: calendar)
        ))

        XCTAssertEqual(fixture.state.predictionHistory.count, 1)
    }

    func testReturningToOlderInputsCreatesNewLegitimateSnapshot() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        await fixture.state.requestHealthAccess()

        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 180, screenTimeMinutes: 240, previousScore: 75))
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))

        XCTAssertEqual(fixture.state.predictionHistory.count, 3)
    }

    func testHistoryPersistsAcrossStateRecreation() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await fixture.state.requestHealthAccess()
        let saved = try XCTUnwrap(fixture.state.predictionHistory.only)

        let recreated = TwinTrackState(defaults: fixture.defaults, healthService: fixture.service)

        XCTAssertEqual(recreated.predictionHistory.only, saved)
    }

    func testEmptyAndPartialTrendContainOnlyRealSavedDays() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 8, 12, calendar: calendar)
        XCTAssertTrue(PredictionHistoryTrend.points(from: [], now: now, calendar: calendar).isEmpty)

        let snapshots = [
            snapshot(at: date(2026, 9, 3, 9, calendar: calendar), score: 70),
            snapshot(at: date(2026, 9, 7, 9, calendar: calendar), score: 80),
        ]
        let points = PredictionHistoryTrend.points(from: snapshots, now: now, calendar: calendar)

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points.map(\.snapshot.prediction), [70, 80])
        XCTAssertEqual(PredictionHistoryTrend.days(now: now, calendar: calendar).count, 7)
    }

    func testSevenDayWindowIncludesLocalStartAndExcludesOutsideBoundaries() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 8, 12, calendar: calendar)
        let start = date(2026, 9, 2, 0, calendar: calendar)
        let tomorrow = date(2026, 9, 9, 0, calendar: calendar)
        let snapshots = [
            snapshot(at: start.addingTimeInterval(-1), score: 60),
            snapshot(at: start, score: 70),
            snapshot(at: tomorrow.addingTimeInterval(-1), score: 80),
            snapshot(at: tomorrow, score: 90),
        ]

        let points = PredictionHistoryTrend.points(from: snapshots, now: now, calendar: calendar)

        XCTAssertEqual(points.map(\.snapshot.prediction), [70, 80])
    }

    func testConsecutiveLocalDaysRemainSeparateAndChronological() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 8, 12, calendar: calendar)
        let snapshots = [
            snapshot(at: date(2026, 9, 7, 23, calendar: calendar), score: 71),
            snapshot(at: date(2026, 9, 8, 0, calendar: calendar), score: 72),
        ]

        let points = PredictionHistoryTrend.points(from: snapshots, now: now, calendar: calendar)

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points.map(\.snapshot.prediction), [71, 72])
        XCTAssertEqual(calendar.component(.day, from: points[0].day), 7)
        XCTAssertEqual(calendar.component(.day, from: points[1].day), 8)
    }

    func testTrendUsesCalendarDaysAcrossDaylightSavingBoundary() throws {
        let calendar = calendar(timeZone: "America/Los_Angeles")
        let now = date(2025, 11, 3, 12, calendar: calendar)
        let days = PredictionHistoryTrend.days(now: now, calendar: calendar)

        XCTAssertEqual(days.count, 7)
        let novemberSecond = try XCTUnwrap(days.first { calendar.component(.day, from: $0) == 2 })
        let novemberThird = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: novemberSecond))
        XCTAssertEqual(novemberThird.timeIntervalSince(novemberSecond), 25 * 60 * 60)
    }

    func testSevenLocalDaySlotsUseRequestedLabelsAndChronologicalMapping() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 6, 12, calendar: calendar)
        let days = PredictionHistoryTrend.days(now: now, calendar: calendar)
        let snapshots = [
            snapshot(at: date(2026, 9, 1, 8, calendar: calendar), score: 71),
            snapshot(at: date(2026, 9, 5, 21, calendar: calendar), score: 82),
        ]
        let points = PredictionHistoryTrend.points(from: snapshots, now: now, calendar: calendar)
        let slots = PredictionTrendPresentation.slots(days: days, points: points)

        XCTAssertEqual(slots.count, 7)
        XCTAssertEqual(slots.map { PredictionTrendPresentation.dayLabel($0.day, calendar: calendar) },
                       ["M", "T", "W", "Th", "F", "S", "Su"])
        XCTAssertEqual(slots.compactMap(\.point?.snapshot.prediction), [71, 82])
        XCTAssertEqual(slots[1].point?.snapshot, snapshots[0])
        XCTAssertEqual(slots[5].point?.snapshot, snapshots[1])
    }

    func testMissingDaySlotsNeverReceiveFabricatedPredictionOrSelection() throws {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 6, 12, calendar: calendar)
        let snapshot = snapshot(at: date(2026, 9, 4, 10, calendar: calendar), score: 78)
        let points = PredictionHistoryTrend.points(from: [snapshot], now: now, calendar: calendar)
        let slots = PredictionTrendPresentation.slots(
            days: PredictionHistoryTrend.days(now: now, calendar: calendar),
            points: points
        )

        XCTAssertEqual(slots.compactMap(\.point).count, 1)
        XCTAssertEqual(slots.filter { $0.point == nil }.count, 6)
        let missing = try XCTUnwrap(slots.first(where: { $0.point == nil }))
        XCTAssertNil(missing.point?.snapshot)
    }

    func testBarHeightUsesOneConsistentZeroToOneHundredScale() {
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: 0), 0)
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: 50), 36)
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: 80), 57.6, accuracy: 1e-12)
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: 82), 59.04, accuracy: 1e-12)
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: 100), 72)
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: -1), 0)
        XCTAssertEqual(PredictionTrendPresentation.barHeight(prediction: 101), 72)
    }

    func testSelectingRealBarReturnsExactImmutableSnapshotAndDefaultsToLatest() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let first = snapshot(at: date(2026, 9, 4, 9, calendar: calendar), score: 74)
        let latest = snapshot(at: date(2026, 9, 6, 18, calendar: calendar), score: 83)
        let points = PredictionHistoryTrend.points(
            from: [first, latest],
            now: date(2026, 9, 6, 20, calendar: calendar),
            calendar: calendar
        )

        XCTAssertEqual(PredictionTrendPresentation.selectedPoint(id: nil, points: points)?.snapshot, latest)
        XCTAssertEqual(
            PredictionTrendPresentation.selectedPoint(id: first.id, points: points)?.snapshot,
            first
        )
    }

    func testDetailRowsDisplayExactSevenSavedInputs() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let profile = TwinTrackProfile(
            sleepHours: 7.5,
            steps: 7840,
            exerciseMinutes: 31,
            restingHeartRate: 64,
            studyMinutes: 130,
            screenTimeMinutes: 185,
            previousScore: 82
        )
        let saved = snapshot(
            at: date(2026, 9, 6, 18, calendar: calendar),
            score: 84.2,
            profile: profile
        )
        let rows = PredictionHistoryDetail.rows(snapshot: saved)

        XCTAssertEqual(rows, [
            PredictionHistoryDetailRow(id: "sleep", label: "Sleep", value: "7h 30m"),
            PredictionHistoryDetailRow(id: "steps", label: "Steps", value: "7,840"),
            PredictionHistoryDetailRow(id: "exercise", label: "Exercise", value: "31 min"),
            PredictionHistoryDetailRow(id: "restingHeartRate", label: "Resting Heart Rate", value: "64 bpm"),
            PredictionHistoryDetailRow(id: "study", label: "Study", value: "2h 10m"),
            PredictionHistoryDetailRow(id: "screenTime", label: "Screen Time", value: "3h 5m"),
            PredictionHistoryDetailRow(id: "previousScore", label: "Previous Score", value: "82"),
        ])
        XCTAssertEqual(saved.inputs, PredictionInputs(profile: profile))
    }

    func testPreparingAndClosingReadOnlyDetailDoesNotMutateCurrentStateOrHistory() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await fixture.state.requestHealthAccess()
        let saved = try XCTUnwrap(fixture.state.predictionHistory.only)
        let currentValues = [
            fixture.state.sleepHours,
            fixture.state.steps,
            fixture.state.exerciseMinutes,
            fixture.state.restingHeartRate,
            fixture.state.studyMinutes.map(Double.init),
            fixture.state.screenTimeMinutes.map(Double.init),
            fixture.state.previousScore,
        ]
        let historyBefore = fixture.state.predictionHistory

        _ = PredictionHistoryDetail.rows(snapshot: saved)
        _ = PredictionHistoryDetailView(snapshot: saved)

        XCTAssertEqual([
            fixture.state.sleepHours,
            fixture.state.steps,
            fixture.state.exerciseMinutes,
            fixture.state.restingHeartRate,
            fixture.state.studyMinutes.map(Double.init),
            fixture.state.screenTimeMinutes.map(Double.init),
            fixture.state.previousScore,
        ], currentValues)
        XCTAssertEqual(fixture.state.predictionHistory, historyBefore)
        XCTAssertEqual(fixture.state.predictionHistory.count, 1)
    }

    func testTrendDeltaUsesEarliestAndLatestRealPointsOnly() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 6, 20, calendar: calendar)
        let points = PredictionHistoryTrend.points(from: [
            snapshot(at: date(2026, 9, 1, 9, calendar: calendar), score: 79.3),
            snapshot(at: date(2026, 9, 3, 9, calendar: calendar), score: 40),
            snapshot(at: date(2026, 9, 6, 9, calendar: calendar), score: 84.2),
        ], now: now, calendar: calendar)

        let summary = PredictionTrendPresentation.summary(points: points)
        XCTAssertEqual(summary.description, "Prediction increased across available days")
        XCTAssertEqual(try XCTUnwrap(summary.delta), 4.9, accuracy: 1e-12)
    }

    func testInsufficientAndStableHistoryProduceHonestTrendStates() {
        let calendar = calendar(timeZone: "Asia/Dubai")
        let now = date(2026, 9, 6, 20, calendar: calendar)
        let onePoint = PredictionHistoryTrend.points(from: [
            snapshot(at: date(2026, 9, 6, 9, calendar: calendar), score: 80),
        ], now: now, calendar: calendar)
        XCTAssertEqual(
            PredictionTrendPresentation.summary(points: onePoint),
            PredictionTrendSummary(description: "Insufficient history for a trend", delta: nil)
        )

        let stable = PredictionHistoryTrend.points(from: [
            snapshot(at: date(2026, 9, 3, 9, calendar: calendar), score: 80),
            snapshot(at: date(2026, 9, 6, 9, calendar: calendar), score: 80.04),
        ], now: now, calendar: calendar)
        XCTAssertEqual(
            PredictionTrendPresentation.summary(points: stable).description,
            "Prediction remained relatively stable"
        )
    }

    func testSameDayKeepsAllHistoryButTrendUsesLatestSnapshot() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        let calendar = calendar(timeZone: "Asia/Dubai")
        let morning = date(2026, 9, 8, 9, calendar: calendar)
        let evening = date(2026, 9, 8, 18, calendar: calendar)
        fixture.defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        await fixture.state.refreshHealth(now: morning, calendar: calendar)
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75, now: morning
        ))
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 180, screenTimeMinutes: 240, previousScore: 75, now: evening
        ))

        XCTAssertEqual(fixture.state.predictionHistory.count, 2)
        let points = PredictionHistoryTrend.points(
            from: fixture.state.predictionHistory,
            now: evening,
            calendar: calendar
        )
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points.only?.snapshot, fixture.state.predictionHistory.last)
    }

    func testSameInputsWithNewCompletedHealthWindowCreateNewSnapshot() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        let calendar = calendar(timeZone: "Asia/Dubai")
        fixture.defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        XCTAssertTrue(fixture.state.saveManualInputs(
            studyMinutes: 120,
            screenTimeMinutes: 240,
            previousScore: 75
        ))

        await fixture.state.refreshHealth(
            now: date(2026, 9, 8, 12, calendar: calendar),
            calendar: calendar
        )
        await fixture.state.refreshHealth(
            now: date(2026, 9, 9, 12, calendar: calendar),
            calendar: calendar
        )

        XCTAssertEqual(fixture.state.predictionHistory.count, 2)
        XCTAssertEqual(
            fixture.state.predictionHistory.map(\.inputs),
            Array(repeating: fixture.state.predictionHistory[0].inputs, count: 2)
        )
        XCTAssertNotEqual(
            fixture.state.predictionHistory[0].healthWindow,
            fixture.state.predictionHistory[1].healthWindow
        )
    }

    func testClearRemovesHistoryOnlyAndCancelLeavesItUnchanged() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await fixture.state.requestHealthAccess()
        let beforeCancel = fixture.state.predictionHistory

        // The confirmation dialog's Cancel action deliberately performs no mutation.
        XCTAssertEqual(fixture.state.predictionHistory, beforeCancel)
        XCTAssertTrue(fixture.state.clearPredictionHistory())

        XCTAssertTrue(fixture.state.predictionHistory.isEmpty)
        XCTAssertEqual(fixture.state.studyMinutes, 120)
        XCTAssertEqual(fixture.state.screenTimeMinutes, 240)
        XCTAssertEqual(fixture.state.previousScore, 75)
        XCTAssertEqual(fixture.state.healthReadings, fixture.service.readings)
        let recreated = TwinTrackState(defaults: fixture.defaults, healthService: fixture.service)
        XCTAssertTrue(recreated.predictionHistory.isEmpty)
        XCTAssertEqual(recreated.studyMinutes, 120)
    }

    func testStoredPredictionIsDefensivelyConsistentWithFrozenRidge() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertTrue(fixture.state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75))
        await fixture.state.requestHealthAccess()
        let snapshot = try XCTUnwrap(fixture.state.predictionHistory.only)

        XCTAssertEqual(snapshot.prediction, TwinTrackModel.predict(snapshot.inputs.profile), accuracy: 1e-12)
    }

    func testInvalidPersistedHistoryIsIgnored() throws {
        let name = "PredictionHistoryTests.invalid.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("not-json".utf8), forKey: "twintrack.prediction.history.v1")

        XCTAssertTrue(UserDefaultsPredictionHistoryStore(defaults: defaults).load().isEmpty)
    }

    private func makeFixture() -> (
        state: TwinTrackState,
        service: HistoryTestHealthService,
        defaults: UserDefaults,
        name: String
    ) {
        let name = "PredictionHistoryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let service = HistoryTestHealthService()
        return (TwinTrackState(defaults: defaults, healthService: service), service, defaults, name)
    }

    private func healthReadings(missing: TwinTrackFeature) -> HealthReadings {
        var readings = HistoryTestHealthService().readings
        switch missing {
        case .sleepHours: readings.sleep = .missing
        case .steps: readings.steps = .missing
        case .exerciseMinutes: readings.exercise = .missing
        case .restingHeartRate: readings.restingHeartRate = .missing
        case .studyMinutes, .screenTimeMinutes, .previousScore: break
        }
        return readings
    }

    private func snapshot(
        at date: Date,
        score: Double,
        profile: TwinTrackProfile = TwinTrackProfile(
            sleepHours: 7,
            steps: 6500,
            exerciseMinutes: 30,
            restingHeartRate: 68,
            studyMinutes: 120,
            screenTimeMinutes: 240,
            previousScore: 75
        )
    ) -> PredictionSnapshot {
        PredictionSnapshot(
            createdAt: date,
            prediction: score,
            inputs: PredictionInputs(profile: profile),
            healthWindow: nil
        )
    }

    private func calendar(timeZone identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }
}

@MainActor
private final class HistoryTestHealthService: HealthDataProviding {
    var isAvailable = true
    var readings = HealthReadings(
        sleep: .available(7),
        steps: .available(6500),
        exercise: .available(30),
        restingHeartRate: .available(68)
    )

    func requestAccess() async throws {}

    func read(window: HealthDataWindow) async -> HealthReadings {
        readings
    }
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
