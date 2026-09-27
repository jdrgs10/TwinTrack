import XCTest
@testable import twintrack

@MainActor
final class WellbeingHistoryTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "America/New_York")!
        return value
    }
    private func date(_ day: Int, month: Int = 3) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    private func snapshot(day: Int, created: Int? = nil, study: Double = 90,
                          context: Bool = true, window: Bool = true, subject: String = "Synthetic mathematics") -> PredictionSnapshot {
        let profile = TwinTrackProfile(sleepHours: 5.572, steps: 6758.79, exerciseMinutes: 12.7,
                                      restingHeartRate: 61, studyMinutes: study, screenTimeMinutes: 120, previousScore: 80)
        let health = HealthDataWindow(now: date(day + 1), calendar: calendar)
        return PredictionSnapshot(createdAt: date(created ?? (day + 1)), prediction: TwinTrackModel.predict(profile),
            inputs: PredictionInputs(profile: profile),
            healthWindow: window ? PredictionHealthWindow(health, restingHeartRateSampleDate: date(day)) : nil,
            modelVersion: TwinTrackModel.version,
            predictionContext: context ? V2PredictionContext(subject: subject, assessmentName: "Fixture assessment",
                assessmentDate: date(15), previousDate: date(1), manualDay: date(day),
                timeZoneIdentifier: calendar.timeZone.identifier, sameSubjectConfirmed: true,
                nextIndividualAssessmentConfirmed: true, latestComparablePriorConfirmed: true) : nil)
    }
    func testSevenAndThirtyDaysUseLocalCalendarAcrossDST() {
        let days = WellbeingHistory.days(count: 7, now: date(10), calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first, calendar.startOfDay(for: date(4)))
        XCTAssertEqual(days.last, calendar.startOfDay(for: date(10)))
        XCTAssertNotEqual(days.last!.timeIntervalSince(days.first!), 6 * 86400)
        XCTAssertEqual(WellbeingHistory.days(count: 30, now: date(10), calendar: calendar).count, 30)
    }
    func testMissingDaysRemainEmptyAndSourceDayIsNotCreationDay() {
        let records = WellbeingHistory.observations([snapshot(day: 5), snapshot(day: 8, created: 10)],
            feature: .studyMinutes, days: 7, now: date(10), calendar: calendar)
        XCTAssertEqual(records.map(\.date), [date(5), date(8)])
        XCTAssertEqual(records.count, 2)
    }
    func testSameManualDayUsesLatestRecordedValueWithoutCreatingEvents() {
        let records = WellbeingHistory.observations([snapshot(day: 8, created: 9), snapshot(day: 8, created: 10, study: 120)],
            feature: .studyMinutes, days: 7, now: date(10), calendar: calendar)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.value, 120)
    }
    func testStudyRecordsKeepDifferentSubjectsSeparate() {
        let records = [snapshot(day: 8), snapshot(day: 8, study: 120, subject: "Synthetic science")]
        let study = WellbeingHistory.observations(records, feature: .studyMinutes, days: 7, now: date(10), calendar: calendar)
        XCTAssertEqual(study.count, 2)
        XCTAssertEqual(Set(study.map(\.value)), [90, 120])
        XCTAssertTrue(study.contains { $0.period.contains("Synthetic mathematics") })
        XCTAssertTrue(study.contains { $0.period.contains("Synthetic science") })
    }

    func testHomeTrendDoesNotCompareDifferentAssessments() {
        let first = snapshot(day: 7), second = snapshot(day: 8, subject: "Synthetic science")
        let summary = PredictionTrendPresentation.summary(points: [
            PredictionTrendPoint(day: date(7), snapshot: first), PredictionTrendPoint(day: date(8), snapshot: second)])
        XCTAssertNil(summary.delta)
        XCTAssertTrue(summary.description.contains("Different assessments"))
    }

    func testRepeatedHealthPeriodAndRHRReadingAppearOnlyOnce() {
        let snapshots = [snapshot(day: 8, created: 9), snapshot(day: 8, created: 10, study: 120)]
        for feature in [TwinTrackFeature.steps, .exerciseMinutes, .sleepHours, .restingHeartRate] {
            let records = WellbeingHistory.observations(snapshots, feature: feature, days: 7, now: date(10), calendar: calendar)
            XCTAssertEqual(records.count, 1)
            XCTAssertTrue(records[0].period.contains("Health"))
        }
        XCTAssertEqual(snapshots.count, 2, "The projection must not remove legitimate prediction runs")
    }
    func testUndatedLegacyManualValuesAreNotInventedHistory() {
        let records = [snapshot(day: 8, context: false, window: false)]
        XCTAssertTrue(WellbeingHistory.observations(records, feature: .studyMinutes, days: 30, now: date(10), calendar: calendar).isEmpty)
        XCTAssertTrue(WellbeingHistory.observations(records, feature: .steps, days: 30, now: date(10), calendar: calendar).isEmpty)
    }
    func testRangeFiltersSourceTimeAndNeverCarriesValuesForward() {
        let records = [snapshot(day: 2), snapshot(day: 8), snapshot(day: 12)]
        XCTAssertEqual(WellbeingHistory.observations(records, feature: .steps, days: 7, now: date(10), calendar: calendar).count, 1)
        XCTAssertEqual(WellbeingHistory.observations(records, feature: .steps, days: 30, now: date(10), calendar: calendar).count, 2)
    }
    func testDisplayRoundingLeavesNumericalInputsAndRidgeUntouched() {
        let record = snapshot(day: 8), before = snapshot(day: 8).inputs
        XCTAssertEqual(WhatIfDisplay.value(5.572, feature: .sleepHours), "5h 34m")
        XCTAssertEqual(WhatIfDisplay.value(6758.79, feature: .steps), "6,759")
        XCTAssertEqual(WhatIfDisplay.value(12.7, feature: .exerciseMinutes), "13 min")
        XCTAssertEqual(record.inputs, before)
        XCTAssertEqual(record.prediction, TwinTrackModel.predict(before.profile))
    }
}
