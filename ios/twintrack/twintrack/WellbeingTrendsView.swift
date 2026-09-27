import SwiftUI

/// A read-only projection of existing prediction records, not another history store.
/// Deduplicate by metric source period, never by the prediction's creation day.
enum WellbeingHistory {
    struct Observation: Identifiable, Equatable {
        let id: String
        let date: Date
        let value: Double
        let period: String
        let recordedAt: Date
    }

    static func days(count: Int, now: Date, calendar: Calendar) -> [Date] {
        guard [7, 30].contains(count) else { return [] }
        let today = calendar.startOfDay(for: now)
        return (-(count - 1)...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    static func observations(_ snapshots: [PredictionSnapshot], feature: TwinTrackFeature,
                             days count: Int, now: Date, calendar: Calendar) -> [Observation] {
        guard let start = days(count: count, now: now, calendar: calendar).first,
              let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return [] }
        var records: [String: Observation] = [:]
        for snapshot in snapshots.sorted(by: { $0.createdAt < $1.createdAt }) where snapshot.isValid {
            let date: Date, key: String, period: String
            switch feature {
            case .studyMinutes, .screenTimeMinutes:
                guard let context = snapshot.predictionContext else { continue }
                date = context.manualDay
                let subject = feature == .studyMinutes ? context.subject : ""
                key = "manual:\(date.timeIntervalSinceReferenceDate):\(context.timeZoneIdentifier):\(subject)"
                period = "Manual source day · \(dateLabel(date, zone: context.timeZoneIdentifier))"
                    + (subject.isEmpty ? "" : " · \(subject)")
            case .steps, .exerciseMinutes, .sleepHours:
                guard let window = snapshot.healthWindow else { continue }
                let lower = feature == .sleepHours ? window.sleepStart : window.dayStart
                let upper = feature == .sleepHours ? window.sleepEnd : window.dayEnd
                // Display a multi-day aggregate once, at its source-window start.
                date = lower
                key = "period:\(lower.timeIntervalSinceReferenceDate):\(upper.timeIntervalSinceReferenceDate):\(window.timeZoneIdentifier)"
                period = "Health source period · \(dateLabel(lower, zone: window.timeZoneIdentifier, time: true)) – \(dateLabel(upper, zone: window.timeZoneIdentifier, time: true))"
            case .restingHeartRate:
                guard let window = snapshot.healthWindow else { continue }
                if let sample = window.restingHeartRateSampleDate {
                    date = sample
                    key = "sample:\(sample.timeIntervalSinceReferenceDate)"
                    period = "Health reading · \(dateLabel(sample, zone: window.timeZoneIdentifier, time: true))"
                } else {
                    // Only legacy semantics used a completed-period average. A
                    // modern reading without a sample date cannot become a point.
                    guard window.semanticsVersion == nil else { continue }
                    date = window.dayStart
                    key = "legacy:\(window.dayStart.timeIntervalSinceReferenceDate):\(window.dayEnd.timeIntervalSinceReferenceDate)"
                    period = "Legacy period average · \(dateLabel(window.dayStart, zone: window.timeZoneIdentifier)) – \(dateLabel(window.dayEnd, zone: window.timeZoneIdentifier))"
                }
            case .previousScore: continue
            }
            guard date >= start, date < end else { continue }
            records[key] = Observation(id: key, date: date,
                value: WhatIfScenario.value(feature, in: snapshot.inputs.profile), period: period,
                recordedAt: snapshot.createdAt)
        }
        return records.values.sorted { $0.date < $1.date }
    }

    private static func dateLabel(_ date: Date, zone: String, time: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = time ? .short : .none
        formatter.timeZone = TimeZone(identifier: zone)
        return "\(formatter.string(from: date)) (\(zone))"
    }
}

struct WellbeingTrendsView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.calendar) private var calendar
    @State private var count = 7
    @State private var feature = TwinTrackFeature.studyMinutes
    @State private var detail: PredictionSnapshot?
    private let features: [TwinTrackFeature] = [.studyMinutes, .screenTimeMinutes, .sleepHours, .steps, .exerciseMinutes, .restingHeartRate]

    var body: some View {
        let now = Date()
        let days = WellbeingHistory.days(count: count, now: now, calendar: calendar)
        let observations = WellbeingHistory.observations(state.predictionHistory, feature: feature,
                                                         days: count, now: now, calendar: calendar)
        List {
            Section {
                Text("Changes over time").font(.headline)
                Text("Only values captured with saved predictions appear here. This is not a complete daily journal. Missing dates remain empty; repeated source periods are shown once.")
                    .font(.footnote).foregroundStyle(.secondary)
                Picker("Time range", selection: $count) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                }.pickerStyle(.segmented).accessibilityIdentifier("wellbeingTrendRange")
            }
            Section("Recorded habits & health") {
                Picker("Recorded value", selection: $feature) {
                    ForEach(features, id: \.self) { Text(HomeDisplay.featureName($0)).tag($0) }
                }.accessibilityIdentifier("wellbeingTrendMetric")
                Text("\(observations.count) recorded observations").font(.caption).foregroundStyle(.secondary)
                    .accessibilityIdentifier("wellbeingTrendCount")
                ForEach(days.reversed(), id: \.self) { day in
                    let records = observations.filter { calendar.isDate($0.date, inSameDayAs: day) }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(day, format: .dateTime.month().day()).font(.subheadline.weight(.medium))
                        if records.isEmpty {
                            Text("No recorded value").font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(records) { record in
                            Text(WhatIfDisplay.value(record.value, feature: feature)).monospacedDigit()
                            Text(record.period).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }.accessibilityElement(children: .combine)
                }
            }
            Section("Model estimates") {
                Text("Saved runs remain separate by assessment and model version. A higher estimate is not proof of improvement.")
                    .font(.footnote).foregroundStyle(.secondary)
                let estimates = state.predictionHistory.filter {
                    $0.createdAt >= (days.first ?? now) && $0.createdAt <= now
                }.sorted { $0.createdAt > $1.createdAt }
                if estimates.isEmpty { Text("No saved estimates in this period").foregroundStyle(.secondary) }
                ForEach(estimates) { snapshot in
                    Button { detail = snapshot } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.predictionContext?.summary ?? "Legacy assessment · Context not recorded")
                            Text("\(HomeDisplay.prediction(snapshot.prediction)) / 100 · \(snapshot.modelLabel)")
                                .font(.footnote)
                            Text(snapshot.createdAt, format: .dateTime.month().day().hour().minute()).font(.caption)
                        }
                    }.buttonStyle(.plain)
                }
            }
            Section("Body measurements") {
                Text("Body & Wellbeing keeps your latest saved measurements only. No body-measurement history is inferred from predictions or chat.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Trends & History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { PredictionHistoryDetailView(snapshot: $0) }
        .privacySensitive()
    }
}
