import Foundation

nonisolated struct AssistantProvenance: Codable, Equatable, Sendable {
    static let currentBuild = "FMQ-2026-09-15-E"
    nonisolated enum Origin: String, Codable, Sendable {
        case model = "On-device model"
        case sleepReading = "Swift · readCurrentSleep"
        case current = "Swift · readCurrentTwin"
        case scenario = "Swift · runWhatIf"
        case history = "Swift · readPredictionHistory"
        case explanation = "Swift · explanation/clarification"
        case urgent = "Swift · reviewed urgent guidance"
        case review = "App response review"
        case frameworkRefusal = "Apple framework refusal"
    }
    let build: String
    let origin: Origin
    init(_ origin: Origin) { build = Self.currentBuild; self.origin = origin }
}
