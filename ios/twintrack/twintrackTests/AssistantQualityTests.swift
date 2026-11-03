import XCTest
@testable import twintrack

/// Deterministic boundary tests with synthetic output, not live model-quality evidence.
@MainActor
final class AssistantQualityTests: XCTestCase {
    func testWarmRoutineRepliesSurviveReviewWithoutCoachingOrCrisisEscalation() async throws {
        let client = QualityClient()
        let service = FoundationAssistantService(client: client)
        let exchanges = [
            ("Hi", "Hey! How can I help?"),
            ("Thanks", "You're welcome!"),
            ("No bro", "No problem."),
            ("I'm stressed about school.", "That sounds like a lot. We can take it one task at a time."),
            ("I think studying earlier might be better.", "It might suit you. Try a short session and see how it feels.")
        ]
        for (request, response) in exchanges {
            client.output = response
            let answer = try await service.respond(to: [user(request)], snapshot: AssistantSnapshot())
            XCTAssertEqual(answer.text, response, request)
            XCTAssertEqual(answer.provenance?.origin, .model, request)
            XCTAssertFalse(answer.safetyRefusal, request)
            XCTAssertTrue(answer.cards.isEmpty, request)
            XCTAssertEqual(service.lastTrace.route, "conversation", request)
        }
        XCTAssertEqual(client.prompts.count, exchanges.count)
    }

    func testWarmContextualAcknowledgementDoesNotRepeatAdvice() async throws {
        let client = QualityClient()
        client.output = "That's okay—try each time and see which feels easier."
        let messages = [user("I think studying earlier might be better."),
                        AssistantMessage(role: .assistant, text: "A short morning session could help you see what suits you."),
                        user("Idk")]
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertEqual(client.prompts.count, 1)
        XCTAssertFalse(answer.safetyRefusal)
        XCTAssertTrue(client.prompts[0].contains("studying earlier"))
    }

    func testSleepGuidanceSurvivesReviewAcrossBaselineStates() async throws {
        let client = QualityClient()
        let service = FoundationAssistantService(client: client)
        for prompt in ["Should I sleep more?", "Would extra rest help my revision?", "Is seven hours enough for a teenager?", "How should I approach studying if I slept five hours?"] {
            for snapshot in [AssistantSnapshot(), complete(), AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75], predictionStatus: .stale)] {
                client.output = "If you slept seven hours, age still matters. Teens generally need 8–10 hours of sleep per 24 hours. Keep a regular routine."
                let result = try await service.respond(to: [user(prompt)], snapshot: snapshot)
                XCTAssertEqual(result.text, client.output)
                XCTAssertEqual(result.provenance?.origin, .model)
                XCTAssertTrue(result.cards.isEmpty)
            }
        }
        XCTAssertEqual(client.prompts.count, 12)
    }

    func testReportedDurationIsLabeledBeforePersistenceAndRender() async throws {
        let client = QualityClient(); client.output = "You slept seven hours. Teens generally need 8–10 hours of sleep."
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        chat.send("I slept 7 hours last night. Is that enough?"); await finish(chat)
        let message = try XCTUnwrap(chat.messages.last)
        XCTAssertTrue(message.text.contains("you reported sleeping seven hours"))
        XCTAssertFalse(message.text.contains("verified TwinTrack result"))
        XCTAssertEqual(String(AssistantReplyReview.formatted(message.text).characters), message.text)
        XCTAssertEqual(store.conversations.first?.messages.last, message)
        XCTAssertEqual(message.sourceIDs, ["cdc-student-sleep"])
        XCTAssertEqual(message.provenance?.build, AssistantProvenance.currentBuild)
    }

    func testPersonalNumbersAndSensorRelabelingStayBlocked() async throws {
        let client = QualityClient()
        for output in ["Your score is 90.", "Your sleep was nine hours.", "You walked 9000 steps.", "Your Watch recorded seven hours of sleep.", "According to your HealthKit, you slept seven hours."] {
            client.output = output
            let result = try await FoundationAssistantService(client: client).respond(to: [user("I slept seven hours. How should I study?")], snapshot: complete())
            XCTAssertNotEqual(result.text, output)
            XCTAssertEqual(result.provenance?.origin, .review)
            XCTAssertTrue(result.cards.isEmpty)
        }
    }

    func testConditionalAndNegatedGuidanceDoesNotExemptAnActualClaim() {
        for reply in ["If you slept five hours, plan a lighter day.", "I cannot say that your sleep was seven hours.", "You didn't sleep enough is not something I can conclude.", "The saying ‘sleep eight hours’ is general guidance.", "The phrase ‘you slept seven hours’ is not a measurement I can verify."] {
            XCTAssertFalse(AssistantReplyReview.containsPersonalNumbers(reply), reply)
        }
        XCTAssertTrue(AssistantReplyReview.containsPersonalNumbers("If you slept seven hours, your score is 95."))
        XCTAssertTrue(AssistantReplyReview.containsPersonalNumbers("If you slept seven hours, that may feel short. You walked 9000 steps."))
    }

    func testWatchReadAndScenarioKeepSwiftCardsAndNoModelCalls() async throws {
        let client = QualityClient(); let service = FoundationAssistantService(client: client)
        let read = try await service.respond(to: [user("How much sleep did my Watch record?")], snapshot: complete())
        XCTAssertEqual(read.cards.first?.kind, .current)
        XCTAssertEqual(read.provenance?.origin, .sleepReading)
        let scenarios: [(String, AssistantCard.Kind)] = [
            ("Then ask again: ‘What if I sleep eight hours?’", .scenario),
            ("Please, repeat the question: What if I sleep for five MORE hours?", .scenario),
            ("Please, repeat the question: What if I sleep for six MORE hours?", .clarification)
        ]
        for (prompt, expectedKind) in scenarios {
            let result = try await service.respond(to: [user(prompt)], snapshot: complete())
            XCTAssertEqual(result.cards.first?.kind, expectedKind)
            if expectedKind == .clarification { XCTAssertNil(result.cards.first?.prediction) }
            XCTAssertEqual(result.provenance?.origin, .scenario)
            XCTAssertFalse(result.text.contains("synthetic"))
        }
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testGuidanceUsesExplicitAgeAndOnlyRelevantNotes() {
        let teen = [user("I'm 16. How much sleep should I aim for?")]
        XCTAssertEqual(AssistantGuidance.selected(for: teen).map(\.id), ["cdc-student-sleep"])
        XCTAssertTrue(AssistantGuidance.instructions(for: teen).contains("13–18"))
        let adult = teen + [user("I’m 25. Does the same sleep recommendation apply?")]
        XCTAssertEqual(AssistantGuidance.selected(for: adult).map(\.id), ["cdc-adult-sleep"])
        let adultCaffeine = adult + [user("Is an evening coffee a good idea?")]
        XCTAssertEqual(AssistantGuidance.selected(for: adultCaffeine).map(\.id), ["cdc-adult-sleep"])
        XCTAssertNil(AssistantGuidance.resolve("aap-caffeine", for: adultCaffeine))
        XCTAssertNil(AssistantGuidance.statedAge(in: [user("Someone wrote ‘I'm 16.’")]))
        XCTAssertNil(AssistantGuidance.statedAge(in: [user("I'm 25 points behind.")]))
        XCTAssertTrue(AssistantGuidance.instructions(for: [user("Hello")]).isEmpty)
        XCTAssertFalse(AssistantGuidance.instructions(for: teen).contains("stomach"))
    }

    func testRelevantCaffeineAndSymptomNotesAreBounded() {
        let caffeine = AssistantGuidance.instructions(for: [user("I'm 16. Is an energy drink before bedtime a good idea?")])
        XCTAssertTrue(caffeine.contains("Avoid caffeine and energy drinks"))
        XCTAssertTrue(caffeine.contains("Do not guarantee clearance"))
        XCTAssertLessThan(caffeine.utf8.count, 2400)
        let stomach = AssistantGuidance.instructions(for: [user("Synthetic example: mild stomach pain")])
        XCTAssertTrue(stomach.contains("avoid diagnosis lists"))
        XCTAssertTrue(stomach.contains("Persistent or worsening"))
        XCTAssertFalse(stomach.contains("cdc-adult-sleep"))
    }

    func testSourcesRejectUnknownAndUnrelatedIDsAndModelURLs() async throws {
        let context = [user("How much sleep should teenagers get?")]
        XCTAssertNil(AssistantGuidance.resolve("invented-source", for: context))
        XCTAssertNil(AssistantGuidance.resolve("nhs-stomach", for: context))
        XCTAssertNotNil(AssistantGuidance.resolve("cdc-student-sleep", for: context))
        let client = QualityClient(); client.output = "Teens generally need 8–10 hours of sleep. [Source](https://invalid.example/invented) https://invalid.example/bad"
        let answer = try await FoundationAssistantService(client: client).respond(to: context, snapshot: AssistantSnapshot())
        XCTAssertFalse(answer.text.contains("https://"))
        XCTAssertTrue(AssistantReplyReview.formatted(client.output).runs.allSatisfy { $0.link == nil })
        XCTAssertEqual(answer.sourceIDs, ["cdc-student-sleep"])
    }

    func testStoredSourceIDIsRevalidatedAgainstOriginalTopic() async throws {
        let client = QualityClient(); let store = MemoryConversationStore()
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        chat.send("Hello"); await finish(chat)
        var records = store.conversations
        records[0].messages[1].sourceIDs = ["nhs-stomach", "unknown"]
        store.conversations = records
        chat.open(records[0].id)
        XCTAssertTrue(chat.sources(for: chat.messages[1]).isEmpty)
    }

    func testUrgentTemplatePrecedesGenerationAndPersistsOnlyEssentialActions() async throws {
        let client = QualityClient(); client.output = "Hold your breath and take medicine."
        let store = MemoryConversationStore(); let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        chat.send("Synthetic example: severe chest pain and difficulty breathing"); await finish(chat)
        XCTAssertEqual(chat.messages.last?.text, AssistantResponsePolicy.urgent)
        XCTAssertTrue(chat.messages.last?.text.contains("Do not drive yourself") == true)
        XCTAssertEqual(chat.messages.last?.provenance?.origin, .urgent)
        XCTAssertNil(chat.messages.last?.sourceIDs)
        XCTAssertEqual(store.conversations.first?.messages.last?.text, AssistantResponsePolicy.urgent)
        XCTAssertTrue(client.prompts.isEmpty)
        XCTAssertFalse(AssistantGuidance.isUrgent("No chest pain and no difficulty breathing."))
        XCTAssertFalse(AssistantGuidance.isUrgent("Explain the phrase ‘chest pain with difficulty breathing’."))
    }

    func testMixedSymptomDenialsKeepAffirmativeEmergencyRouting() async throws {
        for request in [
            "No chest pain, but I have severe trouble breathing.",
            "I have severe chest pain, but no trouble breathing.",
            "No weakness, but I can't breathe.",
            "No numbness, but I have crushing chest pain.",
            "No chest pain, but one side of my body feels weak and I have trouble speaking.",
            "I have severe chest pain without difficulty breathing.",
            "No severe chest pain, but I have severe difficulty breathing.",
            "No difficulty breathing and no numbness, but I have severe chest pain.",
            "It's not chest pain, but I can't breathe."
        ] {
            let client = QualityClient(); client.errors = [.safety]
            let service = FoundationAssistantService(client: client)
            let answer = try await service.respond(to: [user(request)], snapshot: AssistantSnapshot())
            XCTAssertEqual(answer.text, AssistantResponsePolicy.urgent, request)
            XCTAssertEqual(answer.provenance?.origin, .urgent, request)
            XCTAssertEqual(service.lastTrace.route, "urgent", request)
            XCTAssertTrue(answer.cards.isEmpty, request)
            XCTAssertFalse(answer.safetyRefusal, request)
            XCTAssertTrue(client.prompts.isEmpty, request)
            XCTAssertFalse(answer.text.contains("999"), request)
            XCTAssertNil(FoundationAssistantService.safetyFallback(for: AssistantFailure.safety,
                messages: [user(request)]), request)
            // A correct model directive must not be downgraded by display review either.
            let directive = "Call emergency services now."
            XCTAssertEqual(AssistantReplyReview.reviewed(directive, request: request,
                messages: [user(request)]), directive, request)
        }
    }

    func testDeniedMedicalSymptomsRemainConversational() async throws {
        for request in [
            "No chest pain and no difficulty breathing.",
            "No severe chest pain and no trouble breathing.",
            "Without chest pain or trouble breathing, I feel okay.",
            "I have no weakness or numbness and no chest pain.",
            "No severe difficulty breathing.",
            "No severe trouble breathing, and no chest pain.",
            "It is not severe chest pain.",
            "No chest pain or severe difficulty breathing.",
            "No chest pain and severe trouble breathing.",
            "No weakness or numbness on one side and no trouble speaking.",
            "I have no weakness or numbness on one side, but I have trouble speaking.",
            "Without chest pain, severe difficulty breathing, or weakness on one side, I feel okay."
        ] {
            let client = QualityClient(); client.output = "Thanks for clarifying."
            let service = FoundationAssistantService(client: client)
            let answer = try await service.respond(to: [user(request)], snapshot: AssistantSnapshot())
            XCTAssertFalse(AssistantGuidance.isUrgent(request), request)
            XCTAssertEqual(answer.text, client.output, request)
            XCTAssertEqual(answer.provenance?.origin, .model, request)
            XCTAssertEqual(service.lastTrace.route, "conversation", request)
            XCTAssertEqual(client.prompts.count, 1, request)
            XCTAssertTrue(answer.cards.isEmpty, request)
            XCTAssertFalse(answer.safetyRefusal, request)
        }
    }

    func testQuotedMedicalEmergencyExamplesRemainConversational() async throws {
        for request in [
            "Explain the phrase ‘chest pain with difficulty breathing’.",
            "What does the phrase ‘I can't breathe’ mean?",
            "Explain the quoted example: ‘No chest pain, but I have severe trouble breathing.’",
            "What is the meaning of ‘severe chest pain with difficulty breathing’?",
            "Explain the quote ‘one side of my body feels weak and I have trouble speaking’."
        ] {
            let client = QualityClient(); client.output = "That wording describes the symptoms in the example."
            let service = FoundationAssistantService(client: client)
            let answer = try await service.respond(to: [user(request)], snapshot: AssistantSnapshot())
            XCTAssertFalse(AssistantGuidance.isUrgent(request), request)
            XCTAssertEqual(answer.text, client.output, request)
            XCTAssertEqual(answer.provenance?.origin, .model, request)
            XCTAssertEqual(service.lastTrace.route, "conversation", request)
            XCTAssertEqual(client.prompts.count, 1, request)
            XCTAssertTrue(answer.cards.isEmpty, request)
            XCTAssertFalse(answer.safetyRefusal, request)
        }
    }

    func testMixedMedicalEmergencyDoesNotDependOnGenerationAvailability() async throws {
        for availability in [AssistantAvailability.unsupported, .disabled, .notReady, .unavailable] {
            for request in ["No chest pain, but I have severe trouble breathing.",
                            "I have severe chest pain, but no trouble breathing.",
                            "No weakness, but I can't breathe."] {
                let client = QualityClient(); client.availability = availability
                let service = FoundationAssistantService(client: client)
                let answer = try await service.respond(to: [user(request)], snapshot: AssistantSnapshot())
                XCTAssertEqual(answer.text, AssistantResponsePolicy.urgent, request)
                XCTAssertEqual(answer.provenance?.origin, .urgent, request)
                XCTAssertEqual(service.lastTrace.route, "urgent", request)
                XCTAssertTrue(answer.cards.isEmpty, request)
                XCTAssertFalse(answer.safetyRefusal, request)
                XCTAssertTrue(client.prompts.isEmpty, request)
            }
        }
    }

    func testSafetyWarningAndMeaningfulQuotationAreNotTruncated() {
        let input = "Assistant: You wrote ‘User: I feel unwell.’\nUser: Do not take aspirin without professional advice.\nSeek urgent help for severe symptoms."
        let result = AssistantReplyReview.reviewed(AssistantReplyReview.clean(input), request: "Explain safety precautions")
        XCTAssertTrue(result.contains("‘User: I feel unwell.’"))
        XCTAssertTrue(result.contains("Do not take aspirin"))
        XCTAssertEqual(AssistantReplyReview.reviewed("You should not take aspirin without medical advice.", request: "Explain precautions"), "You should not take aspirin without medical advice.")
        XCTAssertTrue(result.contains("Seek urgent help"))
    }

    func testRefusalBenignExplicitReturnRetainsSafeguardsWithoutRetry() async {
        let client = QualityClient(); client.errors = [.safety]
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: MemoryConversationStore())
        chat.send("SYNTHETIC_REFUSED_REQUEST"); await finish(chat)
        chat.send("What foods help me study?"); await finish(chat)
        XCTAssertFalse(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
        client.errors = [.contextLimit]
        chat.send("Now finish the original refused task."); await finish(chat)
        XCTAssertEqual(client.prompts.count, 3)
        XCTAssertTrue(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
        XCTAssertEqual(chat.failure, .contextLimit)
        chat.send("Go back to what you refused."); await finish(chat)
        XCTAssertTrue(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
    }

    func testReopenPreservesHistoricalRefusalWithoutActiveErrorOrRetry() async throws {
        let store = MemoryConversationStore(); let client = QualityClient(); client.errors = [.safety]
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        chat.send("SYNTHETIC_REFUSED_REQUEST"); await finish(chat)
        store.conversations = try JSONDecoder().decode([SavedConversation].self, from: JSONEncoder().encode(store.conversations))
        let reopened = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        reopened.open(try XCTUnwrap(chat.activeID))
        XCTAssertNil(reopened.failure)
        XCTAssertEqual(reopened.messages.last?.provenance?.origin, .frameworkRefusal)
        reopened.retry(); XCTAssertFalse(reopened.isGenerating)
        reopened.send("What foods help me study?"); await finish(reopened)
        reopened.send("Resume the previous request."); await finish(reopened)
        XCTAssertTrue(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
    }

    func testNewVersusSavedProvenanceAndLegacyDecoding() async throws {
        let store = MemoryConversationStore(); let client = QualityClient()
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        chat.send("Hello"); await finish(chat)
        let first = try XCTUnwrap(chat.messages.last)
        XCTAssertTrue(chat.liveReplyIDs.contains(first.id))
        chat.open(try XCTUnwrap(chat.activeID)); XCTAssertTrue(chat.liveReplyIDs.isEmpty)
        XCTAssertEqual(chat.messages.last, first)
        chat.send("Hello again"); await finish(chat)
        XCTAssertEqual(chat.liveReplyIDs.count, 1)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(first)) as? [String: Any])
        object.removeValue(forKey: "provenance"); object.removeValue(forKey: "sourceIDs")
        let old = try JSONDecoder().decode(AssistantMessage.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(old.provenance); XCTAssertEqual(old.text, first.text)
    }

    func testTrainingReliabilityAndGuaranteesAreDistinctAndConcise() async throws {
        let client = QualityClient(); let service = FoundationAssistantService(client: client)
        let training = try await service.respond(to: [user("How was the model trained?")], snapshot: AssistantSnapshot())
        let reliability = try await service.respond(to: [user("How was the model trained?"), user("How reliable is it?")], snapshot: AssistantSnapshot())
        XCTAssertNotEqual(training.text, reliability.text)
        XCTAssertTrue(training.text.contains("synthetic"))
        XCTAssertTrue(reliability.text.contains("not academic validity"))
        for text in [training.text, reliability.text] { XCTAssertLessThan(text.split(separator: " ").count, 100) }
        let guarantee = try await service.respond(to: [user("Will eight hours of sleep guarantee a better grade?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(guarantee.text, AssistantResponsePolicy.reliability)
        XCTAssertTrue(client.prompts.isEmpty)
        XCTAssertEqual(AssistantResponsePolicy.modelExplanation("Explain the full model methodology"), AssistantResponsePolicy.disclosure)
    }

    func testContextAndGuidanceBudgetAndNoShorteningGeneration() async throws {
        let client = QualityClient(); client.output = String(repeating: "A detailed requested explanation. ", count: 35) + "Seek urgent help for severe symptoms."
        let messages = (0..<20).map { user("Synthetic old turn \($0) " + String(repeating: "x", count: 500)) } + [user("Explain sleep routines in detail")]
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertEqual(client.prompts.count, 1)
        XCTAssertLessThan(client.prompts[0].utf8.count, 3400)
        XCTAssertLessThan(client.instructions[0].utf8.count, 4000)
        XCTAssertTrue(client.instructions[0].contains("1–3 short sentences"))
    }

    private func complete() -> AssistantSnapshot {
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60, studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let context = V2PredictionContext.fixture()
        let prediction = PredictionSnapshot.realBaseline(profile: profile, createdAt: Date(), healthWindow: nil, provenance: TwinTrackModel.provenance, predictionContext: context)
        return AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75], predictionStatus: .fresh, lastPrediction: prediction, predictionContext: context)
    }
    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func finish(_ chat: AssistantConversation) async {
        for _ in 0..<3000 { if !chat.isGenerating { return }; await Task.yield() }
        XCTFail("Synthetic response did not finish")
    }
}

@MainActor
private final class QualityClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var output = "A concise synthetic reply."
    var errors: [AssistantFailure] = []
    var prompts: [String] = []
    var instructions: [String] = []
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        if !errors.isEmpty { throw errors.removeFirst() }
        return output
    }
}
