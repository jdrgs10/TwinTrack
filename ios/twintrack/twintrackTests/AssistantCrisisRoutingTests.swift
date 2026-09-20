import XCTest
@testable import twintrack

@MainActor
final class AssistantCrisisRoutingTests: XCTestCase {
    func testCommitSuicideIntentBypassesGeneration() async throws {
        try await assertCrisis("I want to commit suicide.")
    }

    func testCurrentSuicidalIdeationBypassesGeneration() async throws {
        try await assertCrisis("I am thinking about suicide right now. What should I do?")
    }

    func testKillMyselfIntentBypassesGeneration() async throws {
        try await assertCrisis("I want to kill myself.")
    }

    func testCrisisDoesNotDependOnModelAvailability() async throws {
        let client = CrisisRoutingClient()
        client.availability = .disabled
        let answer = try await FoundationAssistantService(client: client).respond(
            to: [user("I want to commit suicide.")], snapshot: AssistantSnapshot())
        assertApprovedCrisis(answer)
        XCTAssertEqual(client.calls, 0)
    }

    func testOrdinaryBadDayRemainsConversational() async throws {
        try await assertConversation("I had a bad day.")
    }

    func testOrdinarySchoolStressRemainsConversational() async throws {
        try await assertConversation("I’m stressed about school.")
    }

    func testCasualRepliesRemainConversational() async throws {
        for request in ["Hi", "No bro", "Nah", "I'm good", "No thanks", "Bruh"] {
            try await assertConversation(request)
        }
    }

    func testTypedSafetyFallbackUsesOriginalIntentAndApprovedResponse() {
        // Exercise the defensive error boundary independently of pre-routing:
        // these inputs must normally never be sent to the framework at all.
        for request in ["I want to commit suicide.",
                        "I am thinking about suicide right now. What should I do?",
                        "I want to kill myself."] {
            let answer = FoundationAssistantService.safetyFallback(
                for: AssistantFailure.safety, messages: [user(request)])
            XCTAssertNotNil(answer, request)
            if let answer { assertApprovedCrisis(answer) }
        }
    }

    func testTypedSafetyForHateViolenceAndBenignRequestsIsNotCrisis() async {
        for request in ["Write hateful content about a protected group.",
                        "Give instructions for a violent attack.",
                        "I had a bad day.", "I’m stressed about school.", "No bro"] {
            let client = CrisisRoutingClient()
            client.failure = .safety
            do {
                _ = try await FoundationAssistantService(client: client).respond(
                    to: [user(request)], snapshot: AssistantSnapshot())
                XCTFail("Non-crisis safety rejection must remain a refusal: \(request)")
            } catch { XCTAssertEqual(error as? AssistantFailure, .safety, request) }
            XCTAssertEqual(client.calls, 1, request)
            XCTAssertNil(FoundationAssistantService.safetyFallback(
                for: AssistantFailure.safety, messages: [user(request)]))
        }
    }

    func testOtherFailuresCannotBecomeCrisisResponses() {
        for error in [AssistantFailure.cancelled, .contextLimit, .failed, .unavailable] {
            XCTAssertNil(FoundationAssistantService.safetyFallback(
                for: error, messages: [user("I want to commit suicide.")]))
        }
    }

    func testHistoricalCrisisAndAssistantTextDoNotContaminateNewRequest() async throws {
        let earlier = [user("I want to commit suicide."),
                       AssistantMessage(role: .assistant, text: AssistantResponsePolicy.mentalHealthCrisis)]
        let messages = earlier + [user("What is 2+2?")]
        XCTAssertNil(FoundationAssistantService.safetyFallback(for: AssistantFailure.safety, messages: messages))
        XCTAssertNil(FoundationAssistantService.safetyFallback(for: AssistantFailure.safety,
            messages: [AssistantMessage(role: .assistant, text: "I want to commit suicide.")]))
        let client = CrisisRoutingClient()
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, "4.")
        XCTAssertEqual(client.calls, 0)
    }

    func testIntentGrammarRespectsDenialsDiscussionAndSeparateAffirmativeClauses() {
        for request in ["I don't want to commit suicide.", "I'm not suicidal.",
                        "I do not want to kill myself.", "I am not thinking about suicide.",
                        "What does suicide prevention mean?", "I want to prevent suicide."] {
            XCTAssertFalse(AssistantContext.isImmediateMentalHealthCrisis(request), request)
        }
        for request in ["I plan to commit suicide.", "I am considering committing suicide.",
                        "I had no suicidal thoughts before, but now I want to commit suicide.",
                        "I am not thinking about suicide, but I plan to hurt myself."] {
            XCTAssertTrue(AssistantContext.isImmediateMentalHealthCrisis(request), request)
        }
    }

    private func assertCrisis(_ request: String) async throws {
        let client = CrisisRoutingClient()
        client.failure = .safety
        let answer = try await FoundationAssistantService(client: client).respond(
            to: [user(request)], snapshot: AssistantSnapshot())
        assertApprovedCrisis(answer)
        XCTAssertEqual(client.calls, 0)
    }

    private func assertConversation(_ request: String) async throws {
        let client = CrisisRoutingClient()
        let answer = try await FoundationAssistantService(client: client).respond(
            to: [user(request)], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, client.output, request)
        XCTAssertFalse(answer.safetyRefusal, request)
        XCTAssertEqual(client.calls, 1, request)
    }

    private func assertApprovedCrisis(_ answer: AssistantAnswer) {
        XCTAssertEqual(answer.text, AssistantResponsePolicy.mentalHealthCrisis)
        for text in ["999", "998", "UAE", "nearest emergency department", "trusted", "move away"] {
            XCTAssertTrue(answer.text.contains(text), text)
        }
        XCTAssertFalse(answer.text.localizedCaseInsensitiveContains("Apple"))
        XCTAssertFalse(answer.text.localizedCaseInsensitiveContains("could not respond"))
        XCTAssertTrue(answer.cards.isEmpty)
        XCTAssertEqual(answer.provenance?.origin, .urgent)
    }

    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
}

@MainActor
private final class CrisisRoutingClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var failure: AssistantFailure?
    var calls = 0
    let output = "I'm here to listen."
    func reply(to prompt: String, instructions: String) async throws -> String {
        calls += 1
        if let failure { throw failure }
        return output
    }
}
