import Foundation
import XCTest
@testable import twintrack

@MainActor
final class RestingHeartRateTrendTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c
    }
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 12))! }
    private func readings(_ recent: [Double?] = [60, 60, 60, 60, 60], missing: Set<Int> = [], flat: Bool = false) -> [RestingHeartRateReading] {
        let start = RestingHeartRateTrend.window(now: now, calendar: calendar).start
        return (0..<33).compactMap { i in
            guard !missing.contains(i), let value = i < 28 ? (flat ? 60 : Double(58 + i % 5)) : recent[i - 28] else { return nil }
            return RestingHeartRateReading(bpm: value, date: calendar.date(byAdding: .day, value: i, to: start)!.addingTimeInterval(3600))
        }
    }
    private func assess(_ recent: [Double?] = [60, 60, 60, 60, 60], missing: Set<Int> = [], flat: Bool = false) -> RestingHeartRateTrend {
        RestingHeartRateTrend.assess(samples: readings(recent, missing: missing, flat: flat), now: now, calendar: calendar)
    }

    func testEmptyDataRemainsUnavailable() {
        let r = RestingHeartRateTrend.assess(samples: [], now: now, calendar: calendar)
        XCTAssertEqual(r.state, .insufficient); XCTAssertEqual(r.baselineDays, 0); XCTAssertEqual(r.recentDays, 0)
    }
    func testNormalPersonalBaseline() {
        let r = assess(); XCTAssertEqual(r.state, .within); XCTAssertEqual(r.baselineDays, 28); XCTAssertEqual(r.recentDays, 5)
    }
    func testTemporaryOneDayDeviationIsNotPersistent() {
        XCTAssertEqual(assess([60, 60, 60, 60, 80]).state, .different)
    }
    func testThreeSameSideRecentDaysArePersistent() {
        let r = assess([80, 60, 80, 60, 80]); XCTAssertEqual(r.state, .persistent); XCTAssertEqual(r.direction, .higher)
    }
    func testPersistentLowerDirection() {
        let r = assess([40, 40, 60, 40, 60]); XCTAssertEqual(r.state, .persistent); XCTAssertEqual(r.direction, .lower)
    }
    func testOppositeSideExcursionPreventsPersistence() {
        let r = assess([80, 80, 40, 80, 60]); XCTAssertEqual(r.state, .different); XCTAssertEqual(r.direction, .varied)
    }
    func testTwoLatestInsideCalendarDaysReset() {
        XCTAssertEqual(assess([80, 80, 80, 60, 60]).state, .within)
    }
    func testOneInsideDayDoesNotReset() {
        XCTAssertEqual(assess([80, 80, 60, 80, 60]).state, .persistent)
    }
    func testMissingDayBreaksResetButDoesNotInventReading() {
        let r = assess([80, 80, 80, nil, 60]); XCTAssertEqual(r.state, .persistent); XCTAssertEqual(r.recentDays, 4)
    }
    func testMissingYesterdayImmediatelyInvalidatesTrend() {
        XCTAssertEqual(assess([80, 80, 80, 80, nil]).state, .insufficient)
    }
    func testThreeRecentDaysAreInsufficient() {
        XCTAssertEqual(assess([nil, nil, 80, 80, 80]).state, .insufficient)
    }
    func testTwentyBaselineDaysAreInsufficient() {
        XCTAssertEqual(assess(missing: Set([0, 1, 7, 8, 14, 15, 21, 22])).state, .insufficient)
    }
    func testTwentyOneSpreadBaselineDaysAreEnough() {
        XCTAssertEqual(assess(missing: Set([0, 1, 7, 8, 14, 15, 21])).state, .within)
    }
    func testBaselineWeeklyCoverageCannotBeReplacedByCluster() {
        let r = assess(missing: Set([0, 1, 2, 3])); XCTAssertEqual(r.baselineDays, 24); XCTAssertEqual(r.state, .insufficient)
    }
    func testZeroMADDoesNotInventFloor() {
        let r = assess(flat: true); XCTAssertEqual(r.state, .insufficient); XCTAssertTrue(r.rangeUnavailable)
    }
    func testExactRangeBoundaryIsInside() {
        // Baseline median 60, MAD 1 for the fixed fixture.
        XCTAssertEqual(assess([60 + 3 * 1.4826, 60 - 3 * 1.4826, 60, 60, 60 + 3 * 1.4826]).state, .within)
    }
    func testLatestPositiveSamplePerDayAndTimestampTieBreak() {
        var samples = readings([60, 60, 60, 60, 80])
        let last = samples.removeLast()
        samples += [last, RestingHeartRateReading(bpm: 60, date: last.date.addingTimeInterval(-1)),
                    RestingHeartRateReading(bpm: 0, date: last.date.addingTimeInterval(1)),
                    RestingHeartRateReading(bpm: .nan, date: last.date.addingTimeInterval(2)),
                    RestingHeartRateReading(bpm: .infinity, date: last.date.addingTimeInterval(3)),
                    RestingHeartRateReading(bpm: 59, date: last.date)]
        let r = RestingHeartRateTrend.assess(samples: samples, now: now, calendar: calendar)
        XCTAssertEqual(r.state, .different); XCTAssertEqual(r.recentDays, 5)
        XCTAssertEqual(r, RestingHeartRateTrend.assess(samples: samples.reversed(), now: now, calendar: calendar))
    }
    func testTodayAndOlderSamplesNeverSupplyCoverage() {
        let window = RestingHeartRateTrend.window(now: now, calendar: calendar)
        let samples = readings(missing: [32]) + [RestingHeartRateReading(bpm: 60, date: window.end),
            RestingHeartRateReading(bpm: 60, date: window.start.addingTimeInterval(-1))]
        XCTAssertEqual(RestingHeartRateTrend.assess(samples: samples, now: now, calendar: calendar).state, .insufficient)
    }
    func testCalendarWindowRespectsDSTAndTimeZone() {
        var c = calendar; c.timeZone = TimeZone(identifier: "America/New_York")!
        for (month, day, hours) in [(3, 10, 791.0), (11, 3, 793.0)] {
            let date = c.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
            let w = RestingHeartRateTrend.window(now: date, calendar: c)
            XCTAssertEqual(w.duration / 3600, hours)
            XCTAssertEqual(c.component(.hour, from: w.start), 0)
            XCTAssertEqual(c.dateComponents([.day], from: w.start, to: w.end).day, 33)
        }
        var dubai = calendar; dubai.timeZone = TimeZone(identifier: "Asia/Dubai")!
        XCTAssertNotEqual(RestingHeartRateTrend.window(now: now, calendar: calendar), RestingHeartRateTrend.window(now: now, calendar: dubai))
    }
    func testRepeatedDSTHourSelectsLatestAbsoluteInstant() {
        var c = calendar; c.timeZone = TimeZone(identifier: "America/New_York")!
        let date = c.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
        let w = RestingHeartRateTrend.window(now: date, calendar: c)
        var samples = (0..<33).map { i in
            RestingHeartRateReading(bpm: Double(58 + i % 5), date: c.date(byAdding: .day, value: i, to: w.start)!)
        }
        let day = c.date(byAdding: .day, value: -1, to: w.end)!
        samples += [RestingHeartRateReading(bpm: 60, date: day.addingTimeInterval(90 * 60)),
                    RestingHeartRateReading(bpm: 80, date: day.addingTimeInterval(150 * 60))]
        XCTAssertEqual(RestingHeartRateTrend.assess(samples: samples, now: date, calendar: c).state, .different)
    }
    func testLongGapAndRevisedRecordsRecomputeWithoutLatch() {
        let samples = readings([80, 80, 80, 80, 80])
        XCTAssertEqual(RestingHeartRateTrend.assess(samples: samples, now: now, calendar: calendar).state, .persistent)
        XCTAssertEqual(assess().state, .within)
        let later = calendar.date(byAdding: .day, value: 8, to: now)!
        XCTAssertEqual(RestingHeartRateTrend.assess(samples: samples, now: later, calendar: calendar).state, .insufficient)
    }
    func testTrendDoesNotUseAcademicBPMBounds() {
        let samples = readings().map { RestingHeartRateReading(bpm: $0.bpm + 100, date: $0.date) }
        XCTAssertEqual(RestingHeartRateTrend.assess(samples: samples, now: now, calendar: calendar).state, .within)
    }

    func testTrendRefreshCannotChangePredictionOrPersistHealthSamples() async throws {
        let key = "TwinTrack.RHRTests.\(UUID())", provider = TrendProvider()
        let defaults = UserDefaults(suiteName: key)!; defer { defaults.removePersistentDomain(forName: key) }
        let state = TwinTrackState(defaults: defaults, healthService: provider)
        provider.trend = assess()
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertTrue(state.runPrediction())
        let prediction = state.lastPrediction, history = state.predictionHistory, health = state.healthReadings
        let stored = defaults.persistentDomain(forName: key)! as NSDictionary
        provider.trend = assess([80, 80, 80, 80, 80])
        await state.refreshHealth()
        XCTAssertEqual(state.restingHeartRateTrend?.state, .persistent)
        XCTAssertEqual(state.lastPrediction, prediction); XCTAssertEqual(state.predictionHistory, history)
        XCTAssertEqual(state.healthReadings, health)
        XCTAssertEqual(stored, defaults.persistentDomain(forName: key)! as NSDictionary)
        let reopened = TwinTrackState(defaults: defaults, healthService: provider)
        XCTAssertNil(reopened.restingHeartRateTrend)
        provider.trend = nil
        await state.refreshHealth()
        XCTAssertNil(state.restingHeartRateTrend); XCTAssertEqual(state.restingHeartRate, 60)
    }
    func testFailureAndAccessRemovalClearOldTrend() async {
        let key = "TwinTrack.RHRTests.\(UUID())", provider = TrendProvider()
        let defaults = UserDefaults(suiteName: key)!; defer { defaults.removePersistentDomain(forName: key) }
        let state = TwinTrackState(defaults: defaults, healthService: provider)
        provider.trend = assess(); await state.requestHealthAccess()
        XCTAssertNotNil(state.restingHeartRateTrend)
        provider.trend = nil; await state.refreshHealth(); XCTAssertNil(state.restingHeartRateTrend)
        provider.trend = assess(); await state.refreshHealth(); XCTAssertNotNil(state.restingHeartRateTrend)
        provider.isAvailable = false; await state.refreshHealth(); XCTAssertNil(state.restingHeartRateTrend)
        XCTAssertNil(state.restingHeartRate)
    }
    func testSlowTrendDoesNotBlockFourMetricCommitAndCannotPublishAfterClear() async {
        let key = "TwinTrack.RHRTests.\(UUID())", provider = TrendProvider()
        let defaults = UserDefaults(suiteName: key)!; defer { defaults.removePersistentDomain(forName: key) }
        defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        let state = TwinTrackState(defaults: defaults, healthService: provider)
        provider.hold = true; provider.trend = assess()
        let started = expectation(description: "Trend query started")
        provider.didStart = { started.fulfill() }
        let task = Task { await state.refreshHealth() }
        await fulfillment(of: [started], timeout: 2)
        for _ in 0..<100 where state.healthWindow == nil { await Task.yield() }
        XCTAssertEqual(state.restingHeartRate, 60)
        XCTAssertFalse(state.isRefreshingHealth)
        state.clearHealthValues()
        provider.pending?.resume(returning: provider.trend); provider.pending = nil
        await task.value
        XCTAssertNil(state.restingHeartRateTrend); XCTAssertNil(state.restingHeartRate)
    }
    func testCancelledTrendNeverPublishes() async {
        let key = "TwinTrack.RHRTests.\(UUID())", provider = TrendProvider()
        let defaults = UserDefaults(suiteName: key)!; defer { defaults.removePersistentDomain(forName: key) }
        defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        let state = TwinTrackState(defaults: defaults, healthService: provider)
        provider.hold = true; provider.trend = assess()
        let started = expectation(description: "Trend query started"); provider.didStart = { started.fulfill() }
        let task = Task { await state.refreshHealth() }
        await fulfillment(of: [started], timeout: 2)
        task.cancel(); provider.pending?.resume(returning: provider.trend); provider.pending = nil
        await task.value
        XCTAssertNil(state.restingHeartRateTrend); XCTAssertFalse(state.isRefreshingHealth)
    }
    func testRHRAloneNeverRoutesToEmergency() async throws {
        let key = "TwinTrack.RHRTests.\(UUID())", provider = TrendProvider()
        let defaults = UserDefaults(suiteName: key)!; defer { defaults.removePersistentDomain(forName: key) }
        let state = TwinTrackState(defaults: defaults, healthService: provider)
        provider.trend = assess([80, 80, 80, 80, 80]); await state.requestHealthAccess()
        let client = TrendChatClient()
        let answer = try await FoundationAssistantService(client: client).respond(
            to: [AssistantMessage(role: .user, text: "Hi")], snapshot: AssistantSnapshot(state: state))
        XCTAssertNotEqual(answer.provenance?.origin, .urgent)
        XCTAssertFalse(answer.text.contains("999")); XCTAssertFalse(answer.text.contains("998"))
        XCTAssertNil(FoundationAssistantService.safetyFallback(for: AssistantFailure.safety,
            messages: [AssistantMessage(role: .user, text: "My resting heart rate has been higher than usual.")]))
        let scenarios: [[Double?]] = [[80, 80, 80, 80, 80], [40, 40, 40, 40, 40]]
        for recent in scenarios {
            let explanation = assess(recent).explanation.lowercased()
            for excluded in ["emergency", "dangerous", "critical", "diagnosed", "999", "998"] {
                XCTAssertFalse(explanation.contains(excluded))
            }
        }
    }
}

@MainActor
private final class TrendProvider: HealthDataProviding {
    var isAvailable = true
    var trend: RestingHeartRateTrend?
    var hold = false
    var didStart: (() -> Void)?
    var pending: CheckedContinuation<RestingHeartRateTrend?, Never>?
    func requestAccess() async throws {}
    func read(window: HealthDataWindow) async -> HealthReadings {
        HealthReadings(sleep: .available(7), steps: .available(5000), exercise: .available(30),
            restingHeartRate: .available(60), restingHeartRateSampleDate: window.day.start)
    }
    func readRestingHeartRateTrend(now: Date, calendar: Calendar) async -> RestingHeartRateTrend? {
        if hold {
            return await withCheckedContinuation { pending = $0; didStart?() }
        }
        return trend
    }
}

@MainActor
private final class TrendChatClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    func reply(to prompt: String, instructions: String) async throws -> String { "Hi! How can I help?" }
}
