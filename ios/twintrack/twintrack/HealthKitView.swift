import SwiftUI

/// The limited HealthKit readout for device verification; Home wiring comes later.
struct HealthKitView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("TwinTrack requests read access to these Apple Health data types. Nothing is written back to Health.")
                    Text(state.healthAccess.rawValue).foregroundStyle(.secondary)
                    Button("Request Apple Health Access") {
                        Task { await state.requestHealthAccess() }
                    }
                    .disabled(state.healthAccess == .requesting || state.isRefreshingHealth)
                    Button("Refresh") { Task { await state.refreshHealth() } }
                        .disabled(state.healthAccess != .completed || state.isRefreshingHealth)
                    if state.isRefreshingHealth { ProgressView("Refreshing…") }
                }

                Section("Previous completed day") {
                    if let window = state.healthWindow {
                        Text("Activity and resting heart rate: \(intervalText(window.day, zone: window.timeZone))")
                        Text("Sleep: \(intervalText(window.sleep, zone: window.timeZone))")
                    }
                    Text("Sleep is assigned to its waking day using noon-to-noon. Today's activity and the night ending today are not included.")
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
                        Text("All seven inputs are available. Prediction display will be added in a later milestone.")
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
            if state.isRefreshingHealth {
                Text("Refreshing…").foregroundStyle(.secondary)
            } else if let value = result.value {
                Text("\(value.formatted(.number.precision(.fractionLength(0...2)))) \(unit)")
                    .privacySensitive()
                Text("Recent data available").font(.caption).foregroundStyle(.secondary)
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
