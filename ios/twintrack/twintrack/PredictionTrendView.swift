import SwiftUI

struct PredictionTrendView: View {
    let snapshots: [PredictionSnapshot]
    var now = Date()

    @Environment(\.calendar) private var calendar
    @Environment(\.colorScheme) private var colorScheme

    private var points: [PredictionTrendPoint] {
        PredictionHistoryTrend.points(from: snapshots, now: now, calendar: calendar)
    }

    private var pointsByDay: [Date: PredictionTrendPoint] {
        Dictionary(uniqueKeysWithValues: points.map { ($0.day, $0) })
    }

    private var days: [Date] {
        PredictionHistoryTrend.days(now: now, calendar: calendar)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-DAY TREND")
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(secondaryText)

            if points.isEmpty {
                Text("No prediction history yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text("A trend appears after TwinTrack saves complete real predictions.")
                    .font(.footnote)
                    .foregroundStyle(secondaryText)
            } else {
                chart
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 17)
        .padding(.horizontal, 18)
        .padding(.bottom, 15)
        .background(card, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(border, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .privacySensitive()
        .accessibilityIdentifier("predictionTrendCard")
    }

    private var chart: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(days, id: \.self) { day in
                let point = pointsByDay[day]
                VStack(spacing: 5) {
                    Spacer(minLength: 0)
                    if let point {
                        Text(HomeDisplay.prediction(point.snapshot.prediction))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(primaryText)
                            .minimumScaleFactor(0.7)
                        Capsule()
                            .fill(accent)
                            .frame(height: max(4, 62 * point.snapshot.prediction / 100))
                    } else {
                        Capsule()
                            .fill(border)
                            .frame(height: 2)
                            .accessibilityHidden(true)
                    }
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 98, alignment: .bottom)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: day, point: point))
            }
        }
        .accessibilityIdentifier("predictionTrendChart")
    }

    private var summary: String {
        guard let first = points.first?.snapshot,
              let last = points.last?.snapshot else { return "" }
        if points.count == 1 {
            return "1 saved day in the last 7 days."
        }
        let delta = last.prediction - first.prediction
        return "\(points.count) saved days · \(PredictionHistoryDisplay.delta(delta)) from first to latest"
    }

    private func accessibilityLabel(for day: Date, point: PredictionTrendPoint?) -> String {
        let date = day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        guard let point else { return "\(date), no saved prediction" }
        return "\(date), predicted score \(HomeDisplay.prediction(point.snapshot.prediction)) out of 100"
    }

    private var card: Color {
        colorScheme == .dark ? Color.white.opacity(0.028) : .white
    }

    private var border: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.055)
            : Color(red: 221 / 255, green: 227 / 255, blue: 236 / 255)
    }

    private var primaryText: Color {
        colorScheme == .dark
            ? Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
            : Color(red: 21 / 255, green: 28 / 255, blue: 38 / 255)
    }

    private var secondaryText: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.52)
            : Color(red: 91 / 255, green: 103 / 255, blue: 120 / 255)
    }

    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 90 / 255, green: 200 / 255, blue: 240 / 255)
            : Color(red: 14 / 255, green: 127 / 255, blue: 184 / 255)
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
