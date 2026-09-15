import SwiftUI

/// Shared duration control; these are elapsed hours/minutes, never a time of day.
struct DurationWheelPicker: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    var maximumHours = ManualDuration.maximumHours

    var body: some View {
        HStack(spacing: 0) {
            column("Hours", range: 0...maximumHours, selection: $hours, twoDigits: false)
            column("Minutes", range: 0...59, selection: $minutes, twoDigits: true)
        }
        .frame(height: 170)
        .padding(.horizontal, 8)
    }

    private func column(_ title: String, range: ClosedRange<Int>, selection: Binding<Int>, twoDigits: Bool) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text(twoDigits ? String(format: "%02d", value) : "\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel).labelsHidden().clipped()
            .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity)
    }
}

enum DurationOperation: String, CaseIterable, Identifiable {
    case set = "Set to", increase = "Increase by", decrease = "Decrease by"
    var id: String { rawValue }
}

struct WhatIfDurationDraft {
    let feature: TwinTrackFeature
    let original: Double
    private(set) var operation = DurationOperation.set
    private(set) var edited = false
    var hours: Int { didSet { edited = true } }
    var minutes: Int { didSet { edited = true } }

    init(feature: TwinTrackFeature, value: Double) {
        self.feature = feature
        original = value
        let total = feature == .sleepHours ? value * 60 : value
        // The wheels share Manual Inputs' editing range. An untouched editor
        // preserves the exact baseline, including sub-minute or larger values.
        let bounded = total.isFinite ? min(max(total, 0), Double(ManualDuration.maximumHours * 60 + 59)) : 0
        hours = Int(bounded) / 60
        minutes = Int(bounded) % 60
    }

    mutating func select(_ operation: DurationOperation) {
        guard self.operation != operation else { return }
        let initial = Self(feature: feature, value: original)
        self.operation = operation
        hours = operation == .set ? initial.hours : 0
        minutes = operation == .set ? initial.minutes : 0
        edited = true
    }

    var value: Double? {
        guard [.sleepHours, .studyMinutes, .screenTimeMinutes].contains(feature) else { return nil }
        guard edited else { return WhatIfScenario.isValid(original, for: feature) ? original : nil }
        guard let total = ManualDuration.totalMinutes(hours: hours, minutes: minutes) else { return nil }
        let amount = feature == .sleepHours ? Double(total) / 60 : Double(total)
        let result: Double
        switch operation {
        case .set: result = amount
        case .increase: result = original + amount
        case .decrease: result = original - amount
        }
        return WhatIfScenario.isValid(result, for: feature) ? result : nil
    }
}

#if DEBUG
/// Opt-in component UI tests: no production state, HealthKit, or saved history.
struct DurationPickerTestFixture: View {
    @State private var edit: WhatIfEdit?
    @State private var values: [TwinTrackFeature: Double] = [.sleepHours: 7, .studyMinutes: 120, .screenTimeMinutes: 240]
    var body: some View {
        NavigationStack {
            List {
                Text("Synthetic duration controls")
                ForEach([TwinTrackFeature.sleepHours, .studyMinutes, .screenTimeMinutes], id: \.self) { feature in
                    Button(HomeDisplay.featureName(feature)) { edit = WhatIfEdit(feature: feature, value: values[feature]!) }
                    Text(WhatIfDisplay.value(values[feature]!, feature: feature))
                        .accessibilityIdentifier("fixture.\(feature.key)")
                }
            }
            .sheet(item: $edit) { item in
                WhatIfValueEditor(edit: item) { values[item.feature] = $0 }
            }
        }
    }
}
#endif
