import XCTest
import FoundationModels
@testable import twintrack

@MainActor
final class AssistantReliabilityTests: XCTestCase {
    func testOrdinaryConversationUsesPlainTextWithoutAnyInputsOrCards() async throws {
        let client = TextClientStub()
        let service = FoundationAssistantService(client: client)
        let prompts = ["Hello", "How are you?", "What foods are good before studying?", "How can I focus better?",
            "What are some good sleep habits?", "I drink an energy drink at 7 PM and sleep at 10 PM. Is that a good idea?",
            "I slept seven hours last night", "I slept 7 hours last night", "Why do people recommend 8 hours of sleep?",
            "I drink coffee at 7 PM.", "Should I sleep more?", "What foods help me study?"]
        for prompt in prompts {
            guard case .general = AssistantRouter.route(prompt) else { return XCTFail(prompt) }
            let answer = try await service.respond(to: [user(prompt)], snapshot: AssistantSnapshot())
            XCTAssertEqual(answer.text, client.text)
            XCTAssertTrue(answer.cards.isEmpty)
        }
        XCTAssertEqual(client.prompts, prompts)
        XCTAssertTrue(client.instructions.allSatisfy { $0.hasPrefix(FoundationAssistantService.conversationInstructions) })
    }

    func testNaturalChangesSelectExactFeatureOperationAmountAndUnit() throws {
        let examples: [(String, AssistantFeature, AssistantOperation, Double, AssistantUnit)] = [
            ("What if I sleep 8 hours?", .sleep_hours, .set, 8, .hours),
            ("What if sleep for 6 more hours", .sleep_hours, .increase, 6, .hours),
            ("What if I sleep for six more hours?", .sleep_hours, .increase, 6, .hours),
            ("Study another hour.", .study_minutes, .increase, 1, .hours),
            ("Reduce screen time by 30 minutes.", .screen_time_minutes, .decrease, 30, .minutes),
            ("Add 2,000 steps.", .steps, .increase, 2000, .count),
            ("Set previous score to 90.", .previous_score, .set, 90, .points),
            ("Set sleep to 7.5 hrs", .sleep_hours, .set, 7.5, .hours),
            ("Increase study by thirty mins", .study_minutes, .increase, 30, .minutes),
            ("Set sleep to 7 hours 30 minutes", .sleep_hours, .set, 450, .minutes),
            ("Set RHR to 65 bpm", .resting_heart_rate, .set, 65, .bpm),
            ("Set exercise to 20 min", .exercise_minutes, .set, 20, .minutes),
            ("Run a scenario with sleep 8 hours", .sleep_hours, .set, 8, .hours),
            ("Set study time to an hour and 30 minutes", .study_minutes, .set, 90, .minutes)
        ]
        for (prompt, feature, operation, amount, unit) in examples {
            guard case .scenario(let changes) = AssistantRouter.route(prompt) else { XCTFail(prompt); continue }
            let change = try XCTUnwrap(changes.first)
            XCTAssertEqual(changes.count, 1, prompt)
            XCTAssertEqual(change.feature, feature, prompt)
            XCTAssertEqual(change.operation, operation, prompt)
            XCTAssertEqual(change.value, amount, prompt)
            XCTAssertEqual(change.unit, unit, prompt)
        }
    }

    func testNaturalScenariosUseExistingEngineAndNeverAskModelForNumbers() async throws {
        let client = TextClientStub()
        let service = FoundationAssistantService(client: client)
        let examples: [(String, TwinTrackFeature, Double)] = [
            ("What if I sleep for 6 more hours?", .sleepHours, 13),
            ("Study another hour", .studyMinutes, 180),
            ("Reduce screen time by 30 minutes", .screenTimeMinutes, 210),
            ("Add 2,000 steps", .steps, 7000),
            ("Set previous score to 90", .previousScore, 90),
            ("What if I sleep 8 hours", .sleepHours, 8)
        ]
        let snapshot = complete()
        for (prompt, feature, value) in examples {
            let answer = try await service.respond(to: [user(prompt)], snapshot: snapshot)
            var expected = try WhatIfScenario(baseline: snapshot.profile)
            try expected.set(value, for: feature)
            XCTAssertEqual(answer.cards.first?.kind, .scenario, prompt)
            XCTAssertEqual(answer.cards.first?.prediction, expected.evaluate().scenarioPrediction, prompt)
        }
        XCTAssertTrue(client.prompts.isEmpty)
        XCTAssertEqual(snapshot.values[0], 7)
        XCTAssertTrue(snapshot.history.isEmpty)
    }

    func testMultiFeatureChangesUseOneCombinedScenario() async throws {
        let snapshot = complete()
        let service = FoundationAssistantService(client: TextClientStub())
        let answer = try await service.respond(to: [user("What if I sleep 8 hours and reduce screen time by 30 minutes?")], snapshot: snapshot)
        var expected = try WhatIfScenario(baseline: snapshot.profile)
        try expected.set(8, for: .sleepHours)
        try expected.set(210, for: .screenTimeMinutes)
        XCTAssertEqual(answer.cards.count, 1)
        XCTAssertEqual(answer.cards.first?.delta, expected.evaluate().delta)
    }

    func testUnderstoodOutOfRangeReportsRangeInsteadOfAmbiguity() async throws {
        let service = FoundationAssistantService(client: TextClientStub())
        for prompt in ["Set previous score to 101", "Decrease screen time by 300 minutes", "Set steps to -1"] {
            let answer = try await service.respond(to: [user(prompt)], snapshot: complete())
            XCTAssertEqual(answer.cards.first?.title, "Check the scenario", prompt)
            XCTAssertTrue(answer.cards.first?.message.contains("valid") == true, prompt)
            XCTAssertNil(answer.cards.first?.prediction)
        }
    }

    func testAmbiguousAndConflictingChangesAskForSpecificClarification() async throws {
        let service = FoundationAssistantService(client: TextClientStub())
        for prompt in ["Make it two", "Set sleep to 8", "Set sleep to 8 bpm", "Set sleep to 8 hours or 9 hours", "Set sleep to 8 hours and sleep to 9 hours"] {
            guard case .clarification = AssistantRouter.route(prompt) else { XCTFail(prompt); continue }
            let answer = try await service.respond(to: [user(prompt)], snapshot: complete())
            XCTAssertTrue(answer.cards.isEmpty)
            XCTAssertTrue(answer.text.contains("unit"), prompt)
        }
    }

    func testUnsupportedExtraQuantitiesCannotBeSilentlyDiscarded() {
        for prompt in ["Set sleep to six point five hours", "Set sleep to 8 hours plus 2", "Set sleep to 8 hours for 3 days"] {
            guard case .clarification = AssistantRouter.route(prompt) else { XCTFail(prompt); continue }
        }
    }

    func testCurrentPredictionKeepsAllFourExplicitStates() async throws {
        let client = TextClientStub()
        let service = FoundationAssistantService(client: client)
        let fresh = complete()
        let snapshots = [AssistantSnapshot(), AssistantSnapshot(values: fresh.values), fresh,
            AssistantSnapshot(values: fresh.values, predictionStatus: .stale, lastPrediction: fresh.lastPrediction)]
        for (index, snapshot) in snapshots.enumerated() {
            let answer = try await service.respond(to: [user("What is my predicted score?")], snapshot: snapshot)
            let card = try XCTUnwrap(answer.cards.first)
            if index == 2 { XCTAssertEqual(card.prediction, fresh.lastPrediction?.prediction) }
            else { XCTAssertNil(card.prediction) }
            if index == 0 { XCTAssertTrue(card.message.contains("missing")) }
            if index == 1 { XCTAssertTrue(card.message.contains("Run Prediction")) }
            if index == 3 { XCTAssertTrue(card.message.contains("not current")) }
        }
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testScenarioNeverCreatesMissingOrStaleExplicitBaseline() async throws {
        let service = FoundationAssistantService(client: TextClientStub())
        let fresh = complete()
        for status: PredictionStatus in [.ready, .stale] {
            let snapshot = AssistantSnapshot(values: fresh.values, predictionStatus: status)
            let answer = try await service.respond(to: [user("Study another hour")], snapshot: snapshot)
            XCTAssertEqual(answer.cards.first?.title, "Run Prediction first")
            XCTAssertNil(answer.cards.first?.prediction)
            XCTAssertTrue(snapshot.history.isEmpty)
        }
    }

    func testHistoryAndModelDisclosureNeverNeedGeneration() async throws {
        let client = TextClientStub()
        let service = FoundationAssistantService(client: client)
        let history = try await service.respond(to: [user("Show my prediction history.")], snapshot: AssistantSnapshot())
        XCTAssertEqual(history.cards.first?.kind, .history)
        let disclosure = try await service.respond(to: [user("How reliable is the prediction?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(disclosure.text, AssistantResponsePolicy.reliability)
        XCTAssertTrue(disclosure.text.contains("not academic validity"))
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testOrdinaryNumbersAllowedButPersonalInventedNumbersRejected() async throws {
        let client = TextClientStub()
        let service = FoundationAssistantService(client: client)
        for text in ["Try a 20 minute break at 7 PM.", "For a test scored out of 100, schedule 2 revision sessions."] {
            client.text = text
            let reply = try await service.respond(to: [user("How can I organize revision?")], snapshot: AssistantSnapshot())
            XCTAssertEqual(reply.text, text)
        }
        for text in ["Your predicted score is 90.", "Your steps are 5000.", "Your sleep was seven hours."] {
            client.text = text
            let reply = try await service.respond(to: [user("Hello")], snapshot: AssistantSnapshot())
            XCTAssertEqual(reply.text, AssistantResponsePolicy.toolRequired)
        }
    }

    func testRecentContextIsBoundedAndExcludesHistoricalCards() {
        let card = AssistantCard(kind: .current, title: "PRIVATE_CARD_SENTINEL", message: "", prediction: 99)
        var messages = (0..<40).map { AssistantMessage(role: .user, text: "turn\($0) " + String(repeating: "x", count: 500)) }
        messages.append(AssistantMessage(role: .assistant, text: "Recent useful context", cards: [card]))
        messages.append(user("Tell me more"))
        let prompt = AssistantContext.prompt(for: messages)
        XCTAssertLessThan(prompt.utf8.count, 3300)
        XCTAssertFalse(prompt.contains("turn0 "))
        XCTAssertTrue(prompt.contains("Recent useful context"))
        XCTAssertFalse(prompt.contains("PRIVATE_CARD_SENTINEL"))
        XCTAssertFalse(prompt.contains("99"))
        XCTAssertEqual(messages.count, 42)
    }

    func testContextFailureRetriesOnceWithLatestMessageOnly() async throws {
        let client = TextClientStub()
        client.errors = [.contextLimit]
        let service = FoundationAssistantService(client: client)
        _ = try await service.respond(to: [user("Old turn"), user("Latest turn")], snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertEqual(client.prompts.last, "Latest turn")
    }

    func testSafetyFailureNeverAutomaticallyRetries() async {
        let client = TextClientStub()
        client.errors = [.safety]
        do {
            _ = try await FoundationAssistantService(client: client).respond(to: [user("Old turn"), user("New turn")], snapshot: AssistantSnapshot())
            XCTFail("Expected refusal")
        } catch { XCTAssertEqual(error as? AssistantFailure, .safety) }
        XCTAssertEqual(client.prompts.count, 1)
    }

    func testContextRecoveryCannotLoop() async {
        let client = TextClientStub()
        client.errors = [.contextLimit, .contextLimit, .contextLimit]
        do {
            _ = try await FoundationAssistantService(client: client).respond(to: [user("Old turn"), user("Latest turn")], snapshot: AssistantSnapshot())
            XCTFail("Expected context failure")
        } catch { XCTAssertEqual(error as? AssistantFailure, .contextLimit) }
        XCTAssertEqual(client.prompts.count, 2)
    }

    func testAllInstalledSDKGenerationErrorsHaveSanitizedCategories() {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "DO_NOT_EXPOSE_SYNTHETIC_DETAIL")
        let errors: [(LanguageModelSession.GenerationError, AssistantFailure)] = [
            (.exceededContextWindowSize(context), .contextLimit), (.assetsUnavailable(context), .assetsNotReady),
            (.guardrailViolation(context), .safety), (.unsupportedGuide(context), .unsupportedGuide),
            (.unsupportedLanguageOrLocale(context), .language), (.decodingFailure(context), .decoding),
            (.rateLimited(context), .rateLimited), (.concurrentRequests(context), .busy),
            (.refusal(.init(transcriptEntries: []), context), .safety)
        ]
        for (error, category) in errors {
            XCTAssertEqual(AssistantFailure.classify(error), category)
            XCTAssertFalse(category.message.contains("DO_NOT_EXPOSE"))
        }
        XCTAssertEqual(AssistantFailure.classify(CancellationError()), .cancelled)
        XCTAssertEqual(AssistantFailure.classify(NSError(domain: "synthetic", code: 1)), .failed)
        let run = AssistantToolRun(snapshot: AssistantSnapshot(), userMessage: "")
        let toolError = LanguageModelSession.ToolCallError(tool: ReadCurrentTwinTool(run: run), underlyingError: NSError(domain: "synthetic", code: 1))
        XCTAssertEqual(AssistantFailure.classify(toolError), .toolFailure)
    }

    func testEmptyResponseIsAnExplicitRetryableFailure() async {
        let client = TextClientStub(); client.text = "  "
        do {
            _ = try await FoundationAssistantService(client: client).respond(to: [user("Hello")], snapshot: AssistantSnapshot())
            XCTFail("Expected empty response error")
        } catch { XCTAssertEqual(error as? AssistantFailure, .emptyResponse) }
    }

    func testLongSavedConversationCanContinueWithoutErasingArchive() async {
        let store = MemoryConversationStore()
        let client = TextClientStub(); client.text = String(repeating: "a", count: 1000)
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        for index in 0..<12 {
            chat.send("Hello turn \(index)")
            for _ in 0..<2000 { if !chat.isGenerating { break }; await Task.yield() }
            XCTAssertNil(chat.failure)
        }
        XCTAssertEqual(chat.messages.count, 24)
        XCTAssertEqual(chat.conversations.first?.messages.count, 24)
        XCTAssertTrue(client.prompts.allSatisfy { $0.utf8.count < 3400 })
    }

    func testTypedCancellationRemainsStoppedWithoutErrorCard() async {
        let client = TextClientStub(); client.errors = [.cancelled]
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: MemoryConversationStore())
        chat.send("Hello")
        for _ in 0..<2000 { if !chat.isGenerating { break }; await Task.yield() }
        XCTAssertTrue(chat.wasCancelled)
        XCTAssertNil(chat.failure)
        XCTAssertEqual(chat.messages.count, 1)
    }

    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func complete() -> AssistantSnapshot {
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60, studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let prediction = PredictionSnapshot.realBaseline(profile: profile, createdAt: Date(), healthWindow: nil, provenance: "explicitRun.v1")
        return AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75], predictionStatus: .fresh, lastPrediction: prediction)
    }
}

@MainActor
private final class TextClientStub: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var text = "General synthetic reply at 7 PM."
    var errors: [AssistantFailure] = []
    var prompts: [String] = []
    var instructions: [String] = []
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        if !errors.isEmpty { throw errors.removeFirst() }
        return text
    }
}
