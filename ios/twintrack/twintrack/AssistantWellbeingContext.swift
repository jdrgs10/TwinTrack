import Foundation

/// Derived interpretation only. Raw measurements and birth dates never enter chat.
/// Optional on cards so older saved conversations continue to decode.
nonisolated struct AssistantWellbeingSummary: Codable, Equatable, Sendable {
    enum Reference: String, Codable, Sendable { case childTeen, adult, unavailable }
    let reference: Reference
    let healthyCategory: Bool

    func explanation(for request: String) -> String {
        let text = request.lowercased()
        if text.contains("percentile") {
            guard reference == .childTeen else {
                return "Use the current reference in the saved summary below; a BMI-for-age percentile is not available for this result."
            }
            return "The current percentile is shown in the summary below. It compares BMI with the CDC reference for children of the same age and sex; it is not a percentage of health or a target to reach."
        }
        guard text.range(of: #"\b(?:improve|change|healthy|normal|okay|good|mean|explain|why|how|do next)\b"#, options: .regularExpression) != nil else {
            return "Here is your saved wellbeing summary."
        }
        let interpretation: String
        if healthyCategory {
            interpretation = reference == .childTeen
                ? "Your saved result is within the app’s healthy BMI-for-age category."
                : "Your saved result is within the app’s healthy adult BMI category."
        } else {
            interpretation = "Use the category and reference in the current saved summary below."
        }
        return interpretation + " BMI is a screening measure, not a diagnosis or a number to optimize. Focus on regular meals, sleep and enjoyable activity; discuss concerns with a parent, guardian or healthcare professional."
    }
}

enum AssistantWellbeingContext {
    static func continuesSummary(_ messages: [AssistantMessage]) -> Bool {
        guard messages.count >= 3, let request = messages.last, request.role == .user else { return false }
        let previous = messages[messages.count - 2]
        guard previous.role == .assistant,
              previous.provenance?.origin == .wellbeing || previous.cards.contains(where: { $0.kind == .wellbeing }) else { return false }
        // Match a follow-up about this result, not arbitrary new health/safety topics.
        // Values in the old card are never used as the current measurement.
        let text = request.text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if AssistantContext.relation(in: messages) == .elaboration { return true }
        return AssistantRouter.matches(#"^(?:how (?:can|do|could|should) i (?:improve|change|understand|interpret) (?:it|that|this|my bmi)|is (?:it|that|this|my bmi) (?:healthy|okay|ok|good|normal)|what does (?:that|this|it|(?:the |my )?\d+(?:st|nd|rd|th)? percentile|(?:the |my )?percentile) mean|(?:should|do) i need to (?:change|improve) (?:it|that|this)|what (?:can|should) i do (?:about it|about that|next))[.!?\s]*$"#, text)
    }
}
