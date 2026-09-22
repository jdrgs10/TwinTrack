import Foundation

/// Experimental personal comparison. No Ridge, diagnosis, persistence or emergency routing.
struct RestingHeartRateTrend: Equatable, Sendable {
    enum State: String, Sendable {
        case insufficient = "Not enough recent data"
        case within = "Within your recent usual range"
        case different = "Different from your recent usual range"
        case persistent = "Persistently different from your recent usual range"
    }

    enum Direction: String, Sendable { case higher, lower, varied }

    let state: State
    let direction: Direction?
    let completedDay: Date
    let baselineDays: Int
    let recentDays: Int
    let rangeUnavailable: Bool

    var explanation: String {
        switch state {
        case .insufficient:
            rangeUnavailable
                ? "A reliable personal comparison range could not be estimated from the available readings."
                : "Not enough recent data to compare your resting heart rate with your usual pattern."
        case .within:
            "Your recent readings are within your personal comparison range. This does not assess your health."
        case .different:
            "Some recent readings differ from your usual pattern. Changes can happen for many reasons, including sleep, stress, exercise, recovery or illness."
        case .persistent:
            "Your resting heart rate has been \(direction == .lower ? "lower" : "higher") than your recent usual range for several days. If this continues or you feel unwell, consider telling a parent, trusted adult or healthcare professional."
        }
    }

    nonisolated static func window(now: Date, calendar: Calendar) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        return DateInterval(start: calendar.date(byAdding: .day, value: -33, to: today)!, end: today)
    }

    nonisolated static func assess(
        samples: [RestingHeartRateReading], now: Date, calendar: Calendar
    ) -> Self {
        let window = window(now: now, calendar: calendar)
        let dates = (0..<33).map { calendar.date(byAdding: .day, value: $0, to: window.start)! }
        var daily: [Date: RestingHeartRateReading] = [:]
        for sample in samples where sample.bpm.isFinite && sample.bpm > 0
            && sample.date >= window.start && sample.date < window.end {
            let day = calendar.startOfDay(for: sample.date)
            if let old = daily[day], old.date > sample.date
                || (old.date == sample.date && old.bpm >= sample.bpm) { continue }
            daily[day] = sample
        }
        let baseline = dates.prefix(28).compactMap { daily[$0]?.bpm }
        let recent = dates.suffix(5).compactMap { daily[$0]?.bpm }
        func result(_ state: State, _ direction: Direction? = nil, rangeUnavailable: Bool = false) -> Self {
            Self(state: state, direction: direction, completedDay: dates[32],
                 baselineDays: baseline.count, recentDays: recent.count, rangeUnavailable: rangeUnavailable)
        }
        guard daily[dates[32]] != nil, baseline.count >= 21, recent.count >= 4,
              stride(from: 0, to: 28, by: 7).allSatisfy({ start in
                  dates[start..<(start + 7)].filter { daily[$0] != nil }.count >= 4
              }) else { return result(.insufficient) }
        let center = median(baseline)
        let scale = 1.4826 * median(baseline.map { abs($0 - center) })
        let lower = center - 3 * scale, upper = center + 3 * scale
        guard scale.isFinite, scale > 0, lower.isFinite, upper.isFinite else {
            return result(.insufficient, rangeUnavailable: true)
        }
        let flags = Dictionary(uniqueKeysWithValues: dates.suffix(5).compactMap { date -> (Date, Int)? in
            guard let value = daily[date]?.bpm else { return nil }
            return (date, value > upper ? 1 : value < lower ? -1 : 0)
        })
        // Missing calendar days break the reset; refresh counts never count as days.
        if (flags[dates[31]] == 0 && flags[dates[32]] == 0) || flags.values.allSatisfy({ $0 == 0 }) {
            return result(.within)
        }
        let high = flags.values.filter { $0 == 1 }.count
        let low = flags.values.filter { $0 == -1 }.count
        let direction: Direction = high > 0 && low == 0 ? .higher : low > 0 && high == 0 ? .lower : .varied
        return result(max(high, low) >= 3 && min(high, low) == 0 ? .persistent : .different, direction)
    }

    nonisolated private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted(), middle = values.count / 2
        return values.count.isMultiple(of: 2) ? sorted[middle - 1] / 2 + sorted[middle] / 2 : sorted[middle]
    }
}
