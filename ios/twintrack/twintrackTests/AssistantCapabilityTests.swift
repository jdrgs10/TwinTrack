import XCTest
@testable import twintrack

/// Checks real service boundaries using synthetic generation; not a live-model quality verdict.
@MainActor
final class AssistantCapabilityTests: XCTestCase {
    private func user(_ text: String) -> AssistantMessage { .init(role: .user, text: text) }
    func testOneWordGreetingGetsNaturalOpeningWithoutChangingGoodReplies() async throws {
        let client = CapabilityClient()
        for short in ["Hello.", "Hi", "Hey!"] {
            client.output = short
            let result = try await FoundationAssistantService(client: client).respond(to: [user("Hi")], snapshot: AssistantSnapshot())
            XCTAssertTrue(result.text.contains("How’s your day going?"))
            XCTAssertEqual(result.provenance?.origin, .review)
            XCTAssertTrue(result.cards.isEmpty)
        }
        client.output = "Hey! How's your day going?"
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("Hi")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertEqual(answer.provenance?.origin, .model)
    }
    func testWorkoutRequestsStayConversationalAndKeepPracticalNumbers() async throws {
        let client = CapabilityClient()
        client.output = "Beginner, no equipment: warm up for 3 minutes. Do 2 rounds: 8 chair squats, 6 wall push-ups and 20 seconds marching; rest 45 seconds between exercises. Finish with 2 minutes of easy mobility. Use a comfortable pace and stop if an exercise hurts."
        for request in ["Make me a 20-minute beginner home workout.", "Create a three-day weekly strength-training plan.", "Give me a bodyweight workout without equipment.", "How can I improve my cardio?", "Make me a workout routine with sets, reps and rest times."] {
            guard case .general = AssistantRouter.route(request) else { XCTFail(request); continue }
            let answer = try await FoundationAssistantService(client: client).respond(to: [user(request)], snapshot: AssistantSnapshot())
            XCTAssertEqual(answer.text, client.output)
            XCTAssertFalse(answer.safetyRefusal)
            XCTAssertTrue(answer.cards.isEmpty)
        }
        XCTAssertTrue(client.instructions.allSatisfy { $0.contains("Ordinary general fitness plans are allowed") })
    }
    func testWorkoutFollowupKeepsExerciseAndUserLimitations() async throws {
        let client = CapabilityClient(); client.output = "Replace the floor push-ups with wall push-ups; keep the same rounds and rests."
        let messages = [user("Make a beginner workout. I have no equipment."),
                        AssistantMessage(role: .assistant, text: "Warm up. Do two rounds of chair squats, floor push-ups and marching, with rest between exercises."),
                        user("Make it easier and replace the push-ups.")]
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertTrue(client.prompts[0].contains("no equipment"))
        XCTAssertTrue(client.prompts[0].contains("floor push-ups"))
    }
    func testBudgetExpandsForPlansAndPlanAdjustmentsOnly() {
        XCTAssertEqual(AssistantGenerationBudget.maximumResponseTokens(for: "Hi"), 450)
        XCTAssertEqual(AssistantGenerationBudget.maximumResponseTokens(for: "Make a 20-minute workout"), 1000)
        XCTAssertEqual(AssistantGenerationBudget.maximumResponseTokens(for: "Create a three-day strength training routine"), 1000)
        XCTAssertEqual(AssistantGenerationBudget.maximumResponseTokens(for: "Earlier workout\nLatest user message:\nMake it easier"), 1000)
        XCTAssertEqual(AssistantGenerationBudget.maximumResponseTokens(for: "Earlier workout\nLatest user message:\nHi"), 450)
    }
    func testImmediatePlanDetailsSurviveContextBudget() {
        let plan = String(repeating: "Warm-up and gentle movement. ", count: 28) + "ROUND TWO: wall push-ups, chair squats and marching. Rest 45 seconds."
        let prompt = AssistantContext.prompt(for: [user("A beginner workout without equipment"), .init(role: .assistant, text: plan), user("Can I replace the squats?")])
        XCTAssertTrue(prompt.contains("ROUND TWO"))
        XCTAssertTrue(prompt.contains("without equipment"))
        XCTAssertLessThan(prompt.utf8.count, 3000)
    }
    func testTypedAppleSafetyRefusalIsNeverRetriedForWorkout() async {
        let client = CapabilityClient(); client.failure = .safety
        do {
            _ = try await FoundationAssistantService(client: client).respond(to: [user("Make a beginner workout")], snapshot: AssistantSnapshot())
            XCTFail("Expected typed safety failure")
        } catch { XCTAssertEqual(error as? AssistantFailure, .safety) }
        XCTAssertEqual(client.prompts.count, 1)
    }
    func testInventedPersonalNumbersStillCannotBecomeWorkoutGrounding() async throws {
        let client = CapabilityClient(); client.output = "Your resting heart rate is 60 bpm, so do 3 rounds."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("Make a workout")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, AssistantResponsePolicy.toolRequired)
        XCTAssertTrue(answer.cards.isEmpty)
    }
}

@MainActor
private final class CapabilityClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var output = "Hello."
    var failure: AssistantFailure?
    var prompts: [String] = []
    var instructions: [String] = []
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        if let failure { throw failure }
        return output
    }
}
