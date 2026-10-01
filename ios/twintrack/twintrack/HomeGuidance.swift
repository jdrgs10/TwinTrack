import Foundation

enum ManualReviewField: String, CaseIterable, Identifiable, Hashable {
    case study, screen, subject, assessment, previousScore, assessmentDate, previousDate, confirmation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: "Study Time"
        case .screen: "Recreational Screen Time"
        case .subject: "Subject"
        case .assessment: "Assessment Name"
        case .previousScore: "Previous Score"
        case .assessmentDate: "Next Assessment"
        case .previousDate: "Previous Result Date"
        case .confirmation: "Assessment confirmation"
        }
    }

    var isAssessmentContext: Bool {
        switch self {
        case .study, .screen, .previousScore: false
        default: true
        }
    }
}

struct ManualReviewIssue: Equatable {
    let field: ManualReviewField
    let message: String
}

/// Presentation only: existing state decides eligibility and performs every action.
struct HomeGuidance {
    enum Action: Equatable {
        case none, run, refresh, health, manual(ManualReviewField)
    }

    let action: Action
    let stateLine: String
    let healthLabel: String
    let availableHealthCount: Int

    var actionTitle: String? {
        switch action {
        case .none: nil
        case .run: "Run Prediction"
        case .refresh: "Refresh data"
        case .health: "Review Apple Health"
        case let .manual(field): field.isAssessmentContext ? "Complete assessment information" : "Update Manual Inputs"
        }
    }

    @MainActor
    init(state: TwinTrackState, now: Date = Date(), calendar: Calendar = .current) {
        let status = state.predictionStatus(now: now, calendar: calendar)
        let prefix = state.lastPrediction == nil ? "" : "Saved estimate · "
        let readings = state.healthReadings
        let available = [readings.sleep, readings.steps, readings.exercise, readings.restingHeartRate]
            .filter { $0.value != nil }.count
        availableHealthCount = available
        switch state.healthAccess {
        case .notRequested, .failed: healthLabel = "Apple Health · Review access"
        case .requesting: healthLabel = "Apple Health · Requesting access"
        case .unavailable: healthLabel = "Apple Health · Unavailable here"
        case .completed: healthLabel = "Apple Health · \(available)/4 values available"
        }

        if state.healthAccess == .requesting {
            action = .none
            stateLine = prefix + "Requesting Health access"
        } else if status == .refreshing {
            action = .none
            stateLine = prefix + "Refreshing inputs"
        } else if status == .fresh {
            action = .none
            stateLine = prefix + "Inputs match"
        } else if status == .ready || status == .stale {
            action = .run
            stateLine = status == .ready ? "Current inputs ready" : prefix + "Inputs changed"
        } else if let field = Self.manualReviewField(state: state, now: now, calendar: calendar) {
            action = .manual(field)
            stateLine = prefix + (field.isAssessmentContext ? "Assessment context needs review" : "Manual inputs need review")
        } else if state.healthAccess == .completed && (status == .needsRefresh ||
            [readings.sleep, readings.steps, readings.exercise, readings.restingHeartRate].contains(.failed)) {
            action = .refresh
            stateLine = prefix + "Refresh Health inputs"
        } else {
            action = .health
            stateLine = prefix + (available == 4 ? "Review Health inputs" : "Health inputs unavailable")
        }
    }

    @MainActor
    private static func manualReviewField(state: TwinTrackState, now: Date, calendar: Calendar) -> ManualReviewField? {
        if state.studyMinutes == nil { return .study }
        if state.screenTimeMinutes == nil { return .screen }
        if state.previousScore == nil { return .previousScore }
        let context = state.predictionContext
        let issues = ManualInputsValidation.issues(
            studyMinutes: state.studyMinutes, screenTimeMinutes: state.screenTimeMinutes,
            previousScoreText: state.previousScore.map { String($0) } ?? "",
            subject: context?.subject ?? "", assessmentName: context?.assessmentName ?? "",
            assessmentDate: context?.assessmentDate ?? now, previousDate: context?.previousDate ?? now,
            confirmed: context.map { $0.sameSubjectConfirmed && $0.nextIndividualAssessmentConfirmed && $0.latestComparablePriorConfirmed } ?? false,
            now: now, calendar: calendar)
        if let issue = issues.first { return issue.field }
        if context?.issue(now: now, calendar: calendar) != nil { return .study }
        if let value = state.studyMinutes, !WhatIfScenario.isValid(Double(value), for: .studyMinutes) { return .study }
        if let value = state.screenTimeMinutes, !WhatIfScenario.isValid(Double(value), for: .screenTimeMinutes) { return .screen }
        if let value = state.previousScore, !WhatIfScenario.isValid(value, for: .previousScore) { return .previousScore }
        return nil
    }
}
