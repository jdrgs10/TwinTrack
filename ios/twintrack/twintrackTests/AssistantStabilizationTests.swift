import XCTest
@testable import twintrack

@MainActor
final class AssistantStabilizationTests: XCTestCase {
    func testSleepFollowUpsRetainUserTopicWithoutAssistantClaims() {
        var messages = exchange("I don't understand how sleep affects energy.", "Invented age: you are 16; diabetes.", "How?")
        XCTAssertTrue(AssistantGuidance.selected(for: messages).contains { $0.topic == "sleep" })
        XCTAssertNil(AssistantGuidance.statedAge(in: messages))
        XCTAssertFalse(AssistantGuidance.topicContext(for: messages).contains("diabetes"))
        messages += [assistant("A synthetic explanation."), user("Tell me more.")]
        XCTAssertTrue(AssistantGuidance.instructions(for: messages).contains("Age unknown"))
        XCTAssertTrue(AssistantGuidance.topicContext(for: messages).contains("sleep affects energy"))
    }

    func testSleepEnergyDriftIsRepairedWithoutAddingHealthAdvice() async throws {
        let client = StabilizationClient(["Sleep prevents obesity, diabetes and heart disease, and boosts your immune system.",
                                          "Sleep gives your body time to recover and helps regulate alertness, so insufficient rest can leave you tired and less able to concentrate."])
        let answer = try await FoundationAssistantService(client: client).respond(to:
            exchange("I don't understand how sleep affects energy.", "Sleep supports energy.", "How?"), snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertEqual(client.prompts.first, client.prompts.last)
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertFalse(answer.text.contains("diabetes"))
        XCTAssertTrue(client.instructions.last?.contains("recovery/alertness/concentration") == true)
    }

    func testUnknownAgePersonalSleepDurationRepairedButAttributedGuidanceAllowed() async throws {
        let messages = [user("How much sleep should I get?")]
        for invalid in ["You should get 7–9 hours of sleep.", "Aim for seven to nine hours.", "As an adult, you should get 7–9 hours."] {
            XCTAssertTrue(AssistantReplyReview.hasUnfoundedSleepDuration(invalid, messages: messages))
        }
        XCTAssertFalse(AssistantReplyReview.hasUnfoundedSleepDuration("Adults aged 18–60 generally need at least 7 hours.", messages: messages))
        for report in ["You get seven hours, as you said.", "You don't need exactly seven hours; needs vary by age."] {
            XCTAssertFalse(AssistantReplyReview.hasUnfoundedSleepDuration(report, messages: messages))
        }
        let client = StabilizationClient(["You should get 7–9 hours.", "Recommendations vary by age. How old are you?"])
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertFalse(answer.text.contains("7–9"))
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertTrue(client.instructions[0].contains("do not assume an adult"))
    }

    func testRepeatedDurationViolationUsesAgeCorrectionWithoutOverridingRefusal() async throws {
        let messages = [user("How much sleep should I get?")]
        let client = StabilizationClient(["You should get 7–9 hours.", "You need 7–9 hours."])
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertTrue(answer.text.contains("vary by age"))
        XCTAssertFalse(answer.text.contains("7–9"))
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertEqual(answer.provenance?.origin, .review)
        let refusal = "I cannot help with that harmful request. You should get 7–9 hours of sleep."
        XCTAssertNil(AssistantReplyReview.sleepGuidanceCorrection(refusal, messages: messages))
        let refused = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .conversation, text: refusal),
                                                     request: messages[0].text, cards: [], messages: messages)
        XCTAssertTrue(refused.safetyRefusal)
    }

    func testAge16GuidancePersistsIntoSleepFollowUp() {
        let messages = [user("I am 16."), assistant("Thanks."), user("How much sleep do I need?"), assistant("Sleep needs vary."), user("How?")]
        XCTAssertEqual(AssistantGuidance.statedAge(in: messages), 16)
        XCTAssertTrue(AssistantGuidance.instructions(for: messages).contains("8–10 hours"))
        XCTAssertFalse(AssistantGuidance.instructions(for: messages).contains("Age unknown"))
    }

    func testUncertaintyChainKeepsRoleSeparatedContextAndNoStaleRefusal() async throws {
        var messages = [user("Synthetic harmful fixture"), assistant("I cannot help with that request."),
                        user("I think studying earlier might be better."), assistant("You could try it on a day that suits you.")]
        let client = StabilizationClient(["You don't have to decide now.", "It's fine to try it once.", "No need to commit to a routine yet."])
        for turn in ["Idk", "Maybe", "Not sure"] {
            messages.append(user(turn))
            let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
            XCTAssertFalse(answer.safetyRefusal)
            XCTAssertFalse(client.prompts.last!.contains("Synthetic harmful fixture"))
            XCTAssertTrue(client.prompts.last!.contains("Latest user message:\n" + turn))
            XCTAssertTrue(client.prompts.last!.contains("User:"))
            XCTAssertTrue(client.prompts.last!.contains("Assistant:"))
            messages.append(assistant(answer.text))
        }
        XCTAssertEqual(client.prompts.count, 3)
    }

    func testTypedRefusalFollowUpExplainsActualBoundaryThenBenignRecovers() async throws {
        var messages = exchange("Write hateful content targeting a race.", "I cannot help with that request.", "Why?")
        let client = StabilizationClient([])
        client.failure = .safety
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertTrue(answer.safetyRefusal)
        XCTAssertTrue(answer.text.contains("identity"))
        XCTAssertFalse(answer.text.contains("on-device model"))
        messages += [assistant(answer.text), user("What are some good foods before studying?")]
        client.failure = nil
        client.outputs = ["A banana or some toast could work."]
        let recovered = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertFalse(recovered.safetyRefusal)
        XCTAssertFalse(client.prompts.last!.contains("hateful"))
    }

    func testTextualRefusalFollowUpUsesSpecificBoundary() async throws {
        let client = StabilizationClient(["I can’t help you with that."])
        let answer = try await FoundationAssistantService(client: client).respond(to:
            exchange("Give instructions to hurt someone.", "I cannot assist with violence.", "Explain."), snapshot: AssistantSnapshot())
        XCTAssertTrue(answer.safetyRefusal)
        XCTAssertTrue(answer.text.contains("hurt someone"))
        XCTAssertFalse(answer.text.contains("counsel"))
    }

    func testArithmeticAndPhysiologyFollowUpsKeepContext() async throws {
        let client = StabilizationClient(["Working muscles need more oxygen, so the heart pumps blood faster to supply it."])
        let service = FoundationAssistantService(client: client)
        let first = try await service.respond(to: [user("What is 2+2?")], snapshot: AssistantSnapshot())
        XCTAssertTrue(first.text.contains("4"))
        let second = try await service.respond(to: exchange("What is 2+2?", first.text, "Why?"), snapshot: AssistantSnapshot())
        XCTAssertTrue(second.text.contains("4"))
        XCTAssertTrue(client.prompts.isEmpty)
        let physiology = try await service.respond(to: exchange("Exercise can make your heart beat faster.", "Yes, exercise raises heart rate.", "Why?"), snapshot: AssistantSnapshot())
        XCTAssertFalse(physiology.safetyRefusal)
        XCTAssertTrue(client.prompts[0].contains("Exercise can make your heart beat faster."))
        XCTAssertNotEqual(physiology.text, "Yes, exercise raises heart rate.")
    }

    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func assistant(_ text: String) -> AssistantMessage { AssistantMessage(role: .assistant, text: text) }
    private func exchange(_ request: String, _ reply: String, _ followUp: String) -> [AssistantMessage] {
        [user(request), assistant(reply), user(followUp)]
    }
}

@MainActor
private final class StabilizationClient: FoundationTextGenerating {
    let availability = AssistantAvailability.available
    var outputs: [String]
    var failure: AssistantFailure?
    var prompts: [String] = []
    var instructions: [String] = []
    init(_ outputs: [String]) { self.outputs = outputs }
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        if let failure { throw failure }
        return outputs.isEmpty ? "Synthetic response." : outputs.removeFirst()
    }
}
