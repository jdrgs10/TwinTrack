import Combine
import Foundation
import HealthKit
import XCTest
@testable import twintrack

@MainActor
final class HealthKitTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 0)

    private func sample(_ start: Double, _ end: Double, _ stage: HKCategoryValueSleepAnalysis) -> SleepInterval {
        SleepInterval(start: origin.addingTimeInterval(start * 3600),
                      end: origin.addingTimeInterval(end * 3600), category: stage.rawValue)
    }

    private var sleepWindow: DateInterval {
        DateInterval(start: origin, duration: 12 * 3600)
    }

    func testSleepCountsCoreDeepREMInHours() async {
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: [
            sample(0, 2, .asleepCore), sample(2, 3, .asleepDeep), sample(3, 4.5, .asleepREM),
        ]), 4.5)
    }

    func testSleepExcludesAwakeAndInBed() async {
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: [
            sample(0, 10, .inBed), sample(2, 4, .awake), sample(4, 6, .asleepCore),
        ]), 2)
    }

    func testSleepSupportsUnspecifiedWithoutDoublingStages() async {
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: [
            sample(1, 8, .asleepUnspecified), sample(1, 4, .asleepCore),
            sample(4, 5, .asleepDeep), sample(5, 8, .asleepREM),
        ]), 7)
    }

    func testSleepUnionHandlesDuplicatesContainmentAndChainedOverlap() async {
        let samples = [sample(1, 3, .asleepCore), sample(1, 3, .asleepCore),
                       sample(2, 2.5, .asleepDeep), sample(2, 5, .asleepREM),
                       sample(4, 7, .asleepUnspecified)]
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: samples), 6)
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: samples.reversed()), 6)
    }

    func testSleepClipsBothBoundariesAndPreservesGaps() async {
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: [
            sample(-2, 2, .asleepCore), sample(10, 14, .asleepUnspecified),
            sample(12, 15, .asleepREM), sample(-5, -2, .asleepDeep),
        ]), 4)
    }

    func testSleepEmptyAndAwakeOnlyStayMissing() async {
        XCTAssertNil(SleepAggregation.hours(in: sleepWindow, samples: []))
        XCTAssertNil(SleepAggregation.hours(in: sleepWindow, samples: [
            sample(0, 8, .inBed), sample(2, 4, .awake), sample(4, 4, .asleepCore),
        ]))
    }

    func testSleepConflictUsesDocumentedAsleepUnion() async {
        // A general source and a staged source can disagree. Awake does not add
        // duration, nor erase another source's asleep claim under the union policy.
        XCTAssertEqual(SleepAggregation.hours(in: sleepWindow, samples: [
            sample(1, 5, .asleepUnspecified), sample(2, 3, .awake),
        ]), 4)
    }

    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testTuesdayMorningUsesPreviousActivityDayAndCurrentOvernightSleep() async {
        let calendar = calendar("Asia/Dubai")
        let window = HealthDataWindow(now: date(2026, 9, 8, 10, in: calendar), calendar: calendar)
        XCTAssertEqual(window.day.start, date(2026, 9, 7, 0, in: calendar))
        XCTAssertEqual(window.day.end, date(2026, 9, 8, 0, in: calendar))
        XCTAssertEqual(window.sleep.start, date(2026, 9, 7, 12, in: calendar))
        XCTAssertEqual(window.sleep.end, date(2026, 9, 8, 10, in: calendar))
    }

    func testWindowsRollAtMidnightAndYearBoundary() async {
        let calendar = calendar("UTC")
        let midnight = date(2027, 1, 1, 0, in: calendar)
        let before = HealthDataWindow(now: midnight.addingTimeInterval(-1), calendar: calendar)
        let after = HealthDataWindow(now: midnight, calendar: calendar)
        XCTAssertEqual(before.day.end, after.day.start)
        XCTAssertEqual(after.day.start, date(2026, 12, 31, 0, in: calendar))
    }

    func testDayWindowsRespectSpringAndAutumnDST() async {
        let calendar = calendar("America/New_York")
        XCTAssertEqual(HealthDataWindow(now: date(2026, 3, 9, 8, in: calendar), calendar: calendar).day.duration, 23 * 3600)
        XCTAssertEqual(HealthDataWindow(now: date(2026, 11, 2, 8, in: calendar), calendar: calendar).day.duration, 25 * 3600)
    }

    func testSleepWindowsRespectDSTAndActualElapsedHours() async {
        let calendar = calendar("America/New_York")
        let spring = HealthDataWindow(now: date(2026, 3, 8, 13, in: calendar), calendar: calendar)
        let autumn = HealthDataWindow(now: date(2026, 11, 1, 13, in: calendar), calendar: calendar)
        XCTAssertEqual(spring.sleep.duration, 23 * 3600)
        XCTAssertEqual(autumn.sleep.duration, 25 * 3600)
        let samples = [SleepInterval(start: date(2026, 3, 7, 23, in: calendar),
                                     end: date(2026, 3, 8, 7, in: calendar),
                                     category: HKCategoryValueSleepAnalysis.asleepCore.rawValue)]
        XCTAssertEqual(SleepAggregation.hours(in: spring.sleep, samples: samples), 7)
    }

    func testTimeZoneIsCapturedForEachRefresh() async {
        let now = date(2026, 9, 8, 2, in: calendar("UTC"))
        let dubai = HealthDataWindow(now: now, calendar: calendar("Asia/Dubai"))
        let newYork = HealthDataWindow(now: now, calendar: calendar("America/New_York"))
        XCTAssertNotEqual(dubai.day, newYork.day)
        XCTAssertEqual(dubai.timeZone.identifier, "Asia/Dubai")
        XCTAssertEqual(newYork.timeZone.identifier, "America/New_York")
    }

    func testTuesdayNoonAndAfternoonCapSleepAtTodaysLocalNoon() {
        let calendar = calendar("Asia/Dubai")
        for hour in [12, 16, 23] {
            let window = HealthDataWindow(now: date(2026, 9, 8, hour, in: calendar), calendar: calendar)
            XCTAssertEqual(window.sleep.start, date(2026, 9, 7, 12, in: calendar))
            XCTAssertEqual(window.sleep.end, date(2026, 9, 8, 12, in: calendar))
            XCTAssertEqual(window.day.start, date(2026, 9, 7, 0, in: calendar))
            XCTAssertEqual(window.day.end, date(2026, 9, 8, 0, in: calendar))
        }
    }

    func testFreshSleepCrossesMidnightAndClipsAtMorningRefresh() {
        let calendar = calendar("Asia/Dubai")
        let window = HealthDataWindow(now: date(2026, 9, 8, 8, in: calendar), calendar: calendar)
        let samples = [SleepInterval(
            start: date(2026, 9, 7, 23, in: calendar),
            end: date(2026, 9, 8, 9, in: calendar),
            category: HKCategoryValueSleepAnalysis.asleepCore.rawValue
        )]
        XCTAssertEqual(SleepAggregation.hours(in: window.sleep, samples: samples), 9)
    }

    func testMorningSleepAndRHRWindowsAcrossDST() {
        let calendar = calendar("America/New_York")
        let spring = HealthDataWindow(now: date(2026, 3, 8, 8, in: calendar), calendar: calendar)
        let autumn = HealthDataWindow(now: date(2026, 11, 1, 8, in: calendar), calendar: calendar)
        XCTAssertEqual(spring.sleep.duration, 19 * 3600)
        XCTAssertEqual(autumn.sleep.duration, 21 * 3600)
        XCTAssertEqual(spring.restingHeartRate.duration, 72 * 3600)
        XCTAssertEqual(autumn.restingHeartRate.duration, 72 * 3600)
    }

    func testLatestValidRestingSampleSelectedAndTimestampRetained() {
        let window = HealthDataWindow(now: origin, calendar: calendar("UTC")).restingHeartRate
        let older = RestingHeartRateReading(bpm: 63, date: origin.addingTimeInterval(-48 * 3600))
        let latest = RestingHeartRateReading(bpm: 67, date: origin.addingTimeInterval(-3600))
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: [latest, older]), latest)
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: [older, latest]), latest)
    }

    func testInvalidNewestRestingSamplesDoNotHideOlderValidValue() {
        let window = HealthDataWindow(now: origin, calendar: calendar("UTC")).restingHeartRate
        let valid = RestingHeartRateReading(bpm: 63, date: origin.addingTimeInterval(-3600))
        let invalid = [0.0, -1, .nan, .infinity].map { RestingHeartRateReading(bpm: $0, date: origin) }
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: invalid + [valid]), valid)
        XCTAssertNil(RestingHeartRateSelection.latest(in: window, samples: invalid))
    }

    func testRestingRecencyIncludesExactly72HoursAndNowButRejectsOlderAndFuture() {
        let window = HealthDataWindow(now: origin, calendar: calendar("UTC")).restingHeartRate
        let cutoff = RestingHeartRateReading(bpm: 63, date: origin.addingTimeInterval(-72 * 3600))
        let current = RestingHeartRateReading(bpm: 66, date: origin)
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: [cutoff]), cutoff)
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: [cutoff, current]), current)
        XCTAssertNil(RestingHeartRateSelection.latest(in: window, samples: [
            RestingHeartRateReading(bpm: 60, date: window.start.addingTimeInterval(-1)),
            RestingHeartRateReading(bpm: 62, date: origin.addingTimeInterval(1)),
        ]))
        XCTAssertNil(RestingHeartRateSelection.latest(in: window, samples: []))
    }

    func testRestingTimestampTiesAreOrderIndependent() {
        let window = HealthDataWindow(now: origin, calendar: calendar("UTC")).restingHeartRate
        let first = RestingHeartRateReading(bpm: 63, date: origin)
        let second = RestingHeartRateReading(bpm: 65, date: origin)
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: [first, second]), second)
        XCTAssertEqual(RestingHeartRateSelection.latest(in: window, samples: [second, first]), second)
    }

    func testLaunchAndForegroundRefreshUseUpdatedSharedWindows() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        let service = TestHealthService()
        let state = TwinTrackState(defaults: defaults, healthService: service)
        let calendar = calendar("Asia/Dubai")
        let morning = date(2026, 9, 8, 8, in: calendar)
        await state.refreshHealth(now: morning, calendar: calendar)
        XCTAssertEqual(service.windows.last?.sleep.end, morning)
        XCTAssertEqual(service.windows.last?.day.end, date(2026, 9, 8, 0, in: calendar))
        state.healthSceneChanged(isActive: false)
        state.healthSceneChanged(isActive: true)
        await state.refreshHealth(now: date(2026, 9, 8, 15, in: calendar), calendar: calendar)
        XCTAssertEqual(service.reads, 2)
        XCTAssertEqual(service.windows.last?.sleep.end, date(2026, 9, 8, 12, in: calendar))
    }

    func testRestingTimestampUpdatesAndClearsWithSharedReadings() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.result = HealthReadings(restingHeartRate: .available(64), restingHeartRateSampleDate: origin)
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        XCTAssertEqual(state.healthReadings.restingHeartRateSampleDate, origin)
        service.result = HealthReadings()
        await state.refreshHealth()
        XCTAssertNil(state.restingHeartRate)
        XCTAssertNil(state.healthReadings.restingHeartRateSampleDate)
    }

    func testQuantityConversionsAndMissingUnits() async {
        XCTAssertEqual(HealthUnits.steps(HKQuantity(unit: .count(), doubleValue: 4321)), 4321)
        XCTAssertEqual(HealthUnits.exerciseMinutes(HKQuantity(unit: .second(), doubleValue: 1800)), 30)
        XCTAssertEqual(HealthUnits.restingBPM(HKQuantity(unit: .count().unitDivided(by: .second()), doubleValue: 1)), 60)
        XCTAssertNil(HealthUnits.steps(nil))
        XCTAssertNil(HealthUnits.exerciseMinutes(nil))
        XCTAssertNil(HealthUnits.restingBPM(nil))
        XCTAssertEqual(HealthUnits.steps(HKQuantity(unit: .count(), doubleValue: 0)), 0)
    }

    func testExactlyFourReadTypes() async {
        XCTAssertEqual(HealthKitService.readTypes.map(\.identifier).sorted(), [
            HKCategoryType(.sleepAnalysis).identifier, HKQuantityType(.stepCount).identifier,
            HKQuantityType(.appleExerciseTime).identifier, HKQuantityType(.restingHeartRate).identifier,
        ].sorted())
    }

    func testNoDataAndQueryFailuresRemainDifferent() async {
        XCTAssertEqual(HealthKitService.queryFailure(HKError(.errorNoData)), .missing)
        XCTAssertEqual(HealthKitService.queryFailure(HKError(.errorDatabaseInaccessible)), .failed)
        XCTAssertNil(HealthMetricResult.missing.value)
        XCTAssertNil(HealthMetricResult.failed.value)
        XCTAssertNil(HealthMetricResult.available(.nan).value)
    }

    private func defaults() -> (UserDefaults, String) {
        let name = "HealthKitTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    func testInitialLoadWaitsForExplicitRequest() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.refreshHealth()
        XCTAssertEqual(state.healthAccess, .notRequested)
        XCTAssertEqual(service.requests, 0)
        XCTAssertEqual(service.reads, 0)
        XCTAssertEqual(state.missingInputs.count, 7)
    }

    func testCompletedRequestWithNoDataDoesNotClaimDenial() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let state = TwinTrackState(defaults: defaults, healthService: TestHealthService())
        await state.requestHealthAccess()
        XCTAssertEqual(state.healthAccess, .completed)
        XCTAssertEqual(state.healthReadings, HealthReadings())
        XCTAssertNil(state.completeProfile)
    }

    func testHealthResultsUpdateExistingStateWithoutChangingManualInputs() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.result = HealthReadings(sleep: .available(7), steps: .available(5000),
                                       exercise: .available(30), restingHeartRate: .available(60))
        let state = TwinTrackState(defaults: defaults, healthService: service)
        XCTAssertTrue(state.saveManualInputs(studyMinutes: 90, screenTimeMinutes: 180, previousScore: 75))
        await state.requestHealthAccess()
        XCTAssertEqual(state.sleepHours, 7)
        XCTAssertEqual(state.steps, 5000)
        XCTAssertEqual(state.exerciseMinutes, 30)
        XCTAssertEqual(state.restingHeartRate, 60)
        XCTAssertEqual(state.completeProfile?.studyMinutes, 90)
        XCTAssertEqual(state.completeProfile?.screenTimeMinutes, 180)
        XCTAssertEqual(state.completeProfile?.previousScore, 75)
        XCTAssertTrue(state.missingInputs.isEmpty)
    }

    func testMissingRefreshClearsOldValuesAndKeepsMeasuredZero() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.result = HealthReadings(steps: .available(5000))
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        service.result = HealthReadings(exercise: .available(0), restingHeartRate: .failed)
        await state.refreshHealth()
        XCTAssertNil(state.steps)
        XCTAssertEqual(state.exerciseMinutes, 0)
        XCTAssertNil(state.restingHeartRate)
        XCTAssertEqual(state.healthReadings.restingHeartRate, .failed)
        XCTAssertTrue(state.missingInputs.contains(.steps))
        XCTAssertFalse(state.missingInputs.contains(.exerciseMinutes))
    }

    func testRecreationPersistsRequestCompletionButNotHealthValues() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.result = HealthReadings(steps: .available(5000))
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        let recreated = TwinTrackState(defaults: defaults, healthService: service)
        XCTAssertNil(recreated.steps)
        XCTAssertEqual(recreated.healthAccess, .completed)
        await recreated.refreshHealth()
        XCTAssertEqual(recreated.steps, 5000)
        XCTAssertEqual(service.requests, 1)
    }

    func testUnavailableAndFailedRequestNeverQuery() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.isAvailable = false
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        XCTAssertEqual(state.healthAccess, .unavailable)
        XCTAssertEqual(service.requests, 0)
        service.isAvailable = true
        service.shouldFailRequest = true
        await state.requestHealthAccess()
        XCTAssertEqual(state.healthAccess, .failed)
        XCTAssertEqual(service.reads, 0)
    }

    func testStaleRefreshCannotOverwriteNewForegroundResults() async throws {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        service.holdNextRead = true
        let stale = Task { await state.refreshHealth() }
        for _ in 0..<1000 {
            if service.pending != nil { break }
            await Task.yield()
        }
        let pending = try XCTUnwrap(service.pending)
        XCTAssertTrue(state.isRefreshingHealth)
        let reads = service.reads
        await state.refreshHealth()
        XCTAssertEqual(service.reads, reads, "Concurrent refreshes should coalesce.")
        state.healthSceneChanged(isActive: false)
        XCTAssertNil(state.steps)
        await state.refreshHealth()
        XCTAssertEqual(service.reads, reads, "Background scene must not start a query.")
        state.healthSceneChanged(isActive: true)
        service.result = HealthReadings(steps: .available(1234))
        await state.refreshHealth()
        pending.resume(returning: HealthReadings(steps: .available(9999)))
        service.pending = nil
        await stale.value
        XCTAssertEqual(state.steps, 1234)
        XCTAssertFalse(state.isRefreshingHealth)
    }

    func testRefreshPreservesCommittedStateUntilAllResultsArrive() async throws {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        let original = HealthReadings(sleep: .available(7), steps: .available(5000),
                                      exercise: .available(30), restingHeartRate: .available(60),
                                      restingHeartRateSampleDate: origin)
        service.result = original
        let state = TwinTrackState(defaults: defaults, healthService: service)
        state.saveManualInputs(studyMinutes: 90, screenTimeMinutes: 180, previousScore: 75)
        await state.requestHealthAccess()
        let originalWindow = state.healthWindow
        let historyCount = state.predictionHistory.count
        let refreshDate = origin.addingTimeInterval(86400)
        let refreshCalendar = calendar("UTC")
        var published: [HealthReadings] = []
        let observation = state.$healthReadings.sink { published.append($0) }
        defer { observation.cancel() }

        service.holdNextRead = true
        let refresh = Task { await state.refreshHealth(now: refreshDate, calendar: refreshCalendar) }
        for _ in 0..<1000 {
            if service.pending != nil { break }
            await Task.yield()
        }
        let pending = try XCTUnwrap(service.pending)
        XCTAssertTrue(state.isRefreshingHealth)
        XCTAssertEqual(state.healthReadings, original)
        XCTAssertEqual(state.healthWindow, originalWindow)
        XCTAssertEqual(state.healthAccess, .completed)
        XCTAssertEqual(state.studyMinutes, 90)
        XCTAssertEqual(state.screenTimeMinutes, 180)
        XCTAssertEqual(state.previousScore, 75)
        XCTAssertEqual(state.predictionHistory.count, historyCount)
        XCTAssertEqual(published, [original])

        let updated = HealthReadings(sleep: .available(8), steps: .available(6000),
                                     exercise: .available(40), restingHeartRate: .available(62),
                                     restingHeartRateSampleDate: refreshDate)
        pending.resume(returning: updated)
        service.pending = nil
        await refresh.value
        XCTAssertEqual(published, [original, updated], "No empty or partial health snapshot may be published.")
        XCTAssertEqual(state.healthWindow, HealthDataWindow(now: refreshDate, calendar: refreshCalendar))
        XCTAssertEqual(state.healthReadings, updated)
        XCTAssertEqual(state.healthAccess, .completed)
        XCTAssertFalse(state.isRefreshingHealth)
        XCTAssertEqual(service.requests, 1)
        XCTAssertEqual(state.studyMinutes, 90)
        XCTAssertEqual(state.screenTimeMinutes, 180)
        XCTAssertEqual(state.previousScore, 75)
        XCTAssertEqual(state.predictionHistory.count, historyCount + 1)
    }

    func testCancelledRefreshPreservesCommittedReadingsWindowAndSetup() async throws {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.result = HealthReadings(steps: .available(5000))
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        let original = state.healthReadings
        let window = state.healthWindow
        let history = state.predictionHistory
        service.holdNextRead = true
        let refresh = Task { await state.refreshHealth(now: origin) }
        for _ in 0..<1000 {
            if service.pending != nil { break }
            await Task.yield()
        }
        let pending = try XCTUnwrap(service.pending)
        refresh.cancel()
        pending.resume(returning: HealthReadings())
        service.pending = nil
        await refresh.value
        XCTAssertEqual(state.healthReadings, original)
        XCTAssertEqual(state.healthWindow, window)
        XCTAssertEqual(state.healthAccess, .completed)
        XCTAssertEqual(state.predictionHistory, history)
        XCTAssertFalse(state.isRefreshingHealth)
        service.result = HealthReadings(steps: .available(6000))
        await state.refreshHealth()
        XCTAssertEqual(state.steps, 6000, "A cancelled refresh must not block the next refresh.")
        XCTAssertEqual(service.requests, 1)
    }

    func testUnavailableMetricDoesNotEraseOtherResultsOrResetSetup() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        service.result = HealthReadings(sleep: .available(7), steps: .available(5000),
                                       exercise: .available(30), restingHeartRate: .available(60))
        let state = TwinTrackState(defaults: defaults, healthService: service)
        await state.requestHealthAccess()
        for unavailable in [HealthMetricResult.missing, .failed] {
            service.result = HealthReadings(sleep: unavailable, steps: .available(6000),
                                           exercise: .available(0), restingHeartRate: .available(62))
            await state.refreshHealth()
            XCTAssertNil(state.sleepHours)
            XCTAssertEqual(state.healthReadings.sleep, unavailable)
            XCTAssertEqual(state.steps, 6000)
            XCTAssertEqual(state.exerciseMinutes, 0, "Measured zero remains distinct from missing.")
            XCTAssertEqual(state.restingHeartRate, 62)
            XCTAssertEqual(state.healthAccess, .completed)
        }
        service.result = HealthReadings()
        await state.refreshHealth()
        XCTAssertEqual(state.healthReadings, HealthReadings())
        XCTAssertEqual(state.healthAccess, .completed)
        XCTAssertEqual(service.requests, 1)
    }

    func testCompletedSetupRefreshesWithoutRequestingAuthorizationAgain() async {
        let (defaults, name) = defaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let service = TestHealthService()
        let state = TwinTrackState(defaults: defaults, healthService: service)
        state.saveManualInputs(studyMinutes: 90, screenTimeMinutes: 180, previousScore: 75)
        await state.requestHealthAccess()
        service.shouldFailRequest = true
        await state.requestHealthAccess()
        await state.refreshHealth()
        state.healthSceneChanged(isActive: false)
        XCTAssertEqual(state.healthAccess, .completed)
        state.healthSceneChanged(isActive: true)
        await state.refreshHealth()
        let recreated = TwinTrackState(defaults: defaults, healthService: service)
        XCTAssertEqual(recreated.healthAccess, .completed)
        await recreated.refreshHealth()
        XCTAssertEqual(service.requests, 1, "Repeated setup, launch, foreground and pull refresh must not reauthorize.")
        XCTAssertEqual(service.reads, 5)
        XCTAssertEqual(recreated.healthAccess, .completed)
        XCTAssertEqual(recreated.studyMinutes, 90)
        XCTAssertEqual(recreated.screenTimeMinutes, 180)
        XCTAssertEqual(recreated.previousScore, 75)
    }
}

/// Only tests supply synthetic health values. This provider never enters production.
@MainActor
private final class TestHealthService: HealthDataProviding {
    var isAvailable = true
    var requests = 0
    var reads = 0
    var windows: [HealthDataWindow] = []
    var shouldFailRequest = false
    var result = HealthReadings()
    var holdNextRead = false
    var pending: CheckedContinuation<HealthReadings, Never>?

    func requestAccess() async throws {
        requests += 1
        if shouldFailRequest { throw HKError(.errorHealthDataRestricted) }
    }

    func read(window: HealthDataWindow) async -> HealthReadings {
        reads += 1
        windows.append(window)
        if holdNextRead {
            holdNextRead = false
            return await withCheckedContinuation { pending = $0 }
        }
        return result
    }
}
