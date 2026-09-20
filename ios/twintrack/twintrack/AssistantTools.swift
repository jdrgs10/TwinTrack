import Foundation
import FoundationModels

/// A value copy captured once at Send. Tool calls cannot read later refreshes or
/// mutate the real store; every baseline/scenario/delta in this request agrees.
struct AssistantSnapshot: Sendable {
    let values: [Double?]
    let health: HealthReadings
    let window: HealthDataWindow?
    let history: [PredictionSnapshot]
    let capturedAt: Date
    let calendar: Calendar
    let predictionStatus: PredictionStatus
    let lastPrediction: PredictionSnapshot?

    @MainActor init(state: TwinTrackState, now: Date = Date(), calendar: Calendar = .current) {
        values = [state.sleepHours, state.steps, state.exerciseMinutes, state.restingHeartRate,
                  state.studyMinutes.map(Double.init), state.screenTimeMinutes.map(Double.init), state.previousScore]
        health = state.healthReadings
        window = state.healthWindow
        history = state.predictionHistory
        capturedAt = now
        self.calendar = calendar
        predictionStatus = state.predictionStatus(now: now, calendar: calendar)
        lastPrediction = state.lastPrediction
    }

    init(values: [Double?] = Array(repeating: nil, count: 7), health: HealthReadings = HealthReadings(),
         window: HealthDataWindow? = nil, history: [PredictionSnapshot] = [],
         capturedAt: Date = Date(), calendar: Calendar = .current,
         predictionStatus: PredictionStatus = .ready, lastPrediction: PredictionSnapshot? = nil) {
        self.values = values.count == 7 ? values : Array(repeating: nil, count: 7)
        self.health = health
        self.window = window
        self.history = history
        self.capturedAt = capturedAt
        self.calendar = calendar
        self.predictionStatus = predictionStatus
        self.lastPrediction = lastPrediction
    }

    var missing: [String] {
        TwinTrackFeature.allCases.filter { values[$0.rawValue] == nil }.map(HomeDisplay.featureName)
    }

    var profile: TwinTrackProfile? {
        guard missing.isEmpty else { return nil }
        return TwinTrackProfile(sleepHours: values[0]!, steps: values[1]!, exerciseMinutes: values[2]!,
                                restingHeartRate: values[3]!, studyMinutes: values[4]!,
                                screenTimeMinutes: values[5]!, previousScore: values[6]!)
    }
}

nonisolated struct AssistantField: Codable, Equatable, Sendable {
    let label: String
    let value: String
}

/// All card fields are constructed by Swift, never decoded from model prose.
nonisolated struct AssistantCard: Identifiable, Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable { case current, scenario, history, clarification, unavailable }
    let id: UUID
    let kind: Kind
    let title: String
    let message: String
    var prediction: Double?
    var baseline: Double?
    var delta: Double?
    var fields: [AssistantField]

    init(kind: Kind, title: String, message: String, prediction: Double? = nil,
         baseline: Double? = nil, delta: Double? = nil, fields: [AssistantField] = []) {
        id = UUID()
        self.kind = kind
        self.title = title
        self.message = message
        self.prediction = prediction
        self.baseline = baseline
        self.delta = delta
        self.fields = fields
    }
}

@Generable
nonisolated enum AssistantFeature: String, CaseIterable, Sendable {
    case sleep_hours, steps, exercise_minutes, resting_heart_rate, study_minutes, screen_time_minutes, previous_score
}

@Generable
nonisolated enum AssistantOperation: String, Sendable { case set, increase, decrease }

@Generable
nonisolated enum AssistantUnit: String, Sendable { case hours, minutes, count, bpm, points }

@Generable
nonisolated struct AssistantChange: Sendable {
    var feature: AssistantFeature
    var operation: AssistantOperation
    var unit: AssistantUnit
    @Guide(description: "Explicit nonnegative amount in the user's stated unit. Do not pre-convert.")
    var value: Double
    @Guide(description: "Exact quote from the latest user message that names this feature, amount, unit and operation. Never invent a quote.")
    var evidence: String
}

@Generable
nonisolated struct AssistantScenarioArguments: Sendable {
    @Guide(description: "All explicit changes in this request; ask clarification instead of guessing missing variables or units.", .count(1...7))
    var changes: [AssistantChange]
}

@Generable
nonisolated struct AssistantReadArguments: Sendable {
    @Guide(description: "A short exact quote from the latest user request asking for current TwinTrack data or prediction.")
    var request: String
}

@Generable
nonisolated enum AssistantHistoryScope: String, Sendable { case latest, sevenDays, day }

@Generable
nonisolated struct AssistantHistoryArguments: Sendable {
    var scope: AssistantHistoryScope
    @Guide(description: "For day scope only, the requested date as yyyy-MM-dd in the captured local calendar; otherwise an empty string.")
    var localDate: String
}

@MainActor
final class AssistantToolRun {
    let snapshot: AssistantSnapshot
    let userMessage: String
    private(set) var cards: [AssistantCard] = []
    private(set) var toolNames: [String] = []

    init(snapshot: AssistantSnapshot, userMessage: String) {
        self.snapshot = snapshot
        self.userMessage = userMessage
    }

    func readCurrent() throws -> String {
        try begin("readCurrentTwin")
        var fields = inputFields(snapshot.values)
        fields += sourceFields()
        let fresh = snapshot.predictionStatus == .fresh && snapshot.lastPrediction?.provenance == "explicitRun.v1"
        let status = fresh ? "Current explicit run · Not a guaranteed outcome"
            : (snapshot.lastPrediction == nil ? "No current run. Use Run Prediction on Home." : "Previous result is not current. Review inputs and use Run Prediction Again on Home.")
        if let prior = snapshot.lastPrediction {
            fields.append(AssistantField(label: "Previous run", value: dateText(prior.createdAt, time: true)))
            if !fresh { fields.append(AssistantField(label: "Previous score (historical)", value: HomeDisplay.prediction(prior.prediction))) }
        }
        return try record(AssistantCard(
            kind: .current, title: "Current TwinTrack",
            message: snapshot.missing.isEmpty ? status
                : "Prediction unavailable — missing: \(snapshot.missing.joined(separator: ", ")).",
            prediction: fresh ? snapshot.lastPrediction?.prediction : nil, fields: fields
        ))
    }

    func readSleep() throws -> String {
        try begin("readCurrentSleep")
        // Read the captured committed Health result, never a user report or Ridge.
        let value = snapshot.health.sleep.value.flatMap { $0 > 0 ? $0 : nil }
        let message = value.flatMap { HomeDisplay.sleep($0) }.map { "Recorded sleep: \($0)." }
            ?? "No accessible recent value."
        let fields = sourceFields().filter { ["Captured", "Health source time zone", "Sleep window"].contains($0.label) }
        return try record(AssistantCard(kind: .current, title: "Recorded sleep", message: message, fields: fields))
    }

    func runScenario(_ arguments: AssistantScenarioArguments) throws -> String {
        try begin("runWhatIf")
        do {
            let changes = try validatedChanges(arguments.changes)
            guard snapshot.missing.isEmpty else {
                return try record(AssistantCard(kind: .unavailable, title: "Scenario unavailable",
                    message: "I can't run that scenario yet because these inputs are unavailable: \(snapshot.missing.joined(separator: ", "))."))
            }
            guard snapshot.predictionStatus == .fresh, snapshot.lastPrediction?.provenance == "explicitRun.v1" else {
                return try record(AssistantCard(kind: .unavailable, title: "Run Prediction first",
                    message: "The scenario needs a fresh explicit prediction. Review your inputs and use Run Prediction on Home, then ask again."))
            }
            var scenario = try WhatIfScenario(baseline: snapshot.profile)
            for (feature, change, amount) in changes {
                let baseline = scenario.currentValue(for: feature)
                let target: Double
                switch change.operation {
                case .set: target = amount
                case .increase: target = baseline + amount
                case .decrease: target = baseline - amount
                }
                try scenario.set(target, for: feature)
            }
            let result = scenario.evaluate()
            return try record(AssistantCard(kind: .scenario, title: "Model scenario",
                message: "Predicted change · Not a guaranteed outcome. Your saved inputs are unchanged.",
                prediction: result.scenarioPrediction, baseline: result.baselinePrediction, delta: result.delta,
                fields: inputFields(TwinTrackFeature.allCases.map { WhatIfScenario.value($0, in: result.scenario) }) + sourceFields()))
        } catch let error as WhatIfError {
            return try record(AssistantCard(kind: .clarification, title: "Check the scenario", message: error.errorDescription ?? "Please check the values."))
        } catch is AssistantArgumentError {
            return try record(AssistantCard(kind: .clarification, title: "Please clarify",
                message: "Please name each value, its unit, and whether to set it or change it. For example: set study time to two hours, or add thirty minutes of study."))
        }
    }

    func readHistory(_ arguments: AssistantHistoryArguments) throws -> String {
        try begin("readPredictionHistory")
        let history = snapshot.history.filter(\.isValid).sorted { $0.createdAt < $1.createdAt }
        switch arguments.scope {
        case .latest:
            guard let latest = history.last else { return try emptyHistory() }
            return try record(historyCard(latest))
        case .day:
            let format = DateFormatter()
            format.locale = Locale(identifier: "en_US_POSIX")
            format.calendar = snapshot.calendar
            format.timeZone = snapshot.calendar.timeZone
            format.dateFormat = "yyyy-MM-dd"
            format.isLenient = false
            guard let date = format.date(from: arguments.localDate), format.string(from: date) == arguments.localDate else {
                return try record(AssistantCard(kind: .clarification, title: "Which date?", message: "Please give the date of the history you want to review."))
            }
            guard let latest = history.last(where: { snapshot.calendar.isDate($0.createdAt, inSameDayAs: date) }) else { return try emptyHistory() }
            return try record(historyCard(latest))
        case .sevenDays:
            let points = PredictionHistoryTrend.points(from: history, now: snapshot.capturedAt, calendar: snapshot.calendar)
            let days = PredictionHistoryTrend.days(now: snapshot.capturedAt, calendar: snapshot.calendar)
            let fields = days.map { day in
                AssistantField(label: dateText(day), value: points.first(where: { $0.day == day })
                    .map { HomeDisplay.prediction($0.snapshot.prediction) } ?? "No saved prediction")
            }
            let delta = points.count > 1 ? points.last!.snapshot.prediction - points.first!.snapshot.prediction : nil
            return try record(AssistantCard(kind: .history, title: "7-day prediction history",
                message: delta == nil ? "Insufficient history for a trend." : "Change across available days. Missing days remain empty.",
                delta: delta, fields: fields))
        }
    }

    private func validatedChanges(_ changes: [AssistantChange]) throws -> [(TwinTrackFeature, AssistantChange, Double)] {
        guard (1...7).contains(changes.count), Set(changes.map(\.feature)).count == changes.count else { throw AssistantArgumentError.unclear }
        return try changes.map { change in
            guard let feature = TwinTrackFeature.allCases.first(where: { $0.key == change.feature.rawValue }),
                  evidenceSupports(change) else { throw AssistantArgumentError.unclear }
            guard change.value.isFinite, change.value >= 0 else { throw WhatIfError.invalidValue(feature) }
            let amount: Double
            switch (feature, change.unit) {
            case (.sleepHours, .hours): amount = change.value
            case (.sleepHours, .minutes): amount = change.value / 60
            case (.studyMinutes, .hours), (.screenTimeMinutes, .hours), (.exerciseMinutes, .hours): amount = change.value * 60
            case (.studyMinutes, .minutes), (.screenTimeMinutes, .minutes), (.exerciseMinutes, .minutes): amount = change.value
            case (.steps, .count), (.restingHeartRate, .bpm), (.previousScore, .points): amount = change.value
            default: throw AssistantArgumentError.unclear
            }
            guard amount.isFinite else { throw WhatIfError.invalidValue(feature) }
            return (feature, change, amount)
        }
    }

    private func evidenceSupports(_ change: AssistantChange) -> Bool {
        let evidence = change.evidence.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !evidence.isEmpty, userMessage.lowercased().contains(evidence),
              let parsed = AssistantScenarioParser.change(from: evidence) else { return false }
        return parsed.feature == change.feature && parsed.operation == change.operation
            && parsed.unit == change.unit && parsed.value == change.value
    }

    private func begin(_ name: String) throws {
        try Task.checkCancellation()
        guard toolNames.count < 6 else { throw AssistantFailure.failed }
        toolNames.append(name)
    }

    private func record(_ card: AssistantCard) throws -> String {
        cards.append(card)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(card), as: UTF8.self)
    }

    private func emptyHistory() throws -> String {
        try record(AssistantCard(kind: .history, title: "Prediction history", message: "No saved prediction for this period."))
    }

    private func historyCard(_ snapshot: PredictionSnapshot) -> AssistantCard {
        AssistantCard(kind: .history, title: "Saved model prediction", message: "Recorded \(dateText(snapshot.createdAt, time: true)). These are saved values, not current readings.",
            prediction: snapshot.prediction, fields: inputFields(TwinTrackFeature.allCases.map { WhatIfScenario.value($0, in: snapshot.inputs.profile) }))
    }

    private func inputFields(_ values: [Double?]) -> [AssistantField] {
        TwinTrackFeature.allCases.map { feature in
            let value = values[feature.rawValue]
            let formatted: String?
            switch feature {
            case .sleepHours: formatted = HomeDisplay.sleep(value)
            case .steps: formatted = HomeDisplay.steps(value)
            case .exerciseMinutes: formatted = HomeDisplay.exercise(value)
            case .restingHeartRate: formatted = HomeDisplay.restingHeartRate(value)
            case .studyMinutes, .screenTimeMinutes: formatted = value.map { "\($0.formatted(.number.precision(.fractionLength(0...2)))) min" }
            case .previousScore: formatted = HomeDisplay.previousScore(value)
            }
            return AssistantField(label: HomeDisplay.featureName(feature), value: formatted ?? "Unavailable")
        }
    }

    private func sourceFields() -> [AssistantField] {
        var fields = [AssistantField(label: "Captured", value: dateText(snapshot.capturedAt, time: true)),
                      AssistantField(label: "Manual values", value: "Current saved entries"),
                      AssistantField(label: "Capture time zone", value: snapshot.calendar.timeZone.identifier)]
        if let window = snapshot.window {
            // Travel after a refresh must not relabel the committed Health window.
            fields.append(AssistantField(label: "Health source time zone", value: window.timeZone.identifier))
            fields.append(AssistantField(label: "Steps / Exercise", value: "Previous completed day: \(dateText(window.day.start, zone: window.timeZone))"))
            fields.append(AssistantField(label: "Sleep window", value: "\(dateText(window.sleep.start, time: true, zone: window.timeZone)) – \(dateText(window.sleep.end, time: true, zone: window.timeZone))"))
            fields.append(AssistantField(label: "Resting Heart Rate", value: "Latest valid sample within the preceding 72 hours"))
        }
        if let date = snapshot.health.restingHeartRateSampleDate { fields.append(AssistantField(label: "Resting sample", value: dateText(date, time: true, zone: snapshot.window?.timeZone))) }
        return fields
    }

    private func dateText(_ date: Date, time: Bool = false, zone: TimeZone? = nil) -> String {
        let format = DateFormatter()
        format.calendar = snapshot.calendar
        format.timeZone = zone ?? snapshot.calendar.timeZone
        format.dateStyle = .medium
        format.timeStyle = time ? .short : .none
        return format.string(from: date)
    }
}

private enum AssistantArgumentError: Error { case unclear }

nonisolated struct ReadCurrentTwinTool: Tool {
    let name = "readCurrentTwin"
    let description = "Read the current committed seven inputs, missing inputs, exact source periods and deterministic prediction. Never queries or changes HealthKit."
    let run: AssistantToolRun
    func call(arguments: AssistantReadArguments) async throws -> String { try await run.readCurrent() }
}

nonisolated struct RunWhatIfTool: Tool {
    let name = "runWhatIf"
    let description = "Run all explicit scenario changes together through the existing frozen Ridge engine using this request's immutable baseline. Never saves a scenario. Use exact quoted evidence and original units."
    let run: AssistantToolRun
    func call(arguments: AssistantScenarioArguments) async throws -> String { try await run.runScenario(arguments) }
}

nonisolated struct ReadPredictionHistoryTool: Tool {
    let name = "readPredictionHistory"
    let description = "Read real saved prediction history: latest snapshot, latest snapshot on a requested local date, or seven real local-day slots with honest gaps. Never creates or edits history."
    let run: AssistantToolRun
    func call(arguments: AssistantHistoryArguments) async throws -> String { try await run.readHistory(arguments) }
}
