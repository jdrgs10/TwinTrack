import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scoreSize = 62.0

    let openAI: () -> Void

    private var palette: HomePalette { HomePalette(colorScheme) }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    PageHeader(title: "Home", subtitle: "Your habits. Your data. Your academic twin.")
                    healthStatus
                    predictionHero
                    inputSection
                    emptyTrendCard
                    insightCard
                    openAIButton
                }
            }
            .accessibilityIdentifier("homeScrollView")
            .refreshable {
                // Native refresh lifetime follows the existing shared query; no timer,
                // polling, or Home-owned copy of HealthKit state is needed.
                await state.refreshHealth()
            }
            .scrollBounceBehavior(.always)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(palette.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }

    private var healthStatus: some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(healthStatusColor)
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)
                Text("Apple Health")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(state.healthAccess.rawValue)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var predictionHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PREDICTED ASSESSMENT SCORE")
                .font(.subheadline.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(palette.accentText)
                .fixedSize(horizontal: false, vertical: true)

            if let prediction = state.currentPrediction {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(HomeDisplay.prediction(prediction))
                        .font(.system(size: scoreSize, weight: .semibold))
                        .tracking(-2.4)
                        .monospacedDigit()
                        .foregroundStyle(palette.heroText)
                    Text("/ 100")
                        .font(.body)
                        .foregroundStyle(palette.tertiaryText)
                    Spacer(minLength: 0)
                }

                ProgressView(value: prediction, total: 100)
                    .tint(palette.accent)
                    .accessibilityLabel("Predicted assessment score")
                    .accessibilityValue("\(HomeDisplay.prediction(prediction)) out of 100")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prediction unavailable")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(palette.heroText)
                    Text("Missing: \(state.missingInputs.map(HomeDisplay.featureName).joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Text("Ridge Regression • 7 inputs • On-device")
                .font(.caption)
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .background(palette.accentSurface, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(palette.accentBorder, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .privacySensitive()
        .accessibilityElement(children: .combine)
    }

    private var inputSection: some View {
        VStack(spacing: 9) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    inputSectionTitle
                    Spacer(minLength: 0)
                    inputWindowCaption
                }
                VStack(alignment: .leading, spacing: 5) {
                    inputSectionTitle
                    inputWindowCaption
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 1)

            LazyVGrid(columns: columns, spacing: 9) {
                healthMetric("Sleep", result: state.healthReadings.sleep, value: HomeDisplay.sleep)
                healthMetric("Steps", result: state.healthReadings.steps, value: HomeDisplay.steps)
                healthMetric("Exercise", result: state.healthReadings.exercise, value: HomeDisplay.exercise)
                healthMetric("Resting Heart Rate", result: state.healthReadings.restingHeartRate, value: HomeDisplay.restingHeartRate)
                HomeMetricCard(
                    title: "Study",
                    value: HomeDisplay.duration(minutes: state.studyMinutes),
                    unavailable: "Not entered",
                    source: "MANUAL",
                    palette: palette
                )
                HomeMetricCard(
                    title: "Screen Time",
                    value: HomeDisplay.duration(minutes: state.screenTimeMinutes),
                    unavailable: "Not entered",
                    source: "MANUAL",
                    palette: palette
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Previous Score")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                    HomeSourceLabel(source: "MANUAL", health: false, palette: palette)
                }
                Spacer()
                Text(HomeDisplay.previousScore(state.previousScore) ?? "Not entered")
                    .font(state.previousScore == nil ? .footnote : .title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(state.previousScore == nil ? palette.tertiaryText : palette.primaryText)
                    .privacySensitive()
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .background(palette.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(palette.border, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
    }

    private var inputSectionTitle: some View {
        Text("TODAY'S INPUTS")
            .font(.caption2.weight(.semibold))
            .tracking(1.1)
            .foregroundStyle(palette.secondaryText)
    }

    private var inputWindowCaption: some View {
        Text("Health: previous completed day")
            .font(.caption2)
            .foregroundStyle(palette.tertiaryText)
    }

    private var emptyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-DAY TREND")
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(palette.secondaryText)
            Text("No prediction history yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.primaryText)
            Text("Trends will appear after real prediction history is implemented.")
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 17)
        .padding(.horizontal, 18)
        .padding(.bottom, 15)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.border, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Circle()
                    .fill(palette.violet)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
                Text("MODEL INSIGHT")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(palette.violetText)
            }
            Text("TwinTrack combines all seven inputs to produce the current prediction. Model relationships are predictive, not causal.")
                .font(.subheadline)
                .foregroundStyle(palette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(palette.violetSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.violetBorder, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var openAIButton: some View {
        Button(action: openAI) {
            HStack(spacing: 8) {
                Text("Open TwinTrack AI")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(palette.accentStrong, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("openTwinTrackAI")
        .padding(.horizontal, 16)
        .padding(.top, 16)
        // The native TabView reserves its safe area; this is additional breathing room.
        .padding(.bottom, 28)
    }

    private var healthStatusColor: Color {
        switch state.healthAccess {
        case .completed: palette.green
        case .notRequested, .requesting, .failed, .unavailable: palette.amber
        }
    }

    private func healthMetric(
        _ title: String,
        result: HealthMetricResult,
        value: (Double?) -> String?
    ) -> some View {
        HomeMetricCard(
            title: title,
            value: state.isRefreshingHealth ? nil : value(result.value),
            unavailable: state.isRefreshingHealth
                ? "Refreshing…"
                : (result == .failed ? "Query failed" : "No accessible recent value"),
            source: "APPLE HEALTH",
            palette: palette
        )
    }
}

enum HomeDisplay {
    nonisolated static func duration(minutes: Int?) -> String? {
        guard let minutes, minutes >= 0 else { return nil }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder) min" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }

    nonisolated static func sleep(_ hours: Double?) -> String? {
        guard let hours, hours.isFinite, hours >= 0,
              hours <= Double(Int.max) / 60 else { return nil }
        return duration(minutes: Int((hours * 60).rounded()))
    }

    nonisolated static func steps(_ value: Double?) -> String? {
        whole(value)
    }

    nonisolated static func exercise(_ value: Double?) -> String? {
        whole(value).map { "\($0) min" }
    }

    nonisolated static func restingHeartRate(_ value: Double?) -> String? {
        whole(value).map { "\($0) bpm" }
    }

    nonisolated static func previousScore(_ value: Double?) -> String? {
        guard let value, value.isFinite, (0...100).contains(value) else { return nil }
        return value.formatted(
            .number.locale(Locale(identifier: "en_US"))
                .precision(.fractionLength(0...1))
        )
    }

    nonisolated static func prediction(_ value: Double) -> String {
        value.formatted(
            .number.locale(Locale(identifier: "en_US"))
                .precision(.fractionLength(1))
        )
    }

    nonisolated static func featureName(_ feature: TwinTrackFeature) -> String {
        switch feature {
        case .sleepHours: "Sleep"
        case .steps: "Steps"
        case .exerciseMinutes: "Exercise"
        case .restingHeartRate: "Resting Heart Rate"
        case .studyMinutes: "Study"
        case .screenTimeMinutes: "Screen Time"
        case .previousScore: "Previous Score"
        }
    }

    nonisolated private static func whole(_ value: Double?) -> String? {
        guard let value, value.isFinite, value >= 0,
              value <= Double(Int.max) else { return nil }
        return Int(value.rounded()).formatted(
            .number.locale(Locale(identifier: "en_US"))
                .grouping(.automatic)
        )
    }
}

private struct HomeMetricCard: View {
    let title: String
    let value: String?
    let unavailable: String
    let source: String
    let palette: HomePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)
            Spacer(minLength: 0)
            Text(value ?? unavailable)
                .font(value == nil ? .footnote : .title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(value == nil ? palette.tertiaryText : palette.primaryText)
                .privacySensitive()
            HomeSourceLabel(source: source, health: source == "APPLE HEALTH", palette: palette)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .padding(.top, 13)
        .padding(.horizontal, 13)
        .padding(.bottom, 11)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(palette.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HomeSourceLabel: View {
    let source: String
    let health: Bool
    let palette: HomePalette

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(health ? palette.accent : palette.tertiaryText)
                .frame(width: 5, height: 5)
                .accessibilityHidden(true)
            Text(source)
                .font(.caption2.weight(.medium))
                .tracking(0.4)
                .foregroundStyle(health ? palette.accentText : palette.secondaryText)
        }
    }
}

private struct HomePalette {
    let background: Color
    let card: Color
    let border: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let heroText: Color
    let accent: Color
    let accentText: Color
    let accentSurface: Color
    let accentBorder: Color
    let accentStrong: Color
    let violet: Color
    let violetText: Color
    let violetSurface: Color
    let violetBorder: Color
    let green: Color
    let amber: Color

    init(_ scheme: ColorScheme) {
        if scheme == .dark {
            background = Color(red: 7 / 255, green: 11 / 255, blue: 18 / 255)
            card = Color.white.opacity(0.028)
            border = Color.white.opacity(0.055)
            primaryText = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
            secondaryText = Color(red: 226 / 255, green: 235 / 255, blue: 250 / 255).opacity(0.5)
            tertiaryText = secondaryText
            heroText = Color(red: 234 / 255, green: 246 / 255, blue: 253 / 255)
            accent = Color(red: 90 / 255, green: 200 / 255, blue: 240 / 255)
            accentText = Color(red: 155 / 255, green: 214 / 255, blue: 243 / 255)
            accentSurface = accent.opacity(0.06)
            accentBorder = Color(red: 122 / 255, green: 197 / 255, blue: 240 / 255).opacity(0.2)
            accentStrong = Color(red: 25 / 255, green: 118 / 255, blue: 184 / 255)
            violet = Color(red: 154 / 255, green: 143 / 255, blue: 240 / 255)
            violetText = Color(red: 178 / 255, green: 168 / 255, blue: 245 / 255).opacity(0.85)
            violetSurface = Color(red: 139 / 255, green: 127 / 255, blue: 232 / 255).opacity(0.06)
            violetBorder = Color(red: 139 / 255, green: 127 / 255, blue: 232 / 255).opacity(0.16)
            green = Color(red: 52 / 255, green: 199 / 255, blue: 123 / 255)
            amber = Color(red: 227 / 255, green: 162 / 255, blue: 60 / 255)
        } else {
            background = Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
            card = .white
            border = Color(red: 221 / 255, green: 227 / 255, blue: 236 / 255)
            primaryText = Color(red: 15 / 255, green: 27 / 255, blue: 45 / 255)
            secondaryText = Color(red: 90 / 255, green: 107 / 255, blue: 130 / 255)
            tertiaryText = Color(red: 96 / 255, green: 112 / 255, blue: 135 / 255)
            heroText = Color(red: 11 / 255, green: 32 / 255, blue: 51 / 255)
            accent = Color(red: 14 / 255, green: 127 / 255, blue: 184 / 255)
            accentText = Color(red: 11 / 255, green: 110 / 255, blue: 158 / 255)
            accentSurface = Color(red: 233 / 255, green: 244 / 255, blue: 251 / 255)
            accentBorder = Color(red: 195 / 255, green: 222 / 255, blue: 239 / 255)
            accentStrong = Color(red: 11 / 255, green: 110 / 255, blue: 158 / 255)
            violet = Color(red: 91 / 255, green: 75 / 255, blue: 196 / 255)
            violetText = Color(red: 80 / 255, green: 68 / 255, blue: 176 / 255)
            violetSurface = Color(red: 242 / 255, green: 240 / 255, blue: 253 / 255)
            violetBorder = Color(red: 218 / 255, green: 212 / 255, blue: 246 / 255)
            green = Color(red: 24 / 255, green: 122 / 255, blue: 70 / 255)
            amber = Color(red: 154 / 255, green: 102 / 255, blue: 8 / 255)
        }
    }
}
