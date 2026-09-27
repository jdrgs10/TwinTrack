import Foundation

/// In-memory categorical diagnostics for synthetic tests. No prompt, records,
/// identifiers, generated text or underlying errors are logged or persisted.
struct AssistantAuditTrace {
    var route = "general"
    var tools: [String] = []
    var validation: String?
    var replacements: [String] = []
    var failure: String?
    var promptBytes = 0
    var instructionBytes = 0
}

extension AssistantRoute {
    var auditName: String {
        switch self {
        case .general: "conversation"
        case .current: "read-saved"
        case .calculate: "calculate"
        case .wellbeing: "wellbeing"
        case .sleepReading: "sleep-reading"
        case .modelInformation: "methodology"
        case .history: "history"
        case .scenario: "scenario"
        case .clarification: "clarification"
        }
    }
}
