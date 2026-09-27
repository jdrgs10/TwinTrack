import SwiftUI

struct BodyWellbeingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var store = BodyWellbeingStore()
    @State private var editing = false
    @State private var confirmingRemoval = false
    @State private var removalFailed = false
    @State private var permissionFailed = false
    private var palette: ProfilePalette { ProfilePalette(colorScheme) }
    private var interpretation: BMIInterpretation? {
        store.measurements.map { BMIInterpretation.evaluate($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 16) {
                    Text("BMI").font(.title2.bold())
                    Text("Calculated from height and weight")
                        .font(.subheadline).foregroundStyle(palette.secondaryText)
                    BMIGauge(value: store.measurements?.bmi, accent: palette.accentText)
                    if let value = store.measurements?.bmi {
                        Text(value, format: .number.precision(.fractionLength(1)))
                            .font(.largeTitle.bold().monospacedDigit())
                            .accessibilityIdentifier("bmiValue")
                        Text("kg/m²").font(.caption).foregroundStyle(palette.secondaryText)
                    } else {
                        Text(store.loadFailed ? "Measurements unavailable" : "No measurements yet")
                            .font(.headline).accessibilityIdentifier("bmiEmptyState")
                    }
                    Text(BMIDisplay.scaleNote(store.measurements?.bmi))
                        .font(.caption).foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.center)
                    if store.loadFailed {
                        Text("Your saved wellbeing profile couldn’t be read. Try reopening this page before replacing it.")
                            .font(.caption).foregroundStyle(palette.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(palette.card, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(palette.border))

                if let measurements = store.measurements {
                    profileSummary(measurements)
                    interpretationCard(BMIInterpretation.evaluate(measurements))
                }

                Button(store.measurements == nil ? "Add Wellbeing Profile" : "Edit Wellbeing Profile") {
                    editing = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("editBodyMeasurements")

                VStack(alignment: .leading, spacing: 8) {
                    Text("A screening measure").font(.headline)
                    Text("BMI is a screening measure and does not provide a complete picture of health or fitness.")
                    Text("If you have concerns, talk with a parent, guardian, school nurse or healthcare professional.")
                    Text("Optional, stored only on this device and never used for academic prediction.")
                }
                .font(.subheadline).foregroundStyle(palette.secondaryText)

                if store.measurements != nil || store.loadFailed {
                    Toggle("Allow BMI summary in chat", isOn: Binding(
                        get: { store.assistantAccessAllowed },
                        set: { allowed in
                            do { try store.setAssistantAccess(allowed) } catch { permissionFailed = true }
                        }
                    ))
                    .disabled(store.loadFailed)
                    .accessibilityIdentifier("bodyAssistantConsent")
                    Text("Off by default. When asked, chat can read only your derived BMI, available category/percentile and reference dates—not your date of birth, photo or full profile. Turning this off stops future access; past chat cards and exports remain until you delete them using their existing controls.")
                        .font(.caption).foregroundStyle(palette.secondaryText)
                    Button("Remove Wellbeing Profile", role: .destructive) { confirmingRemoval = true }
                        .accessibilityIdentifier("removeBodyMeasurements")
                }
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("Body & Wellbeing")
        .navigationBarTitleDisplayMode(.inline)
        .tint(palette.accentText)
        .sheet(isPresented: $editing) { BodyMeasurementsEditor(store: store) }
        .alert("Remove saved wellbeing profile?", isPresented: $confirmingRemoval) {
            Button("Remove Wellbeing Profile", role: .destructive) {
                do { try store.clear() } catch { removalFailed = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Only the locally saved date of birth, growth reference, height and weight will be removed.") }
        .alert("Profile Not Removed", isPresented: $removalFailed) {
            Button("OK", role: .cancel) {}
        } message: { Text("Please try again. Your saved wellbeing profile has not been cleared.") }
        .alert("Permission Not Saved", isPresented: $permissionFailed) {
            Button("OK", role: .cancel) {}
        } message: { Text("Please try again. The previous access setting remains in effect.") }
    }

    private func profileSummary(_ measurements: BodyMeasurements) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wellbeing profile").font(.headline)
            Text("Height: \(measurements.heightCM.formatted()) cm")
            Text("Weight: \(measurements.weightKG.formatted()) kg")
            if let date = measurements.dateOfBirth {
                Text("Date of birth: \(date.formatted(date: .abbreviated, time: .omitted))")
            }
            if let sex = measurements.growthReferenceSex {
                Text("CDC reference: \(sex.label)")
            }
        }
        .font(.body)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border))
    }

    private func interpretationCard(_ result: BMIInterpretation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if result.path == .childTeen {
                Text("BMI-for-age").font(.caption.weight(.semibold)).foregroundStyle(palette.secondaryText)
                Text(result.percentile.map { BMIDisplay.percentile($0) } ?? "Unavailable")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("bmiPercentile")
            } else if result.path == .adult {
                Text("BMI interpretation").font(.caption.weight(.semibold)).foregroundStyle(palette.secondaryText)
                Text("Adult reference").font(.title3.weight(.semibold))
            } else {
                Text("BMI-for-age").font(.caption.weight(.semibold)).foregroundStyle(palette.secondaryText)
                Text("BMI category unavailable")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("bmiCategoryUnavailable")
            }
            Text("Category").font(.caption.weight(.semibold)).foregroundStyle(palette.secondaryText)
            Text(result.category?.rawValue ?? "Unavailable")
                .font(.headline)
                .accessibilityIdentifier("bmiCategory")
            Text(result.explanation).font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border))
    }
}

private struct BodyMeasurementsEditor: View {
    @ObservedObject var store: BodyWellbeingStore
    @Environment(\.dismiss) private var dismiss
    @State private var height: String
    @State private var weight: String
    @State private var hasDateOfBirth: Bool
    @State private var dateOfBirth: Date
    @State private var growthReferenceSex: GrowthReferenceSex?
    @State private var saveFailed = false
    @FocusState private var focusedField: Field?

    private enum Field { case height, weight }

    init(store: BodyWellbeingStore) {
        self.store = store
        _height = State(initialValue: store.measurements.map { String($0.heightCM) } ?? "")
        _weight = State(initialValue: store.measurements.map { String($0.weightKG) } ?? "")
        let birthDate = store.measurements?.dateOfBirth
        _hasDateOfBirth = State(initialValue: birthDate != nil)
        _dateOfBirth = State(initialValue: birthDate ?? Calendar.current.date(byAdding: .year, value: -16, to: Date())!)
        _growthReferenceSex = State(initialValue: store.measurements?.growthReferenceSex)
    }

    private var draft: BodyMeasurements? {
        BodyMeasurements.parse(
            height: height,
            weight: weight,
            dateOfBirth: hasDateOfBirth ? dateOfBirth : nil,
            growthReferenceSex: growthReferenceSex
        )
    }

    private var draftInterpretation: BMIInterpretation? { draft.map { BMIInterpretation.evaluate($0) } }
    private var earliestBirthDate: Date { Calendar.current.date(byAdding: .year, value: -120, to: Date())! }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .height)
                        .accessibilityLabel("Height (cm)").accessibilityIdentifier("bodyHeight")
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .accessibilityLabel("Weight (kg)").accessibilityIdentifier("bodyWeight")
                } header: { Text("Measurements") } footer: {
                    Text("Enter height in centimetres and weight in kilograms. Both are optional for using TwinTrack.")
                }

                Section {
                    Toggle("Add date of birth", isOn: $hasDateOfBirth)
                        .accessibilityIdentifier("bodyHasDateOfBirth")
                    if hasDateOfBirth {
                        DatePicker(
                            "Date of birth",
                            selection: $dateOfBirth,
                            in: earliestBirthDate...Date(),
                            displayedComponents: .date
                        )
                        .accessibilityIdentifier("bodyDateOfBirth")
                    }
                    Picker("Sex used by CDC growth reference", selection: $growthReferenceSex) {
                        Text("Not provided").tag(GrowthReferenceSex?.none)
                        ForEach(GrowthReferenceSex.allCases) { value in
                            Text(value.label).tag(Optional(value))
                        }
                    }
                    .accessibilityIdentifier("bodyGrowthReferenceSex")
                } header: { Text("BMI-for-age reference") } footer: {
                    Text("CDC BMI-for-age requires date of birth and a male or female growth reference. These stay on this device and are never prediction inputs.")
                }

                Section {
                    if let bmi = draft?.bmi {
                        Text("BMI: \(bmi.formatted(.number.precision(.fractionLength(1))))")
                            .accessibilityIdentifier("bmiDraftValue")
                        if let result = draftInterpretation {
                            Text(result.percentile.map { BMIDisplay.percentile($0) }
                                 ?? (result.path == .adult ? "Adult reference" : "BMI category unavailable"))
                            Text("Category: \(result.category?.rawValue ?? "Unavailable")")
                        }
                    } else if !height.isEmpty || !weight.isEmpty {
                        Text("Check both values: height 50–250 cm and weight 10–400 kg. These are entry limits, not health targets.")
                            .accessibilityIdentifier("bmiValidation")
                    }
                    Text("Changes take effect only when you save.").font(.caption)
                } header: { Text("Preview") }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Wellbeing Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.accessibilityIdentifier("cancelBodyMeasurements")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let draft else { return }
                        do { try store.save(draft); dismiss() } catch { saveFailed = true }
                    }
                    .disabled(draft == nil).accessibilityIdentifier("saveBodyMeasurements")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .alert("Profile Not Saved", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Please try again. Your previous wellbeing profile is unchanged.") }
        }
    }
}

struct BMIGauge: View {
    let value: Double?
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height - 24)
            let radius = min(size.width / 2 - 24, size.height - 38)
            guard radius.isFinite, radius > 0 else { return }
            var arc = Path()
            arc.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            context.stroke(arc, with: .color(accent.opacity(0.18)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            for tick in stride(from: 0, through: 60, by: 10) {
                let angle = Double.pi * (1 - Double(tick) / 60)
                let labelPoint = CGPoint(x: center.x + (radius - 22) * cos(angle), y: center.y - (radius - 22) * sin(angle))
                context.draw(Text("\(tick)").font(.caption2.monospacedDigit()).foregroundColor(accent), at: labelPoint)
            }
            if let fraction = BMIDisplay.fraction(value) {
                let angle = Double.pi * (1 - fraction)
                let tip = CGPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))
                var needle = Path()
                needle.move(to: center)
                needle.addLine(to: tip)
                context.stroke(needle, with: .color(accent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: tip.x - 7, y: tip.y - 7, width: 14, height: 14)), with: .color(accent))
                context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(accent))
            }
        }
        .frame(maxWidth: 340).frame(height: 195)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("BMI numeric dial")
        .accessibilityValue(value.map { "\($0.formatted(.number.precision(.fractionLength(1)))). \(BMIDisplay.scaleNote($0))" } ?? "No measurements")
        .accessibilityIdentifier("bmiGauge")
    }
}
