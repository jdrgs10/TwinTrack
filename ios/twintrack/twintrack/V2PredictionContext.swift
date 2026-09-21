import Foundation

/// Eligibility/provenance only: these fields never become additional Ridge inputs.
struct V2PredictionContext: Codable, Equatable, Sendable {
    let subject: String
    let assessmentName: String
    let assessmentDate: Date
    let previousDate: Date
    let manualDay: Date
    let timeZoneIdentifier: String
    let sameSubjectConfirmed: Bool
    let nextIndividualAssessmentConfirmed: Bool
    let latestComparablePriorConfirmed: Bool

    func issue(now: Date, calendar: Calendar) -> String? {
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !assessmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              sameSubjectConfirmed, nextIndividualAssessmentConfirmed, latestComparablePriorConfirmed else {
            return "Confirm the subject, next individual assessment and latest comparable prior result in Manual Inputs."
        }
        guard [assessmentDate, previousDate, manualDay].allSatisfy({ $0.timeIntervalSinceReferenceDate.isFinite }) else {
            return "Check the assessment and manual-entry dates."
        }
        let today = calendar.startOfDay(for: now)
        guard timeZoneIdentifier == calendar.timeZone.identifier,
              let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              calendar.isDate(manualDay, inSameDayAs: yesterday) else {
            return "Enter or reconfirm yesterday’s study and recreational screen time in Manual Inputs."
        }
        let horizon = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: assessmentDate)).day ?? 0
        guard (1...7).contains(horizon) else { return "The next assessment must be 1–7 days ahead. Update Manual Inputs when it is in range." }
        let age = calendar.dateComponents([.day], from: calendar.startOfDay(for: previousDate), to: today).day ?? 0
        guard (1...90).contains(age) else { return "The latest comparable same-subject score must be 1–90 days old." }
        return nil
    }

    var summary: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier)
        return "\(subject) · \(assessmentName) · \(formatter.string(from: assessmentDate))"
    }
}

struct V2ManualEntry: Codable {
    let studyMinutes: Int?
    let screenTimeMinutes: Int?
    let previousScore: Double?
    let context: V2PredictionContext?
}
