import SwiftUI

/// Read-only source periods and availability for the shared current health inputs.
struct HealthKitView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("TwinTrack requests read access to these Apple Health data types. Nothing is written back to Health.")
                    Text(state.healthAccess.rawValue).foregroundStyle(.secondary)
                    if state.healthAccess == .notRequested || state.healthAccess == .failed || state.healthAccess == .requesting {
                        Button("Request Apple Health Access") {
                            Task { await state.requestHealthAccess() }
                        }
                        .disabled(state.healthAccess == .requesting || state.isRefreshingHealth)
                    }
                    Button("Refresh") { Task { await state.refreshHealth() } }
                        .disabled(state.healthAccess != .completed || state.isRefreshingHealth)
                    if state.isRefreshingHealth { ProgressView("Refreshing…") }
                }

                Section("Health source periods") {
                    if let window = state.healthWindow {
                        Text("Steps / Exercise — previous completed day: \(intervalText(window.day, zone: window.timeZone))")
                        Text("Last sleep: \(intervalText(window.sleep, zone: window.timeZone))")
                        Text("Resting Heart Rate — latest available within: \(intervalText(window.restingHeartRate, zone: window.timeZone))")
                        if let date = state.healthReadings.restingHeartRateSampleDate {
                            Text("Resting Heart Rate sample: \(date.formatted(.dateTime.month().day().year().hour().minute()))")
                                .privacySensitive()
                        }
                    }
                    Text("Last sleep uses yesterday noon to now before noon, or to today noon afterwards. Steps and Exercise use the previous completed day. Resting Heart Rate uses the latest valid sample within 72 hours.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Included in access request") {
                    metric("Sleep", result: state.healthReadings.sleep, unit: "hours")
                    metric("Steps", result: state.healthReadings.steps, unit: "steps")
                    metric("Exercise", result: state.healthReadings.exercise, unit: "minutes")
                    metric("Resting Heart Rate", result: state.healthReadings.restingHeartRate, unit: "bpm")
                }

                Section {
                    if !state.missingInputs.isEmpty {
                        Text("Prediction unavailable — missing: \(state.missingInputs.map { label($0) }.joined(separator: ", ")).")
                    } else {
                        Text("All seven inputs are available for the current prediction.")
                    }
                    Text("No accessible recent value can mean missing data or limited access. It does not prove read access was denied. Permissions can be reviewed in Apple Health.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func metric(_ title: String, result: HealthMetricResult, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            if let value = result.value {
                Text("\(value.formatted(.number.precision(.fractionLength(0...2)))) \(unit)")
                    .privacySensitive()
                Text(state.isRefreshingHealth ? "Refreshing…" : "Recent data available")
                    .font(.caption).foregroundStyle(.secondary)
            } else if state.isRefreshingHealth {
                Text("Refreshing…").foregroundStyle(.secondary)
            } else {
                Text(result == .failed ? "Query failed — try Refresh" : "No accessible recent value")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func intervalText(_ interval: DateInterval, zone: TimeZone) -> String {
        let format = DateFormatter()
        format.dateStyle = .medium
        format.timeStyle = .short
        format.timeZone = zone
        return "\(format.string(from: interval.start)) → \(format.string(from: interval.end)) (\(zone.identifier))"
    }

    private func label(_ feature: TwinTrackFeature) -> String {
        switch feature {
        case .sleepHours: "Sleep"
        case .steps: "Steps"
        case .exerciseMinutes: "Exercise"
        case .restingHeartRate: "Resting Heart Rate"
        case .studyMinutes: "Study Time"
        case .screenTimeMinutes: "Screen Time"
        case .previousScore: "Previous Score"
        }
    }
}
