import Foundation
import XCTest
@testable import twintrack

final class ManualInputsValidationTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Dubai")!
        return calendar
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 22, hour: 12))!
    }

    private func reasons(
        study: Int? = 120,
        screen: Int? = 240,
        score: String = "80",
        subject: String = "Chemistry",
        assessment: String = "Unit quiz",
        horizon: Int = 3,
        previousAge: Int = 14,
        confirmed: Bool = true
    ) -> [String] {
        let today = calendar.startOfDay(for: now)
        return ManualInputsValidation.reasons(
            studyMinutes: study,
            screenTimeMinutes: screen,
            previousScoreText: score,
            subject: subject,
            assessmentName: assessment,
            assessmentDate: calendar.date(byAdding: .day, value: horizon, to: today)!,
            previousDate: calendar.date(byAdding: .day, value: -previousAge, to: today)!,
            confirmed: confirmed,
            now: now,
            calendar: calendar
        )
    }

    func testCompleteComparableDetailsAreReady() {
        XCTAssertEqual(reasons(), [])
    }

    func testOnlyRelevantMissingManualValuesAreShown() {
        XCTAssertEqual(reasons(study: nil), ["Enter yesterday’s study time."])
        XCTAssertEqual(reasons(screen: nil), ["Enter yesterday’s recreational screen time."])
    }

    func testSubjectAndAssessmentNameHaveDistinctFeedback() {
        XCTAssertEqual(reasons(subject: "  "), ["Enter the subject."])
        XCTAssertEqual(reasons(assessment: "\n"), ["Enter the next assessment name."])
    }

    func testPreviousScoreRequiresNumericZeroThroughOneHundred() {
        for valid in ["0", "81.5", "100"] {
            XCTAssertFalse(reasons(score: valid).contains("Enter a previous score from 0 to 100."), valid)
        }
        for invalid in ["", "-1", "101", "score"] {
            XCTAssertEqual(reasons(score: invalid), ["Enter a previous score from 0 to 100."], invalid)
        }
    }

    func testNextAssessmentEligibilityUsesOneThroughSevenLocalCalendarDays() {
        for horizon in 1...7 { XCTAssertEqual(reasons(horizon: horizon), [], "day \(horizon)") }
        for horizon in [0, 8] {
            XCTAssertEqual(reasons(horizon: horizon), ["Next assessment must be within 1–7 days."])
        }
    }

    func testPreviousResultEligibilityUsesOneThroughNinetyLocalCalendarDays() {
        for age in [1, 30, 90] { XCTAssertEqual(reasons(previousAge: age), [], "day \(age)") }
        for age in [0, 91] {
            XCTAssertEqual(reasons(previousAge: age), ["Previous result must be 1–90 days old."])
        }
    }

    func testConfirmationFeedbackIsShortAndSpecific() {
        XCTAssertEqual(reasons(confirmed: false), ["Confirm the assessment details."])
    }

    func testMultipleIssuesKeepStableRelevantOrder() {
        XCTAssertEqual(
            reasons(study: nil, screen: nil, score: "", subject: "", assessment: "", horizon: 8,
                    previousAge: 91, confirmed: false),
            [
                "Enter yesterday’s study time.",
                "Enter yesterday’s recreational screen time.",
                "Enter the subject.",
                "Enter the next assessment name.",
                "Enter a previous score from 0 to 100.",
                "Next assessment must be within 1–7 days.",
                "Previous result must be 1–90 days old.",
                "Confirm the assessment details.",
            ]
        )
    }
}
