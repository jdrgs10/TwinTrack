import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingManualInputs = false

    private var background: Color {
        colorScheme == .dark
            ? Color(red: 7 / 255, green: 11 / 255, blue: 18 / 255)
            : Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
    }

    private var card: Color {
        colorScheme == .dark ? Color.white.opacity(0.028) : .white
    }

    private var border: Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color(red: 221 / 255, green: 227 / 255, blue: 236 / 255)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    Text("DATA SOURCES")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)

                    Button {
                        isShowingManualInputs = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 30)
                                .background(border, in: RoundedRectangle(cornerRadius: 9))

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 7) {
                                    Text("Manual Inputs")
                                        .font(.subheadline.weight(.medium))

                                    Text("Entered in TwinTrack")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(border, in: Capsule())
                                }

                                Text(manualInputSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(card, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(border, lineWidth: 1)
                    }
                    .accessibilityIdentifier("manualInputsButton")
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
            }
            .background(background.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbarBackground(background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .sheet(isPresented: $isShowingManualInputs) {
                ManualInputsSheet(
                    initialStudyMinutes: state.studyMinutes,
                    initialScreenTimeMinutes: state.screenTimeMinutes,
                    initialPreviousScore: state.previousScore
                )
                .environmentObject(state)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var manualInputSummary: String {
        let enteredCount = [
            state.studyMinutes != nil,
            state.screenTimeMinutes != nil,
            state.previousScore != nil,
        ].filter { $0 }.count

        return enteredCount == 0
            ? "Study time, screen time and previous score · Not entered"
            : "\(enteredCount) of 3 values entered"
    }
}

private struct ManualInputsSheet: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var draftStudyMinutes: Int?
    @State private var draftScreenTimeMinutes: Int?
    @State private var previousScoreText: String
    @State private var openPicker: TimeInput?

    private enum TimeInput {
        case study
        case screen
    }

    init(
        initialStudyMinutes: Int?,
        initialScreenTimeMinutes: Int?,
        initialPreviousScore: Double?
    ) {
        _draftStudyMinutes = State(initialValue: initialStudyMinutes)
        _draftScreenTimeMinutes = State(initialValue: initialScreenTimeMinutes)
        _previousScoreText = State(initialValue: Self.scoreText(initialPreviousScore))
    }

    private var border: Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color(red: 221 / 255, green: 227 / 255, blue: 236 / 255)
    }

    private var card: Color {
        colorScheme == .dark ? Color.white.opacity(0.028) : .white
    }

    private var isScoreValid: Bool {
        PreviousScoreInput.isValidDraft(previousScoreText)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 9) {
                    timeField(
                        title: "Study Time",
                        value: $draftStudyMinutes,
                        input: .study
                    )

                    timeField(
                        title: "Screen Time",
                        value: $draftScreenTimeMinutes,
                        input: .screen
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Previous Score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("Not entered", text: $previousScoreText)
                                    .keyboardType(.decimalPad)
                                    .font(.body.weight(.medium))
                                    .accessibilityIdentifier("previousScoreField")
                            }

                            Text("manual")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if !isScoreValid {
                            Text("Enter a number from 0 to 100.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(card, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isScoreValid ? border : .red, lineWidth: 1)
                    }

                    Text("These three inputs are entered in TwinTrack. They are not Apple Health data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .navigationTitle("Manual Inputs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isScoreValid)
                        .accessibilityIdentifier("saveManualInputsButton")
                }
            }
        }
    }

    @ViewBuilder
    private func timeField(
        title: String,
        value: Binding<Int?>,
        input: TimeInput
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                if value.wrappedValue == nil {
                    value.wrappedValue = 0
                }
                openPicker = openPicker == input ? nil : input
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedDuration(value.wrappedValue))
                            .font(.body.weight(.medium))
                    }

                    Spacer()

                    Text("manual")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Image(systemName: openPicker == input ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if openPicker == input {
                Divider()

                HStack(spacing: 0) {
                    wheelColumn(
                        title: "Hours",
                        range: 0...ManualDuration.maximumHours,
                        selection: hoursBinding(for: value),
                        twoDigits: false
                    )

                    wheelColumn(
                        title: "Minutes",
                        range: 0...59,
                        selection: minutesBinding(for: value),
                        twoDigits: true
                    )
                }
                .frame(height: 170)
                .padding(.horizontal, 8)
            }
        }
        .background(card, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(openPicker == input ? Color.accentColor.opacity(0.45) : border, lineWidth: 1)
        }
    }

    private func wheelColumn(
        title: String,
        range: ClosedRange<Int>,
        selection: Binding<Int>,
        twoDigits: Bool
    ) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker(title, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text(twoDigits ? String(format: "%02d", value) : "\(value)")
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }

    private func hoursBinding(for total: Binding<Int?>) -> Binding<Int> {
        Binding(
            get: { ManualDuration.parts(from: total.wrappedValue ?? 0)?.hours ?? 0 },
            set: { hours in
                let minutes = ManualDuration.parts(from: total.wrappedValue ?? 0)?.minutes ?? 0
                total.wrappedValue = ManualDuration.totalMinutes(hours: hours, minutes: minutes)
            }
        )
    }

    private func minutesBinding(for total: Binding<Int?>) -> Binding<Int> {
        Binding(
            get: { ManualDuration.parts(from: total.wrappedValue ?? 0)?.minutes ?? 0 },
            set: { minutes in
                let hours = ManualDuration.parts(from: total.wrappedValue ?? 0)?.hours ?? 0
                total.wrappedValue = ManualDuration.totalMinutes(hours: hours, minutes: minutes)
            }
        )
    }

    private func formattedDuration(_ totalMinutes: Int?) -> String {
        guard let totalMinutes,
              let parts = ManualDuration.parts(from: totalMinutes) else {
            return "Not entered"
        }

        return "\(parts.hours)h \(parts.minutes)m"
    }

    private func save() {
        let trimmedScore = previousScoreText.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = trimmedScore.isEmpty ? nil : PreviousScoreInput.parse(trimmedScore)

        if state.saveManualInputs(
            studyMinutes: draftStudyMinutes,
            screenTimeMinutes: draftScreenTimeMinutes,
            previousScore: score
        ) {
            dismiss()
        }
    }

    private static func scoreText(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}
