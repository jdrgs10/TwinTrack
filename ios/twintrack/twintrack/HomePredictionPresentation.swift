import Foundation

/// Copy/action projection only. Eligibility and prediction execution remain in TwinTrackState.
struct HomePredictionPresentation {
    let status: PredictionStatus
    let hasSaved: Bool
    let needsManualUpdate: Bool

    var canRun: Bool { status == .ready || status == .stale }

    var stateLine: String {
        let prefix = hasSaved ? "Saved estimate · " : ""
        if status == .fresh { return prefix + "Inputs match" }
        if status == .refreshing { return prefix + "Refreshing inputs" }
        if needsManualUpdate { return prefix + "Confirm manual inputs" }
        switch status {
        case .stale: return prefix + "Inputs changed"
        case .ready: return "Current inputs ready"
        case .needsRefresh: return prefix + "Refresh Health inputs"
        case .missing: return prefix + "Inputs unavailable"
        case .fresh, .refreshing: return prefix
        }
    }
}
