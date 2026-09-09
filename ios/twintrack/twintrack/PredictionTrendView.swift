import SwiftUI

struct PredictionTrendView: View {
    let snapshots: [PredictionSnapshot]
    var now = Date()

    @Environment(\.calendar) private var calendar
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedSnapshotID: UUID?
    @State private var presentedSnapshot: PredictionSnapshot?

    private var palette: PredictionTrendPalette { PredictionTrendPalette(colorScheme) }

    private var displayedSnapshots: [PredictionSnapshot] {
#if DEBUG
        // The review launch uses the same isolated fixture as SwiftUI previews and
        // never writes synthetic snapshots into production history.
        if ProcessInfo.processInfo.arguments.contains("--synthetic-history-review") {
            return SyntheticHistoryPreview.snapshots
        }
#endif
        return snapshots
    }

    private var points: [PredictionTrendPoint] {
        PredictionHistoryTrend.points(from: displayedSnapshots, now: now, calendar: calendar)
    }

    private var days: [Date] {
        PredictionHistoryTrend.days(now: now, calendar: calendar)
    }

    private var slots: [PredictionTrendSlot] {
        PredictionTrendPresentation.slots(days: days, points: points)
    }

    private var selectedPoint: PredictionTrendPoint? {
        PredictionTrendPresentation.selectedPoint(
            id: selectedSnapshotID,
            points: points
        )
    }

    private var trendSummary: PredictionTrendSummary {
        PredictionTrendPresentation.summary(points: points)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    title
                    Spacer(minLength: 0)
                    selectedScoreLabel
                }
                VStack(alignment: .leading, spacing: 5) {
                    title
                    selectedScoreLabel
                }
            }

            if points.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("No prediction history yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.primaryText)
                    Text("A trend appears after TwinTrack saves complete real predictions.")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                }
                .padding(.top, 16)
            } else {
                chart
                Divider()
                    .overlay(palette.border)
                    .padding(.top, 13)
                summaryRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 17)
        .padding(.horizontal, 18)
        .padding(.bottom, 15)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(palette.border, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .privacySensitive()
        .accessibilityIdentifier("predictionTrendCard")
        .onAppear(perform: keepSelectionValid)
        .onChange(of: points.map(\.snapshot.id)) { _, _ in keepSelectionValid() }
        .sheet(item: $presentedSnapshot) { snapshot in
            PredictionHistoryDetailView(snapshot: snapshot)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var title: some View {
        Text("7-DAY TREND")
            .font(.caption2.weight(.semibold))
            .tracking(1.1)
            .foregroundStyle(palette.secondaryText)
    }

    @ViewBuilder
    private var selectedScoreLabel: some View {
        if let selectedPoint {
            Text("Predicted score \(HomeDisplay.prediction(selectedPoint.snapshot.prediction))")
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(palette.accentText)
                .accessibilityIdentifier("predictionTrendSelectedScore")
        }
    }

    private var chart: some View {
        HStack(alignment: .bottom, spacing: dynamicTypeSize.isAccessibilitySize ? 3 : 7) {
            ForEach(slots) { slot in
                if let point = slot.point {
                    realBar(point, day: slot.day)
                } else {
                    missingBar(day: slot.day)
                }
            }
        }
        .padding(.top, 16)
        .accessibilityIdentifier("predictionTrendChart")
    }

    private func realBar(_ point: PredictionTrendPoint, day: Date) -> some View {
        let isSelected = selectedPoint?.snapshot.id == point.snapshot.id
        return Button {
            selectedSnapshotID = point.snapshot.id
            presentedSnapshot = point.snapshot
        } label: {
            barColumn(day: day) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? palette.selectedBar : palette.historicalBar)
                    .frame(
                        height: PredictionTrendPresentation.barHeight(
                            prediction: point.snapshot.prediction
                        )
                    )
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel(for: day, point: point))
        .accessibilityHint("Shows the saved prediction details")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("predictionTrendBar.\(PredictionTrendPresentation.dayKey(day, calendar: calendar))")
    }

    private func missingBar(day: Date) -> some View {
        barColumn(day: day) {
            Capsule()
                .fill(palette.missingSlot)
                .frame(height: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), no saved prediction")
        .accessibilityIdentifier("predictionTrendMissing.\(PredictionTrendPresentation.dayKey(day, calendar: calendar))")
    }

    private func barColumn<Bar: View>(
        day: Date,
        @ViewBuilder bar: () -> Bar
    ) -> some View {
        VStack(spacing: 7) {
            VStack {
                Spacer(minLength: 0)
                bar()
            }
            .frame(height: PredictionTrendPresentation.chartHeight)

            Text(PredictionTrendPresentation.dayLabel(day, calendar: calendar))
                .font(.caption2)
                .foregroundStyle(palette.secondaryText)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                summaryDescription
                Spacer(minLength: 0)
                summaryDelta
            }
            VStack(alignment: .leading, spacing: 5) {
                summaryDescription
                summaryDelta
            }
        }
        .padding(.top, 12)
    }

    private var summaryDescription: some View {
        Text(trendSummary.description)
            .font(.caption)
            .foregroundStyle(palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("predictionTrendSummary")
    }

    @ViewBuilder
    private var summaryDelta: some View {
        if let delta = trendSummary.delta {
            Text(PredictionHistoryDisplay.delta(delta))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(palette.primaryText)
                .accessibilityLabel("Seven-day prediction change \(PredictionHistoryDisplay.delta(delta))")
                .accessibilityIdentifier("predictionTrendDelta")
        }
    }

    private func accessibilityLabel(for day: Date, point: PredictionTrendPoint) -> String {
        let date = day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        return "\(date), predicted score \(HomeDisplay.prediction(point.snapshot.prediction)) out of 100"
    }

    private func keepSelectionValid() {
        guard !points.isEmpty else {
            selectedSnapshotID = nil
            return
        }
        if !points.contains(where: { $0.snapshot.id == selectedSnapshotID }) {
            selectedSnapshotID = points.last?.snapshot.id
        }
    }
}

struct PredictionTrendSlot: Identifiable, Equatable, Sendable {
    let day: Date
    let point: PredictionTrendPoint?

    var id: Date { day }
}

struct PredictionTrendSummary: Equatable, Sendable {
    let description: String
    let delta: Double?
}

enum PredictionTrendPresentation {
    static let chartHeight = 72.0

    static func slots(
        days: [Date],
        points: [PredictionTrendPoint]
    ) -> [PredictionTrendSlot] {
        let pointsByDay = Dictionary(uniqueKeysWithValues: points.map { ($0.day, $0) })
        return days.map { PredictionTrendSlot(day: $0, point: pointsByDay[$0]) }
    }

    static func selectedPoint(
        id: UUID?,
        points: [PredictionTrendPoint]
    ) -> PredictionTrendPoint? {
        points.first(where: { $0.snapshot.id == id }) ?? points.last
    }

    static func barHeight(prediction: Double, maximum: Double = chartHeight) -> Double {
        // Every window uses the same 0...100 scale; missing values never call this path.
        min(max(prediction, 0), 100) / 100 * maximum
    }

    static func summary(points: [PredictionTrendPoint]) -> PredictionTrendSummary {
        guard let first = points.first?.snapshot,
              let last = points.last?.snapshot,
              points.count >= 2 else {
            return PredictionTrendSummary(
                description: "Insufficient history for a trend",
                delta: nil
            )
        }

        let delta = last.prediction - first.prediction
        let description: String
        if delta > 0.05 {
            description = "Prediction increased across available days"
        } else if delta < -0.05 {
            description = "Prediction decreased across available days"
        } else {
            description = "Prediction remained relatively stable"
        }
        return PredictionTrendSummary(description: description, delta: delta)
    }

    static func dayLabel(_ day: Date, calendar: Calendar) -> String {
        switch calendar.component(.weekday, from: day) {
        case 1: "Su"
        case 2: "M"
        case 3: "T"
        case 4: "W"
        case 5: "Th"
        case 6: "F"
        case 7: "S"
        default: ""
        }
    }

    static func dayKey(_ day: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}

private struct PredictionTrendPalette {
    let colorScheme: ColorScheme

    init(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    var card: Color { colorScheme == .dark ? .white.opacity(0.028) : .white }
    var border: Color {
        colorScheme == .dark
            ? .white.opacity(0.055)
            : Color(red: 221 / 255, green: 227 / 255, blue: 236 / 255)
    }
    var primaryText: Color {
        colorScheme == .dark
            ? Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
            : Color(red: 15 / 255, green: 27 / 255, blue: 45 / 255)
    }
    var secondaryText: Color {
        colorScheme == .dark
            ? .white.opacity(0.52)
            : Color(red: 90 / 255, green: 107 / 255, blue: 130 / 255)
    }
    var accentText: Color {
        colorScheme == .dark
            ? Color(red: 155 / 255, green: 214 / 255, blue: 243 / 255)
            : Color(red: 11 / 255, green: 110 / 255, blue: 158 / 255)
    }
    var selectedBar: Color {
        colorScheme == .dark
            ? Color(red: 90 / 255, green: 200 / 255, blue: 240 / 255)
            : Color(red: 14 / 255, green: 127 / 255, blue: 184 / 255)
    }
    var historicalBar: Color {
        colorScheme == .dark
            ? Color(red: 90 / 255, green: 200 / 255, blue: 240 / 255).opacity(0.26)
            : Color(red: 190 / 255, green: 221 / 255, blue: 240 / 255)
    }
    var missingSlot: Color { border.opacity(colorScheme == .dark ? 0.8 : 0.7) }
}

struct PredictionHistoryDetailView: View {
    let snapshot: PredictionSnapshot

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var rows: [PredictionHistoryDetailRow] {
        PredictionHistoryDetail.rows(snapshot: snapshot)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(snapshot.createdAt.formatted(
                        .dateTime.weekday(.wide).month(.wide).day().year().hour().minute()
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("historyDetailDate")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("PREDICTED ASSESSMENT SCORE")
                            .font(.caption2.weight(.semibold))
                            .tracking(0.8)
                            .foregroundStyle(accentText)
                        Text(HomeDisplay.prediction(snapshot.prediction))
                            .font(.largeTitle.weight(.semibold))
                            .monospacedDigit()
                        Text("out of 100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(card, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("historyDetailPrediction")

                    VStack(alignment: .leading, spacing: 0) {
                        Text("INPUTS USED")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)

                        ForEach(rows) { row in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(row.label)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 8)
                                Text(row.value)
                                    .fontWeight(.medium)
                                    .monospacedDigit()
                                    .multilineTextAlignment(.trailing)
                            }
                            .font(.subheadline)
                            .padding(.vertical, 11)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("historyDetailInput.\(row.id)")

                            if row.id != rows.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(card, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1)
                    }

                    Text("This prediction was generated using the TwinTrack model and the values recorded at that time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("historyDetailDisclaimer")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 34)
            }
            .background(background.ignoresSafeArea())
            .navigationTitle("Prediction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .privacySensitive()
    }

    private var background: Color {
        colorScheme == .dark
            ? Color(red: 7 / 255, green: 11 / 255, blue: 18 / 255)
            : Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
    }
    private var card: Color { colorScheme == .dark ? .white.opacity(0.028) : .white }
    private var border: Color {
        colorScheme == .dark
            ? .white.opacity(0.055)
            : Color(red: 221 / 255, green: 227 / 255, blue: 236 / 255)
    }
    private var accentText: Color {
        colorScheme == .dark
            ? Color(red: 155 / 255, green: 214 / 255, blue: 243 / 255)
            : Color(red: 11 / 255, green: 110 / 255, blue: 158 / 255)
    }
}

struct PredictionHistoryDetailRow: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
}

enum PredictionHistoryDetail {
    static func rows(snapshot: PredictionSnapshot) -> [PredictionHistoryDetailRow] {
        let inputs = snapshot.inputs
        return [
            row("sleep", "Sleep", HomeDisplay.sleep(inputs.sleepHours)),
            row("steps", "Steps", HomeDisplay.steps(inputs.steps)),
            row("exercise", "Exercise", HomeDisplay.exercise(inputs.exerciseMinutes)),
            row("restingHeartRate", "Resting Heart Rate", HomeDisplay.restingHeartRate(inputs.restingHeartRate)),
            row("study", "Study", duration(inputs.studyMinutes)),
            row("screenTime", "Screen Time", duration(inputs.screenTimeMinutes)),
            row("previousScore", "Previous Score", HomeDisplay.previousScore(inputs.previousScore)),
        ]
    }

    private static func row(
        _ id: String,
        _ label: String,
        _ value: String?
    ) -> PredictionHistoryDetailRow {
        PredictionHistoryDetailRow(id: id, label: label, value: value ?? "Unavailable")
    }

    private static func duration(_ minutes: Double) -> String? {
        guard minutes.isFinite,
              minutes >= 0,
              minutes <= Double(Int.max) else { return nil }
        return HomeDisplay.duration(minutes: Int(minutes.rounded()))
    }
}

struct DataPrivacyView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isConfirmingClear = false

    var body: some View {
        List {
            Section {
                if state.predictionHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("No saved predictions")
                            .font(.subheadline.weight(.semibold))
                        Text("Complete real predictions will appear here after a Health refresh or Manual Inputs save.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("predictionHistoryEmptyState")
                } else {
                    ForEach(state.predictionHistory.reversed()) { snapshot in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Predicted score")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(HomeDisplay.prediction(snapshot.prediction))
                                    .font(.title3.weight(.semibold).monospacedDigit())
                            }
                            Text(snapshot.createdAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("7 real inputs\(snapshot.healthWindow == nil ? "" : " · completed Health window")")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .privacySensitive()
                        .accessibilityElement(children: .combine)
                    }
                }
            } header: {
                Text("Prediction History")
            } footer: {
                Text("Stored only on this device. What-If results are never included.")
            }

            Section("Data Controls") {
                Button("Clear Prediction History", role: .destructive) {
                    isConfirmingClear = true
                }
                .disabled(state.predictionHistory.isEmpty)
                .accessibilityIdentifier("clearPredictionHistoryButton")
            }
        }
        .scrollContentBackground(.hidden)
        .background(background.ignoresSafeArea())
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Clear Prediction History?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear Prediction History", role: .destructive) {
                state.clearPredictionHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes prediction history only. Your manual inputs and Health state stay unchanged.")
        }
    }

    private var background: Color {
        colorScheme == .dark
            ? Color(red: 7 / 255, green: 11 / 255, blue: 18 / 255)
            : Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
    }
}

enum PredictionHistoryDisplay {
    static func historySummary(_ count: Int) -> String {
        count == 1 ? "1 saved prediction" : "\(count) saved predictions"
    }

    static func delta(_ value: Double) -> String {
        let rounded = abs(value) < 0.05 ? 0 : value
        let formatted = abs(rounded).formatted(.number.precision(.fractionLength(1)))
        if rounded > 0 { return "+\(formatted)" }
        if rounded < 0 { return "−\(formatted)" }
        return "0.0"
    }
}

#if DEBUG
@MainActor
private final class SyntheticHistoryPreviewStore: PredictionHistoryPersisting {
    private var snapshots: [PredictionSnapshot]

    init(_ snapshots: [PredictionSnapshot]) {
        self.snapshots = snapshots
    }

    func load() -> [PredictionSnapshot] { snapshots }
    func save(_ snapshots: [PredictionSnapshot]) throws { self.snapshots = snapshots }
}

@MainActor
private enum SyntheticHistoryPreview {
    static let now = Date()
    static let snapshots = [
        makeSnapshot(daysAgo: 5, studyMinutes: 60),
        makeSnapshot(daysAgo: 2, studyMinutes: 120),
        makeSnapshot(daysAgo: 0, studyMinutes: 180),
    ]

    static func makeState() -> TwinTrackState {
        let defaults = UserDefaults(suiteName: "TwinTrack.SyntheticHistoryPreview")!
        return TwinTrackState(
            defaults: defaults,
            historyStore: SyntheticHistoryPreviewStore(snapshots)
        )
    }

    private static func makeSnapshot(daysAgo: Int, studyMinutes: Double) -> PredictionSnapshot {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let profile = TwinTrackProfile(
            sleepHours: 7,
            steps: 6500,
            exerciseMinutes: 30,
            restingHeartRate: 68,
            studyMinutes: studyMinutes,
            screenTimeMinutes: 240,
            previousScore: 75
        )
        return PredictionSnapshot.realBaseline(
            profile: profile,
            createdAt: date,
            healthWindow: nil
        )!
    }
}

#Preview("Synthetic partial history — full app") {
    ContentView()
        .environmentObject(SyntheticHistoryPreview.makeState())
}

#Preview("Synthetic history — clear controls") {
    NavigationStack {
        DataPrivacyView()
    }
    .environmentObject(SyntheticHistoryPreview.makeState())
}
#endif
