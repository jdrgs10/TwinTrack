import Foundation

/// Output ceiling, not a requested length. Apple's own context/safety errors remain authoritative.
enum AssistantGenerationBudget {
    static func maximumResponseTokens(for prompt: String) -> Int {
        let latest = prompt.components(separatedBy: "Latest user message:\n").last ?? prompt
        let pattern = #"(?i)\b(?:workout|routine|training|plan|sets|reps|repetitions|step.by.step|detail(?:ed)?|explain fully)\b"#
        // Retain room for a structured answer when the user revises the previous plan.
        let followup = #"(?i)\b(?:easier|harder|instead|replace|swap|adjust|change|without|no equipment)\b"#
        let needsDetail = latest.range(of: pattern, options: .regularExpression) != nil
            || (prompt.range(of: pattern, options: .regularExpression) != nil
                && latest.range(of: followup, options: .regularExpression) != nil)
        return needsDetail ? 1000 : 450
    }
}
