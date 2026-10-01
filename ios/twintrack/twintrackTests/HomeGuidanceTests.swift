import Foundation
import XCTest
@testable import twintrack

@MainActor
final class HomeGuidanceTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Dubai")!
        return value
    }
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 14))!
    }

    func testMissingManualValueSelectsItsOwnReviewField() async {
        for field in [ManualReviewField.study, .screen, .previousScore] {
            let fixture = makeFixture()
            defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
            fixture.state.saveManualInputs(studyMinutes: field == .study ? nil : 120,
                screenTimeMinutes: field == .screen ? nil : 180,
                previousScore: field == .previousScore ? nil : 80, context: context())
            await fixture.state.refreshHealth(now: now, calendar: calendar)
            XCTAssertEqual(guidance(fixture.state).action, .manual(field))
            XCTAssertEqual(guidance(fixture.state).actionTitle, "Update Manual Inputs")
            XCTAssertEqual(fixture.state.predictionStatus(now: now, calendar: calendar), .missing)
        }
    }

    func testAssessmentProblemsSelectTheirExactFields() async {
        let cases: [(V2PredictionContext, ManualReviewField)] = [
            (context(subject: " "), .subject),
            (context(assessment: ""), .assessment),
            (context(horizon: 0), .assessmentDate),
            (context(previousAge: 91), .previousDate),
            (context(confirmed: false), .confirmation)
        ]
        for (context, field) in cases {
            let fixture = makeFixture()
            defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
            saveCompleteManual(fixture.state, context: context)
            await fixture.state.refreshHealth(now: now, calendar: calendar)
            XCTAssertEqual(guidance(fixture.state).action, .manual(field))
            XCTAssertEqual(guidance(fixture.state).actionTitle, "Complete assessment information")
        }
    }

    func testMultipleMissingValuesHaveStableFirstActionWithoutFillingAnything() {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        XCTAssertEqual(guidance(fixture.state).action, .manual(.study))
        XCTAssertNil(fixture.state.studyMinutes)
        XCTAssertNil(fixture.state.screenTimeMinutes)
        XCTAssertNil(fixture.state.previousScore)
        XCTAssertTrue(fixture.state.predictionHistory.isEmpty)
    }

    func testStoredManualDurationOutsideModelSupportDirectsToItsFieldWithoutChangingIt() async {
        for (feature, field) in [(TwinTrackFeature.studyMinutes, ManualReviewField.study),
                                 (.screenTimeMinutes, .screen)] {
            let fixture = makeFixture()
            defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
            let unsupported = Int(TwinTrackModel.bounds[feature.rawValue].upperBound) + 1
            XCTAssertTrue(fixture.state.saveManualInputs(
                studyMinutes: field == .study ? unsupported : 120,
                screenTimeMinutes: field == .screen ? unsupported : 180,
                previousScore: 80, context: context()))
            await fixture.state.refreshHealth(now: now, calendar: calendar)
            XCTAssertEqual(guidance(fixture.state).action, .manual(field))
            XCTAssertFalse(fixture.state.runPrediction(now: now, calendar: calendar))
            XCTAssertEqual(field == .study ? fixture.state.studyMinutes : fixture.state.screenTimeMinutes, unsupported)
            XCTAssertTrue(fixture.state.predictionHistory.isEmpty)
        }
    }

    func testReconfirmationDirectsToStudyAndDoesNotChangeSavedSourceDay() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        let olderContext = context(manualAge: 2)
        saveCompleteManual(fixture.state, context: olderContext)
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        let before = fixture.defaults.data(forKey: "twintrack.manual.v2.entry")
        XCTAssertEqual(guidance(fixture.state).action, .manual(.study))
        XCTAssertEqual(fixture.state.predictionContext, olderContext)
        XCTAssertEqual(fixture.state.studyMinutes, 120)
        XCTAssertEqual(fixture.defaults.data(forKey: "twintrack.manual.v2.entry"), before)
        let reopened = TwinTrackState(defaults: fixture.defaults, healthService: fixture.health)
        XCTAssertEqual(reopened.predictionContext, olderContext)
        XCTAssertEqual(reopened.screenTimeMinutes, 180)
    }

    func testMissingHealthDirectsToHealthAndDoesNotClaimDeniedPermission() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        fixture.health.readings.sleep = .missing
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        let value = guidance(fixture.state)
        XCTAssertEqual(value.action, .health)
        XCTAssertEqual(value.actionTitle, "Review Apple Health")
        XCTAssertEqual(value.healthLabel, "Apple Health · 3/4 values available")
        XCTAssertEqual(value.stateLine, "Health inputs unavailable")
        XCTAssertNil(fixture.state.sleepHours)
        XCTAssertFalse((value.healthLabel + value.stateLine).lowercased().contains("denied"))
    }

    func testCompletedAuthorizationWithNoReadingsDoesNotClaimConnected() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        fixture.health.readings = HealthReadings()
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertEqual(fixture.state.healthAccess, .completed)
        XCTAssertEqual(guidance(fixture.state).availableHealthCount, 0)
        XCTAssertEqual(guidance(fixture.state).healthLabel, "Apple Health · 0/4 values available")
        XCTAssertEqual(guidance(fixture.state).action, .health)
        XCTAssertNil(fixture.state.completeProfile)
    }

    func testUnrequestedAndUnsupportedHealthDirectToExistingHealthScreen() async {
        let fixture = makeFixture(requestCompleted: false)
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        XCTAssertEqual(guidance(fixture.state).action, .health)
        XCTAssertEqual(guidance(fixture.state).healthLabel, "Apple Health · Review access")
        fixture.health.isAvailable = false
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertEqual(guidance(fixture.state).action, .health)
        XCTAssertEqual(guidance(fixture.state).healthLabel, "Apple Health · Unavailable here")
    }

    func testFailedReadOffersRefreshWithoutRepeatingAuthorization() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        fixture.health.readings.exercise = .failed
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertEqual(guidance(fixture.state).action, .refresh)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Refresh Health inputs")
        XCTAssertEqual(fixture.health.authorizationCount, 0)
    }

    func testExpiredHealthWithReviewedManualValuesOffersRefresh() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        await fixture.state.refreshHealth(now: yesterday, calendar: calendar)
        saveCompleteManual(fixture.state)
        XCTAssertEqual(fixture.state.predictionStatus(now: now, calendar: calendar), .needsRefresh)
        XCTAssertEqual(guidance(fixture.state).action, .refresh)
    }

    func testReadyGuidanceDoesNotRunAndSavedMatchingInputsDoNotOfferDuplicateRun() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertEqual(guidance(fixture.state).action, .run)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Current inputs ready")
        XCTAssertNil(fixture.state.lastPrediction)
        XCTAssertTrue(fixture.state.predictionHistory.isEmpty)
        XCTAssertTrue(fixture.state.runPrediction(now: now, calendar: calendar))
        let saved = try XCTUnwrap(fixture.state.lastPrediction)
        XCTAssertEqual(guidance(fixture.state).action, .none)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Saved estimate · Inputs match")
        XCTAssertEqual(fixture.state.predictionHistory, [saved])
    }

    func testHealthChangeOffersExplicitRunAndKeepsSavedEstimateHistorical() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertTrue(fixture.state.runPrediction(now: now, calendar: calendar))
        let saved = try XCTUnwrap(fixture.state.lastPrediction)
        fixture.health.readings.steps = .available(7000)
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertEqual(guidance(fixture.state).action, .run)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Saved estimate · Inputs changed")
        XCTAssertEqual(fixture.state.lastPrediction, saved)
        XCTAssertEqual(fixture.state.predictionHistory, [saved])
        fixture.health.readings.sleep = .missing
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Saved estimate · Health inputs unavailable")
        XCTAssertEqual(fixture.state.predictionHistory, [saved])
    }

    func testRefreshInFlightOffersNoCompetingAction() async throws {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        fixture.health.hold = true
        let task = Task { await fixture.state.refreshHealth(now: now, calendar: calendar) }
        for _ in 0..<1000 { if fixture.health.pending != nil { break }; await Task.yield() }
        let pending = try XCTUnwrap(fixture.health.pending)
        XCTAssertEqual(guidance(fixture.state).action, .none)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Refreshing inputs")
        pending.resume(returning: fixture.health.readings)
        await task.value
        XCTAssertEqual(guidance(fixture.state).action, .run)
    }

    func testAvailableButUnsupportedHealthValueNeverOffersRun() async {
        let fixture = makeFixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
        saveCompleteManual(fixture.state)
        fixture.health.readings.sleep = .available(55)
        await fixture.state.refreshHealth(now: now, calendar: calendar)
        XCTAssertNotNil(fixture.state.v2EligibilityIssue(now: now, calendar: calendar))
        XCTAssertEqual(guidance(fixture.state).action, .health)
        XCTAssertEqual(guidance(fixture.state).stateLine, "Review Health inputs")
        XCTAssertEqual(guidance(fixture.state).availableHealthCount, 4)
        XCTAssertFalse(fixture.state.runPrediction(now: now, calendar: calendar))
    }

    func testTypedIssuesPreserveExactValidationOrderAndMessages() {
        let issues = ManualInputsValidation.issues(studyMinutes: nil, screenTimeMinutes: nil,
            previousScoreText: "101", subject: "", assessmentName: "", assessmentDate: now,
            previousDate: now, confirmed: false, now: now, calendar: calendar)
        XCTAssertEqual(issues.map(\.field), [.study, .screen, .subject, .assessment, .previousScore,
                                            .assessmentDate, .previousDate, .confirmation])
        XCTAssertEqual(issues.map(\.message), [
            "Enter yesterday’s study time.", "Enter yesterday’s recreational screen time.",
            "Enter the subject.", "Enter the next assessment name.", "Enter a previous score from 0 to 100.",
            "Next assessment must be within 1–7 days.", "Previous result must be 1–90 days old.",
            "Confirm the assessment details."
        ])
    }

    private func guidance(_ state: TwinTrackState) -> HomeGuidance {
        HomeGuidance(state: state, now: now, calendar: calendar)
    }
    private func saveCompleteManual(_ state: TwinTrackState, context: V2PredictionContext? = nil) {
        XCTAssertTrue(state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 180,
            previousScore: 80, context: context ?? self.context()))
    }
    private func context(subject: String = "Synthetic chemistry", assessment: String = "Fixture quiz",
                         horizon: Int = 3, previousAge: Int = 14, manualAge: Int = 1,
                         confirmed: Bool = true) -> V2PredictionContext {
        let today = calendar.startOfDay(for: now)
        return V2PredictionContext(subject: subject, assessmentName: assessment,
            assessmentDate: calendar.date(byAdding: .day, value: horizon, to: today)!,
            previousDate: calendar.date(byAdding: .day, value: -previousAge, to: today)!,
            manualDay: calendar.date(byAdding: .day, value: -manualAge, to: today)!,
            timeZoneIdentifier: calendar.timeZone.identifier, sameSubjectConfirmed: confirmed,
            nextIndividualAssessmentConfirmed: confirmed, latestComparablePriorConfirmed: confirmed)
    }
    private func makeFixture(requestCompleted: Bool = true) -> (state: TwinTrackState, health: GuidanceHealthFixture, defaults: UserDefaults, name: String) {
        let name = "HomeGuidanceTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defaults.set(requestCompleted, forKey: "twintrack.health.fourTypeRequestCompleted")
        let health = GuidanceHealthFixture()
        return (TwinTrackState(defaults: defaults, healthService: health), health, defaults, name)
    }
}

@MainActor
private final class GuidanceHealthFixture: HealthDataProviding {
    var isAvailable = true
    var authorizationCount = 0
    var hold = false
    var pending: CheckedContinuation<HealthReadings, Never>?
    var readings = HealthReadings(sleep: .available(7), steps: .available(5000),
                                  exercise: .available(30), restingHeartRate: .available(60))
    func requestAccess() async throws { authorizationCount += 1 }
    func read(window: HealthDataWindow) async -> HealthReadings {
        readings.restingHeartRateSampleDate = window.day.start
        if hold { return await withCheckedContinuation { pending = $0 } }
        return readings
    }
}
