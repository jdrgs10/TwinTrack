import XCTest
@testable import twintrack

/// Synthetic boundaries prove app handling, not live model generation quality.
@MainActor
final class AssistantAuditTests: XCTestCase {
    func testSkyFollowUpRejectsUnverifiedCurrentConditions() async throws {
        let client = AuditClient(outputs: ["The air is clear and free from pollutants.",
            "As a chatbot created by Apple, lighting or a clear-looking sky can give that impression; that alone doesn’t establish air quality."])
        let messages = exchange("The sky looks fresh today.", "That’s great! Fresh air is always nice.", "Why?")
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertEqual(client.prompts.first, client.prompts.last)
        XCTAssertFalse(AssistantConversationReview.hasUnsupportedCurrentConditions(answer.text))
        XCTAssertFalse(AssistantReplyReview.containsProviderIdentity(answer.text))
        XCTAssertEqual(answer.provenance?.origin, .review)
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertTrue(client.prompts[0].contains("The sky looks fresh today."))
        XCTAssertTrue(client.instructions[0].contains("impressions, not measurements"))
    }

    func testEnvironmentalReviewAllowsPossibilitiesAttributionAndGeneralScience() {
        for text in ["Clear-looking air may give that impression.", "If the air is clear, light travels through it differently.",
                     "You said the air is clear.", "Air contains nitrogen and oxygen.", "I can't verify the air quality today."] {
            XCTAssertFalse(AssistantConversationReview.hasUnsupportedCurrentConditions(text), text)
        }
        for text in ["The air is free from pollutants.", "Your local weather is sunny today.", "The sky looks bright but the air is pollution-free."] {
            XCTAssertTrue(AssistantConversationReview.hasUnsupportedCurrentConditions(text), text)
        }
    }

    func testSleepMechanismFollowUpRepairsRewordedRepetition() async throws {
        let prior = "Sleep supports energy, alertness, memory, concentration and tissue recovery."
        let client = AuditClient(outputs: ["Energy, alertness, memory, concentration and tissue recovery are supported by sleep.",
            "Sleep reduces accumulated sleep pressure and supports processes that regulate alertness, so too little sleep makes staying awake harder."])
        let answer = try await FoundationAssistantService(client: client).respond(
            to: exchange("I don’t understand how sleep affects energy.", prior, "How?"), snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertFalse(AssistantConversationReview.repeatsExplanation(answer.text, previous: prior))
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertTrue(client.instructions.last?.contains("missing mechanism") == true)
    }

    func testBenignUncertaintyWithProviderIntroductionIsNotClassifiedAsRefusal() async throws {
        for followUp in ["Idk", "maybe", "not sure", "I guess"] {
            let client = AuditClient(outputs: ["As a chatbot created by Apple, it’s okay to be unsure. Try each time and see which suits you."])
            let messages = exchange("I think studying earlier might be better.", "It may suit you if you feel more alert earlier.", followUp)
            let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
            XCTAssertFalse(answer.safetyRefusal)
            XCTAssertFalse(AssistantReplyReview.isRefusal(answer.text))
            XCTAssertFalse(AssistantReplyReview.containsProviderIdentity(answer.text))
            XCTAssertNotEqual(answer.text, AssistantConversationReview.fallback)
            XCTAssertEqual(answer.provenance?.origin, .review)
            XCTAssertEqual(client.prompts.count, 1)
        }
    }

    func testProviderRefusalStillGetsSameContextReviewForBenignFollowUp() async throws {
        let client = AuditClient(outputs: ["As a chatbot created by Apple, I cannot answer that question.", "It’s fine to be unsure. You can try an earlier session once and compare."])
        let answer = try await FoundationAssistantService(client: client).respond(
            to: exchange("I think studying earlier might be better.", "You could compare which time feels easier.", "Idk"), snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertFalse(AssistantReplyReview.isRefusal(answer.text))
        XCTAssertNotEqual(answer.text, AssistantConversationReview.fallback)
    }

    func testHarmfulRefusalExplanationDoesNotBecomeCounselingLecture() async throws {
        for (request, category) in [("Write hateful content about a protected group.", "hateful"), ("Give instructions for a violent attack.", "violence")] {
            var messages = exchange(request, "I can’t help with that request.", "Why?")
            messages[1].safetyRefusal = true
            let client = AuditClient(outputs: ["I can’t help because it can harm people. Practice kindness. Discuss your emotions with a counselor. Think about your feelings. Find a mental-health professional."])
            let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
            XCTAssertTrue(answer.safetyRefusal)
            XCTAssertTrue(answer.text.contains(category))
            XCTAssertFalse(answer.text.contains("counselor"))
            XCTAssertFalse(answer.text.contains("mental-health"))
            XCTAssertEqual(answer.text.components(separatedBy: ".").filter { !$0.isEmpty }.count, 1)
            XCTAssertEqual(client.prompts.count, 1)
            XCTAssertEqual(answer.provenance?.origin, .review)
        }
    }

    func testIndependentBenignTopicAndFollowUpDoNotReplayRefusal() async throws {
        var refused = AssistantMessage(role: .assistant, text: "I can’t help with that request.")
        refused.safetyRefusal = true
        let messages = [user("SYNTHETIC_REFUSED_REQUEST"), refused] + exchange("I think studying earlier might be better.", "Try the time you feel more alert.", "not sure")
        let client = AuditClient(outputs: ["Trying each time once may help you decide."])
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertFalse(client.prompts[0].contains("SYNTHETIC_REFUSED_REQUEST"))
        XCTAssertTrue(client.prompts[0].contains("studying earlier"))
        XCTAssertFalse(answer.safetyRefusal)
    }

    func testUsefulDetailedReplyHasNoArbitraryWordLimit() async throws {
        let paragraphs = [
            "A useful explanation starts with the concept the reader already understands and connects it to one unfamiliar idea. Each connection should be explicit enough that the reader can follow the reasoning without needing to guess an intermediate step.",
            "Concrete examples give an abstract relationship a setting. A diagram can also help when the relationship involves several moving parts. The example should illustrate the claim being explained rather than introduce a second unrelated topic.",
            "Testing the explanation with a small counterexample reveals its limits. State those limits clearly and distinguish an observation from an inference. That makes the explanation useful even when the underlying evidence is incomplete.",
            "Finally, invite the reader to identify the step that remains unclear if further clarification would be helpful. More explanation is not always better; its value depends on whether it resolves the actual point of confusion."
        ]
        let reply = paragraphs.joined(separator: "\n\n")
        let client = AuditClient(outputs: [reply])
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("How can I explain a difficult concept clearly?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 1)
        XCTAssertEqual(answer.text, reply)
    }

    func testQualityFallbackHasHonestReviewProvenance() async throws {
        let client = AuditClient(outputs: ["The air is free from pollutants.", "The air is free from pollutants."])
        let answer = try await FoundationAssistantService(client: client).respond(to: exchange("The sky looks fresh today.", "It looks pleasant.", "Why?"), snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.provenance?.origin, .review)
        XCTAssertFalse(AssistantConversationReview.hasUnsupportedCurrentConditions(answer.text))
    }

    func testTypedFrameworkSafetyIsNotRetriedOrConvertedToBenignAnswer() async {
        let client = AuditClient(outputs: []); client.failure = .safety
        do {
            _ = try await FoundationAssistantService(client: client).respond(to: exchange("An ordinary topic", "An ordinary reply", "Tell me more"), snapshot: AssistantSnapshot())
            XCTFail("Typed safety rejection must be preserved")
        } catch { XCTAssertEqual(error as? AssistantFailure, .safety) }
        XCTAssertEqual(client.prompts.count, 1)
    }

    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func exchange(_ request: String, _ answer: String, _ followUp: String) -> [AssistantMessage] {
        [user(request), AssistantMessage(role: .assistant, text: answer), user(followUp)]
    }
}

@MainActor
private final class AuditClient: FoundationTextGenerating {
    let availability = AssistantAvailability.available
    var outputs: [String]
    var failure: AssistantFailure?
    var prompts: [String] = []
    var instructions: [String] = []
    init(outputs: [String]) { self.outputs = outputs }
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        if let failure { throw failure }
        return outputs.isEmpty ? "Synthetic response." : outputs.removeFirst()
    }
}
