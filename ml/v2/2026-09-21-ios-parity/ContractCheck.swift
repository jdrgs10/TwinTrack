import Foundation

// Portable checks of the production date contract, separate from iOS integration tests.
@main
struct ContractCheck {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
        let today = calendar.startOfDay(for: now)
        func context(horizon: Int = 3, age: Int = 14, confirmed: Bool = true) -> V2PredictionContext {
            V2PredictionContext(subject: "Synthetic subject", assessmentName: "Synthetic quiz",
                assessmentDate: calendar.date(byAdding: .day, value: horizon, to: today)!,
                previousDate: calendar.date(byAdding: .day, value: -age, to: today)!,
                manualDay: calendar.date(byAdding: .day, value: -1, to: today)!,
                timeZoneIdentifier: calendar.timeZone.identifier, sameSubjectConfirmed: confirmed,
                nextIndividualAssessmentConfirmed: confirmed, latestComparablePriorConfirmed: confirmed)
        }
        var checks = 0
        func check(_ result: Bool) { precondition(result); checks += 1 }
        for (horizon, valid) in [(0, false), (1, true), (7, true), (8, false)] {
            check((context(horizon: horizon).issue(now: now, calendar: calendar) == nil) == valid)
        }
        for (age, valid) in [(0, false), (1, true), (90, true), (91, false)] {
            check((context(age: age).issue(now: now, calendar: calendar) == nil) == valid)
        }
        check(context(confirmed: false).issue(now: now, calendar: calendar) != nil)
        let saved = context()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        check(saved.issue(now: tomorrow, calendar: calendar) != nil)
        check(try JSONDecoder().decode(V2PredictionContext.self, from: JSONEncoder().encode(saved)) == saved)
        calendar.timeZone = TimeZone(identifier: "Asia/Dubai")!
        check(saved.issue(now: now, calendar: calendar) != nil)
        print("V2 production date-contract portable checks: \(checks)/\(checks) PASS (including DST, expiry, time-zone and Codable persistence)")
    }
}
