import Foundation
import HealthKit

/// A completed-day baseline, not today's partial activity or an arbitrary latest sample.
struct HealthDataWindow: Equatable, Sendable {
    let day: DateInterval
    let sleep: DateInterval
    let timeZone: TimeZone

    init(now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let previousDay = calendar.date(byAdding: .day, value: -1, to: yesterday)!
        day = DateInterval(start: yesterday, end: today)
        // Noon-to-noon assigns overnight sleep to its waking day. Calendar arithmetic
        // preserves local wall-clock boundaries on 23/25-hour days; never subtract 86400.
        sleep = DateInterval(
            start: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: previousDay)!,
            end: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!
        )
        timeZone = calendar.timeZone
    }
}

enum HealthMetricResult: Equatable, Sendable {
    case available(Double)
    case missing
    case failed

    var value: Double? {
        guard case let .available(value) = self, value.isFinite, value >= 0 else { return nil }
        return value
    }
}

/// Transient transfer value; TwinTrackState is the only owner of app-facing health data.
struct HealthReadings: Equatable, Sendable {
    var sleep: HealthMetricResult = .missing
    var steps: HealthMetricResult = .missing
    var exercise: HealthMetricResult = .missing
    var restingHeartRate: HealthMetricResult = .missing
}

struct SleepInterval: Sendable {
    let start: Date
    let end: Date
    let category: Int
}

enum SleepAggregation {
    nonisolated static func hours(in window: DateInterval, samples: [SleepInterval]) -> Double? {
        // Only actual asleep categories count. In Bed and Awake are never durations
        // of sleep. Unspecified supports legacy/general asleep samples.
        let asleep = Set([
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        ])
        let intervals = samples.compactMap { sample -> DateInterval? in
            guard asleep.contains(sample.category) else { return nil }
            let start = max(window.start, sample.start)
            let end = min(window.end, sample.end)
            guard start < end else { return nil }
            return DateInterval(start: start, end: end)
        }.sorted { $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start }

        guard var merged = intervals.first else { return nil }
        var seconds = 0.0
        // Union all accessible sources, including general asleep over staged sleep.
        // Each instant counts at most once. This does not reproduce Health's private
        // source-priority rules: one source saying asleep wins over another saying awake.
        for interval in intervals.dropFirst() {
            if interval.start <= merged.end {
                merged = DateInterval(start: merged.start, end: max(merged.end, interval.end))
            } else {
                seconds += merged.duration
                merged = interval
            }
        }
        return (seconds + merged.duration) / 3600
    }
}

enum HealthUnits {
    nonisolated static func steps(_ quantity: HKQuantity?) -> Double? {
        quantity?.doubleValue(for: .count())
    }

    nonisolated static func exerciseMinutes(_ quantity: HKQuantity?) -> Double? {
        quantity?.doubleValue(for: .minute())
    }

    nonisolated static func restingBPM(_ quantity: HKQuantity?) -> Double? {
        quantity?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }
}

enum HealthAccessState: String {
    case notRequested = "Access request not yet completed"
    case requesting = "Requesting access…"
    case completed = "Access request completed"
    case failed = "Access request could not complete"
    case unavailable = "HealthKit unavailable"
}

@MainActor
protocol HealthDataProviding {
    var isAvailable: Bool { get }
    func requestAccess() async throws
    func read(window: HealthDataWindow) async -> HealthReadings
}
