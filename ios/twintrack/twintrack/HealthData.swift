import Foundation
import HealthKit

/// Each health feature has its own explicit source period, captured by one refresh.
struct HealthDataWindow: Equatable, Sendable {
    let day: DateInterval
    let sleep: DateInterval
    let restingHeartRate: DateInterval
    let timeZone: TimeZone

    init(now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        day = DateInterval(start: yesterday, end: today)
        // Before noon include the night ending this morning as soon as it syncs.
        // Calendar noon boundaries preserve local time across 23/25-hour days.
        sleep = DateInterval(
            start: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!,
            end: min(now, calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!)
        )
        // RHR recency is 72 elapsed hours, not three local calendar days.
        restingHeartRate = DateInterval(start: now.addingTimeInterval(-72 * 3600), end: now)
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
    var restingHeartRateSampleDate: Date?
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

/// Only the value and measurement timestamp cross the query boundary; no sample/device IDs.
struct RestingHeartRateReading: Equatable, Sendable {
    let bpm: Double
    let date: Date
}

enum RestingHeartRateSelection {
    nonisolated static func latest(
        in window: DateInterval,
        samples: [RestingHeartRateReading]
    ) -> RestingHeartRateReading? {
        samples.filter {
            $0.bpm.isFinite && $0.bpm > 0
                && $0.date >= window.start && $0.date <= window.end
        }.max {
            // Equal timestamps have a deterministic value tie-break, independent of query order.
            $0.date == $1.date ? $0.bpm < $1.bpm : $0.date < $1.date
        }
    }
}
