import SwiftUI

struct WhatIfView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let isActive: Bool

    @State private var scenario: WhatIfScenario?
    @State private var result: WhatIfResult?
    @State private var expanded = false
    @State private var editor: WhatIfEdit?
    @State private var validationMessage: String?
    @State private var baselineChanged = false

    private var palette: WhatIfPalette { WhatIfPalette(colorScheme) }
    private var currentValues: [Double?] {
        [state.sleepHours, state.steps, state.exerciseMinutes, state.restingHeartRate,
         state.studyMinutes.map(Double.init), state.screenTimeMinutes.map(Double.init), state.previousScore]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    PageHeader(
                        title: "TwinTrack AI",
                        subtitle: "Ask questions. Explore scenarios. Understand your twin.",
                        showsMark: false
                    )

                    if let result {
                        resultCard(result)
                            .accessibilityIdentifier("whatIfResult")
                    } else if let scenario {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MODEL SCENARIO").font(.caption.weight(.semibold)).foregroundStyle(palette.accent)
                            Text("V2 baseline: \(HomeDisplay.prediction(scenario.baselinePrediction))")
                                .font(.title2.weight(.semibold)).monospacedDigit()
                            Text("Adjust captured inputs to compare a temporary V2 estimate. Study and recreational screens refer to yesterday.")
                                .font(.footnote).foregroundStyle(palette.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
                        .overlay { RoundedRectangle(cornerRadius: 20).stroke(palette.accentBorder) }
                        .padding(.horizontal, 16)
                        .privacySensitive()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What-If unavailable").font(.headline)
                            Text("All seven valid inputs and a fresh explicit prediction are required. Use Run Prediction on Home first.")
                            if !state.missingInputs.isEmpty {
                                Text("Missing: \(state.missingInputs.map(HomeDisplay.featureName).joined(separator: ", "))")
                            } else if let validationMessage {
                                Text(validationMessage)
                            }
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(palette.card, in: RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .accessibilityIdentifier("whatIfUnavailable")
                    }

                    // This is deterministic model wording, not an AI-generated claim
                    // that changing a habit causes a particular academic outcome.
                    Text("This is a model prediction and does not prove that the change causes an academic outcome. It is not a guaranteed outcome.")
                        .font(.footnote).foregroundStyle(palette.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .accessibilityIdentifier("whatIfDisclaimer")

                    if baselineChanged {
                        Text("Current data changed. The previous scenario was discarded; review the current values before running again.")
                            .font(.footnote).foregroundStyle(palette.secondary).padding(.horizontal, 18)
                    }

                    adjustmentSection
                }
                .padding(.bottom, 28)
            }
            .background(palette.background.ignoresSafeArea())
            .foregroundStyle(palette.primary)
            .navigationTitle("TwinTrack AI")
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(palette.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .sheet(item: $editor) { edit in
                WhatIfValueEditor(edit: edit) { value in
                    update(value, feature: edit.feature)
                }
            }
        }
        .onAppear { if isActive { start() } }
        .onChange(of: isActive) { _, active in
            if active { start() } else { discard() }
        }
        .onChange(of: currentValues) { _, _ in
            // Never retain an arbitrary old baseline across refresh or manual edits.
            if isActive { start(); baselineChanged = true }
        }
        .onChange(of: state.healthWindow) { _, _ in if isActive { start() } }
        .onChange(of: state.lastPrediction) { _, _ in if isActive { start() } }
        .onChange(of: state.predictionContext) { _, _ in if isActive { start() } }
        .onChange(of: state.isRefreshingHealth) { _, _ in if isActive { start() } }
        .onDisappear { discard() }
    }

    private var adjustmentSection: some View {
        VStack(spacing: 6) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Adjust What-If values")
                    Spacer(minLength: 4)
                    Text(scenario.map { "\($0.changes.count) changed" } ?? "Unavailable").font(.caption)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption)
                }
                .font(.footnote).foregroundStyle(palette.secondary)
                .padding(.horizontal, 20).frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("whatIfAdjust")

            if expanded, let scenario {
                ForEach(TwinTrackFeature.allCases, id: \.rawValue) { feature in
                    inputRow(feature, scenario: scenario)
                }
                Text("Extreme values may be outside the model's experience and produce unreliable simulations. Resting heart rate is a weak/noisy prototype input, not an academic recommendation.")
                    .font(.caption).foregroundStyle(palette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18).padding(.vertical, 6)

                if let validationMessage {
                    Text(validationMessage).font(.footnote).foregroundStyle(palette.negative)
                        .padding(.horizontal, 18)
                }
            }

            if expanded || scenario == nil {
                Button("Run simulation") {
                    guard state.predictionStatus() == .fresh else { start(); return }
                    result = scenario?.evaluate()
                }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .foregroundStyle(scenario == nil ? palette.secondary : palette.accent)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(palette.accentBorder) }
                    .disabled(scenario == nil)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("whatIfRun")
            }
            if scenario != nil, expanded || result != nil {
                Button("Cancel scenario") {
                    scenario?.reset()
                    result = nil
                    validationMessage = nil
                    expanded = false
                }
                .frame(minHeight: 44).font(.footnote)
                .accessibilityIdentifier("whatIfCancel")
            }
        }
        .padding(.top, 8)
        .overlay(alignment: .top) { Rectangle().fill(palette.border).frame(height: 1) }
    }

    private func inputRow(_ feature: TwinTrackFeature, scenario: WhatIfScenario) -> some View {
        let changed = scenario.changes[feature] != nil
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return VStack(alignment: .leading, spacing: 5) {
            layout {
                Text(HomeDisplay.featureName(feature)).font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {
                    stepButton(feature, scenario: scenario, direction: -1)
                    Button {
                        editor = WhatIfEdit(feature: feature, value: scenario.scenarioValue(for: feature))
                    } label: {
                        Text(WhatIfDisplay.value(scenario.scenarioValue(for: feature), feature: feature))
                            .font(.subheadline.weight(.semibold)).monospacedDigit()
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(changed ? palette.accent : palette.primary)
                            .frame(minWidth: 74, minHeight: 44)
                    }
                    .accessibilityLabel("Edit scenario \(HomeDisplay.featureName(feature))")
                    .accessibilityIdentifier("whatIfEdit.\(feature.key)")
                    stepButton(feature, scenario: scenario, direction: 1)
                }
            }
            Text("Current: \(WhatIfDisplay.value(scenario.currentValue(for: feature), feature: feature))\(changed ? " · Scenario changed" : "")")
                .font(.caption).foregroundStyle(palette.secondary)
        }
        .padding(.vertical, 9).padding(.horizontal, 12)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(changed ? palette.accentBorder : palette.border) }
        .padding(.horizontal, 16)
        .privacySensitive()
    }

    private func stepButton(_ feature: TwinTrackFeature, scenario: WhatIfScenario, direction: Double) -> some View {
        let value = scenario.scenarioValue(for: feature) + direction * WhatIfDisplay.step(for: feature)
        return Button { update(value, feature: feature) } label: {
            Image(systemName: direction < 0 ? "minus" : "plus")
                .font(.system(size: 14))
                .frame(width: 26, height: 26)
                .background(palette.border, in: RoundedRectangle(cornerRadius: 8))
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!WhatIfScenario.isValid(value, for: feature))
        .accessibilityLabel("\(direction < 0 ? "Decrease" : "Increase") scenario \(HomeDisplay.featureName(feature))")
    }

    private func resultCard(_ result: WhatIfResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("RIDGE V2 · 2.0-final.1 · DETERMINISTIC", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption2.weight(.semibold)).foregroundStyle(palette.accent)
            Text("WHAT-IF").font(.caption2).foregroundStyle(palette.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline, spacing: 14) { scores(result) }
                VStack(alignment: .leading, spacing: 12) { scores(result) }
            }
            Text("The model estimate changes by \(WhatIfDisplay.delta(result.delta)) points.")
                .font(.footnote).foregroundStyle(palette.secondary)
            Divider().overlay(palette.accentBorder)
            Text("VARIABLES CHANGED").font(.caption2.weight(.semibold)).foregroundStyle(palette.secondary)
            if result.changedFeatures.isEmpty {
                Text("No values changed from the current baseline").font(.footnote)
            }
            ForEach(result.changedFeatures, id: \.rawValue) { feature in
                Text("\(HomeDisplay.featureName(feature))  \(WhatIfDisplay.value(WhatIfScenario.value(feature, in: result.baseline), feature: feature)) → \(WhatIfDisplay.value(WhatIfScenario.value(feature, in: result.scenario), feature: feature))")
                    .font(.footnote).padding(.vertical, 5).padding(.horizontal, 9)
                    .background(palette.card, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(palette.accentBorder) }
        .padding(.horizontal, 16).privacySensitive()
    }

    @ViewBuilder private func scores(_ result: WhatIfResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("V2 baseline").font(.caption).foregroundStyle(palette.secondary)
            Text(HomeDisplay.prediction(result.baselinePrediction)).font(.title2.weight(.semibold)).monospacedDigit()
        }
        Image(systemName: "arrow.right").font(.footnote).accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
            Text("V2 estimate").font(.caption).foregroundStyle(palette.accent)
            Text(HomeDisplay.prediction(result.scenarioPrediction)).font(.largeTitle.weight(.semibold)).monospacedDigit()
        }
        Text("\(WhatIfDisplay.delta(result.delta)) pts")
            .font(.footnote.weight(.semibold)).monospacedDigit()
            .foregroundStyle(result.delta == 0 ? palette.secondary : (result.delta > 0 ? palette.positive : palette.negative))
            .padding(.vertical, 5).padding(.horizontal, 9)
            .background(palette.card, in: Capsule())
            .accessibilityLabel("The model estimate changes by \(WhatIfDisplay.delta(result.delta)) points")
    }

    private func update(_ value: Double, feature: TwinTrackFeature) {
        do {
            try scenario?.set(value, for: feature)
            result = nil
            validationMessage = nil
        } catch { validationMessage = error.localizedDescription }
    }

    private func start() {
        discard()
        guard state.predictionStatus() == .fresh else { return }
        do { scenario = try WhatIfScenario(baseline: state.completeProfile) }
        catch { validationMessage = error.localizedDescription }
    }

    private func discard() {
        scenario = nil
        result = nil
        editor = nil
        expanded = false
        validationMessage = nil
        baselineChanged = false
    }
}

struct WhatIfEdit: Identifiable {
    let id = UUID()
    let feature: TwinTrackFeature
    let value: Double
}

struct WhatIfValueEditor: View {
    @Environment(\.dismiss) private var dismiss
    let edit: WhatIfEdit
    let onDone: (Double) -> Void
    @State private var draft: WhatIfInputDraft
    @State private var duration: WhatIfDurationDraft

    init(edit: WhatIfEdit, onDone: @escaping (Double) -> Void) {
        self.edit = edit
        self.onDone = onDone
        _draft = State(initialValue: WhatIfInputDraft(feature: edit.feature, value: edit.value))
        _duration = State(initialValue: WhatIfDurationDraft(feature: edit.feature, value: edit.value))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Temporary scenario value") {
                    if draft.usesDuration {
                        Picker("Operation", selection: Binding(get: { duration.operation }, set: { duration.select($0) })) {
                            ForEach(DurationOperation.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Text("\(duration.operation.rawValue) · Duration").font(.subheadline.weight(.medium))
                        DurationWheelPicker(hours: $duration.hours, minutes: $duration.minutes)
                        if let value = duration.value {
                            Text("Result: \(WhatIfDisplay.value(value, feature: edit.feature))")
                                .font(.footnote).accessibilityIdentifier("durationResult")
                        } else {
                            Text(WhatIfScenario.validationHint(for: edit.feature)).font(.footnote).foregroundStyle(.red)
                        }
                    } else {
                        TextField(HomeDisplay.featureName(edit.feature), text: $draft.number)
                            .keyboardType(.decimalPad)
                    }
                    Text("Current scenario: \(WhatIfDisplay.value(edit.value, feature: edit.feature))")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text(WhatIfScenario.validationHint(for: edit.feature)).font(.footnote)
                    if draft.usesDuration {
                        Text("Choose an elapsed duration, not a time of day. Wheels use 0–\(ManualDuration.maximumHours) hours and 0–59 minutes, like Manual Inputs. An unchanged editor keeps the exact current value.")
                            .font(.footnote)
                    }
                    Text("This edits only the temporary scenario. Your real inputs remain unchanged.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(HomeDisplay.featureName(edit.feature))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let value = draft.usesDuration ? duration.value : draft.parsedValue { onDone(value); dismiss() }
                    }.disabled((draft.usesDuration ? duration.value : draft.parsedValue) == nil)
                }
            }
        }
        .privacySensitive()
    }
}

enum WhatIfDisplay {
    static func value(_ value: Double, feature: TwinTrackFeature) -> String {
        switch feature {
        case .sleepHours: return HomeDisplay.sleep(value) ?? "Unavailable"
        case .studyMinutes, .screenTimeMinutes:
            guard value.isFinite, value >= 0, value < Double(Int.max) else { return "Unavailable" }
            return HomeDisplay.duration(minutes: Int(value.rounded())) ?? "Unavailable"
        case .steps: return HomeDisplay.steps(value) ?? "Unavailable"
        case .exerciseMinutes: return HomeDisplay.exercise(value) ?? "Unavailable"
        case .restingHeartRate: return HomeDisplay.restingHeartRate(value) ?? "Unavailable"
        case .previousScore: return HomeDisplay.previousScore(value) ?? "Unavailable"
        }
    }

    static func number(_ value: Double) -> String {
        value.formatted(.number.locale(Locale(identifier: "en_US")).grouping(.never).precision(.fractionLength(0...2)))
    }

    static func durationParts(_ total: Double) -> (hours: Double, minutes: Double) {
        let displayed = (total * 100).rounded() / 100
        return (floor(displayed / 60), displayed.truncatingRemainder(dividingBy: 60))
    }

    static func delta(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return (rounded > 0 ? "+" : "") + HomeDisplay.prediction(rounded == 0 ? 0 : rounded)
    }

    static func step(for feature: TwinTrackFeature) -> Double {
        switch feature {
        case .sleepHours: 0.5
        case .steps: 500
        case .exerciseMinutes: 5
        case .studyMinutes: 15
        case .screenTimeMinutes: 30
        case .restingHeartRate, .previousScore: 1
        }
    }
}

struct WhatIfInputDraft {
    let feature: TwinTrackFeature
    private let original: Double
    private let originalFields: [String]
    var hours: String
    var minutes: String
    var number: String

    var usesDuration: Bool { [.sleepHours, .studyMinutes, .screenTimeMinutes].contains(feature) }

    init(feature: TwinTrackFeature, value: Double) {
        self.feature = feature
        original = value
        let total = feature == .sleepHours ? value * 60 : value
        let parts = WhatIfDisplay.durationParts(total)
        hours = WhatIfDisplay.number(parts.hours)
        minutes = WhatIfDisplay.number(parts.minutes)
        number = WhatIfDisplay.number(value)
        originalFields = [hours, minutes, number]
    }

    var parsedValue: Double? {
        // Opening and closing an editor must not round a precise HealthKit baseline.
        if [hours, minutes, number] == originalFields { return original }
        let value: Double
        if usesDuration {
            guard let h = Double(hours), let m = Double(minutes),
                  h.isFinite, h >= 0, h.rounded(.towardZero) == h,
                  m.isFinite, (0..<60).contains(m) else { return nil }
            let total = h * 60 + m
            value = feature == .sleepHours ? total / 60 : total
        } else {
            guard let parsed = Double(number) else { return nil }
            value = parsed
        }
        return WhatIfScenario.isValid(value, for: feature) ? value : nil
    }
}

private struct WhatIfPalette {
    let dark: Bool
    init(_ scheme: ColorScheme) { dark = scheme == .dark }
    private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r / 255, green: g / 255, blue: b / 255) }
    var background: Color { dark ? rgb(7, 11, 18) : rgb(241, 244, 248) }
    var primary: Color { dark ? rgb(242, 244, 247) : rgb(15, 27, 45) }
    var secondary: Color { dark ? rgb(226, 235, 250).opacity(0.5) : rgb(90, 107, 130) }
    var card: Color { dark ? Color.white.opacity(0.028) : .white }
    var border: Color { dark ? Color.white.opacity(0.055) : rgb(221, 227, 236) }
    var accent: Color { dark ? rgb(155, 214, 243) : rgb(11, 110, 158) }
    var surface: Color { dark ? rgb(90, 200, 240).opacity(0.06) : rgb(233, 244, 251) }
    var accentBorder: Color { dark ? rgb(122, 197, 240).opacity(0.2) : rgb(195, 222, 239) }
    var positive: Color { dark ? rgb(52, 199, 123) : rgb(24, 122, 70) }
    var negative: Color { dark ? rgb(217, 115, 110) : rgb(179, 66, 60) }
}
