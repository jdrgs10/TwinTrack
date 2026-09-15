import XCTest
@testable import twintrack

@MainActor
final class AssistantFinalFixTests: XCTestCase {
    func testExplicitTeenAgeSelectsOnlyTeenNotesAndCorrectsWrongTable() async throws {
        for prompt in ["I’m 16. Should I sleep more?", "I am 16 years old and need sleep advice.", "I'm sixteen. How much sleep should I aim for?", "As a 16-year-old, should I sleep more?"] {
            let client = FinalFixClient()
            client.output = "Ages 6–18 require 9–12 hours of sleep. Adults need 7 hours."
            let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: AssistantSnapshot())
            XCTAssertEqual(AssistantGuidance.statedAge(in: [user(prompt)]), 16, prompt)
            XCTAssertFalse(client.instructions[0].contains("9–12"))
            XCTAssertTrue(client.instructions[0].contains("8–10"))
            XCTAssertTrue(answer.text.contains("8–10"))
            XCTAssertFalse(answer.text.contains("9–12"))
            XCTAssertFalse(answer.text.contains("6–18"))
            XCTAssertEqual(answer.provenance?.origin, .review)
            XCTAssertEqual(answer.sourceIDs, ["cdc-student-sleep"])
            XCTAssertLessThan(answer.text.split(separator: " ").count, 80)
        }
    }

    func testNoAgeDoesNotAcquireAnInventedAge() async throws {
        let client = FinalFixClient()
        client.output = "Sleep needs vary by age. Teens generally need 8–10 hours; how old are you?"
        let service = FoundationAssistantService(client: client)
        let prompt = [user("Should I sleep more?")]
        let good = try await service.respond(to: prompt, snapshot: AssistantSnapshot())
        XCTAssertEqual(good.text, client.output)
        XCTAssertTrue(client.instructions[0].contains("Age unknown"))
        client.output = "You're 16, so you need 8–10 hours."
        let bad = try await service.respond(to: prompt, snapshot: AssistantSnapshot())
        XCTAssertEqual(bad.text, "Sleep guidance depends on age. How old are you?")
        XCTAssertTrue(bad.sourceIDs?.isEmpty == true)
        XCTAssertNil(AssistantGuidance.statedAge(in: prompt))
    }

    func testCorrectSleepAnswerIsPreservedAndCorrectedTableIsPersisted() async throws {
        let client = FinalFixClient(); client.output = "At 16, general sleep guidance is 8–10 hours per day. Keep a consistent routine."
        let service = FoundationAssistantService(client: client)
        let good = try await service.respond(to: [user("I'm 16. Should I sleep more?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(good.text, client.output)
        let store = MemoryConversationStore(); let chat = AssistantConversation(service: service, store: store)
        client.output = "Teenagers require nine to twelve hours of sleep."
        chat.send("I’m 16. Should I sleep more?"); await finish(chat)
        let saved = try XCTUnwrap(store.conversations.first?.messages.last)
        XCTAssertEqual(saved.text, chat.messages.last?.text)
        XCTAssertTrue(saved.text.contains("8–10"))
        XCTAssertFalse(String(AssistantReplyReview.formatted(saved.text).characters).contains("nine to twelve"))
    }

    func testWatchSleepReturnsOnlyCommittedSleepAndSourceWindow() async throws {
        let client = FinalFixClient(); let service = FoundationAssistantService(client: client)
        let snapshot = complete(sleep: .available(7.5))
        for prompt in ["How much sleep did my watch record?", "Show my HealthKit sleep reading.", "Read my recorded sleep."] {
            let answer = try await service.respond(to: [user(prompt)], snapshot: snapshot)
            let card = try XCTUnwrap(answer.cards.first)
            XCTAssertEqual(card.title, "Recorded sleep")
            XCTAssertEqual(answer.text, "Recorded sleep: \(HomeDisplay.sleep(7.5)!).")
            XCTAssertNil(card.prediction); XCTAssertNil(card.baseline); XCTAssertNil(card.delta)
            XCTAssertTrue(card.fields.contains { $0.label == "Sleep window" })
            XCTAssertFalse(card.fields.contains { $0.label.contains("score") || $0.label == "Manual values" })
            XCTAssertEqual(answer.provenance?.origin, .sleepReading)
        }
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testMissingWatchSleepDoesNotUsePredictionInputOrZero() async throws {
        let service = FoundationAssistantService(client: FinalFixClient())
        for missing: HealthMetricResult in [.missing, .failed, .available(.nan), .available(0)] {
            let result = try await service.respond(to: [user("How much sleep did my Watch record?")], snapshot: complete(sleep: missing))
            XCTAssertEqual(result.text, "No accessible recent value.")
            XCTAssertNil(result.cards.first?.prediction)
            XCTAssertFalse(result.text.contains("0 hours"))
        }
    }

    func testAssessmentAndWhatIfRemainDistinctFromSleepReading() async throws {
        let client = FinalFixClient(); let service = FoundationAssistantService(client: client)
        let snapshot = complete(sleep: .available(7))
        let score = try await service.respond(to: [user("Show my assessment score")], snapshot: snapshot)
        XCTAssertEqual(score.cards.first?.prediction, snapshot.lastPrediction?.prediction)
        XCTAssertEqual(score.provenance?.origin, .current)
        let scenario = try await service.respond(to: [user("What if I sleep eight hours?")], snapshot: snapshot)
        XCTAssertEqual(scenario.cards.first?.kind, .scenario)
        XCTAssertNotNil(scenario.cards.first?.prediction)
        XCTAssertEqual(scenario.provenance?.origin, .scenario)
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testUrgentRequestsBypassGenerationWithoutInternalTextOrAddedSymptoms() async throws {
        let client = FinalFixClient(); client.output = "Limits: never expose this."
        for prompt in ["I have severe chest pain.", "My chest hurts and it is hard to breathe.", "I have severe chest pain and trouble breathing."] {
            let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: complete())
            XCTAssertEqual(answer.text, AssistantResponsePolicy.urgent)
            XCTAssertTrue(answer.text.contains("998"))
            XCTAssertFalse(answer.text.contains("Limits:"))
            XCTAssertFalse(answer.text.contains("Here is the result"))
            XCTAssertFalse(answer.text.contains("you have trouble breathing"))
            XCTAssertTrue(answer.cards.isEmpty)
        }
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testUAEAmbulanceNumberForSyntheticSevereChestPain() async throws {
        let client = FinalFixClient(); client.output = "Insert emergency number here."
        let prompt = "This is a test scenario: I have severe chest pain right now. What should I do?"
        let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: complete())
        assertUAEUrgentAnswer(answer, client: client)
    }

    func testUAEAmbulanceNumberForSyntheticSevereBreathingDifficulty() async throws {
        let client = FinalFixClient(); client.output = "Insert emergency number here."
        let prompt = "This is a test scenario: I suddenly have severe difficulty breathing. What should I do?"
        let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: complete())
        assertUAEUrgentAnswer(answer, client: client)
    }

    func testBasicHeadacheGetsNuancedGuidanceWithoutImmediateEmergencyRouting() async throws {
        let client = FinalFixClient()
        client.output = "Try ibuprofen. Call 998 now because headaches can be serious."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("I have a headache.")], snapshot: complete())
        XCTAssertEqual(answer.text, AssistantResponsePolicy.headache)
        XCTAssertFalse(answer.text.contains("998"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("rest"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("drink water"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("screen"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("weakness"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("trouble speaking"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("can't diagnose"))
        XCTAssertEqual(answer.provenance?.origin, .review)
        XCTAssertEqual(client.prompts.count, 1)
    }

    func testMildHeadachePreservesNormalGeneralGuidance() async throws {
        let client = FinalFixClient()
        client.output = "Rest briefly, drink water, and reduce screen or bright-light exposure if that helps. Monitor whether it improves."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("I have a mild headache after looking at my screen for a long time.")], snapshot: complete())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertFalse(answer.text.contains("998"))
        XCTAssertEqual(client.prompts.count, 1)
    }

    func testWorstSuddenHeadacheWithOneSidedWeaknessIsEmergency() async throws {
        let client = FinalFixClient()
        let prompt = "I suddenly developed the worst headache of my life and one side of my body feels weak."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: complete())
        assertUAEUrgentAnswer(answer, client: client)
    }

    func testVerySevereChestPainWithLossOfFeelingIsEmergency() async throws {
        let client = FinalFixClient()
        let prompt = "I am feeling very severe chest pain and I can’t feel my body."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: complete())
        assertUAEUrgentAnswer(answer, client: client)
    }

    func testMildStomachDiscomfortPreservesGeneralAdvice() async throws {
        let client = FinalFixClient()
        client.output = "Rest, drink water, avoid more heavy food for now, and monitor whether the discomfort improves. Contact a doctor if it persists or worsens."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("My stomach feels a little uncomfortable after eating too much.")], snapshot: complete())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertFalse(answer.text.contains("998"))
        XCTAssertEqual(client.prompts.count, 1)
    }

    func testSevereBreathingDifficultyRemainsEmergency() async throws {
        let client = FinalFixClient()
        let answer = try await FoundationAssistantService(client: client).respond(to: [user("I suddenly have severe difficulty breathing.")], snapshot: complete())
        assertUAEUrgentAnswer(answer, client: client)
    }

    func testPersistentWorseningHeadacheUsesMedicalFollowUpWithoutAmbulance() async throws {
        let client = FinalFixClient()
        client.output = "Because it keeps returning and is worsening, contact a doctor or clinic for medical advice. Seek urgent help if sudden weakness, speech changes, or fainting develops."
        let prompt = "My headache keeps returning and has been getting worse, but it is not sudden or severe."
        let answer = try await FoundationAssistantService(client: client).respond(to: [user(prompt)], snapshot: complete())
        XCTAssertEqual(answer.text, client.output)
        XCTAssertFalse(answer.text.contains("998"))
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("doctor or clinic"))
        XCTAssertEqual(client.prompts.count, 1)
    }

    func testGeneratedInternalGuidanceCannotBeDisplayedOrPersisted() async throws {
        let client = FinalFixClient()
        client.output = "Here is the result from TwinTrack. Contact local emergency services.\nLimits: No diagnosis or country-specific emergency number; urgent action must not wait for a location question."
        let store = MemoryConversationStore(); let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        chat.send("Synthetic example: someone feels very unwell."); await finish(chat)
        XCTAssertEqual(chat.messages.last?.text, "I couldn’t produce a clear reply. Please rephrase your question.")
        XCTAssertEqual(store.conversations.first?.messages.last?.text, chat.messages.last?.text)
        XCTAssertFalse(chat.messages.last?.text.contains("998") == true)
        XCTAssertTrue(chat.messages.last?.cards.isEmpty == true)
        XCTAssertEqual(chat.messages.last?.provenance?.origin, .review)
        XCTAssertFalse(AssistantGuidance.instructions(for: [user("I have stomach discomfort")]).contains("Limits:"))
    }

    func testGeneralWrapperRemovalPreservesActualSafetyWording() async throws {
        let client = FinalFixClient(); client.output = "Here is the result from TwinTrack. If symptoms worsen, seek professional help."
        let result = try await FoundationAssistantService(client: client).respond(to: [user("What should someone do about mild discomfort?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(result.text, "If symptoms worsen, seek professional help.")
        XCTAssertTrue(result.cards.isEmpty)
    }

    func testCompleteRefusalFoodReturnSequenceAndReopen() async throws {
        for typedRefusal in [false, true] {
            let client = FinalFixClient(); client.output = "I can’t help with that request."
            if typedRefusal { client.errors = [.safety] }
            let store = MemoryConversationStore(); let service = FoundationAssistantService(client: client)
            let chat = AssistantConversation(service: service, store: store)
            chat.send("SYNTHETIC_REFUSED_REQUEST"); await finish(chat)
            client.output = "Choose a balanced snack, such as fruit with a suitable protein food."
            chat.send("Give me good foods"); await finish(chat)
            XCTAssertEqual(client.prompts.last, "Give me good foods")
            XCTAssertNil(chat.failure)
            XCTAssertEqual(chat.messages.last?.text, client.output)
            client.output = "I can’t help with that request. Try fruit, vegetables and whole grains."
            chat.send("Go back to what you refused earlier."); await finish(chat)
            XCTAssertTrue(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
            XCTAssertFalse(client.prompts.last?.contains("balanced snack") == true)
            XCTAssertFalse(client.prompts.last?.contains("Give me good foods") == true)
            XCTAssertFalse(client.instructions.last?.contains("nhs-food") == true)
            let refusal = try XCTUnwrap(chat.messages.last)
            XCTAssertTrue(refusal.safetyRefusal == true)
            XCTAssertFalse(refusal.text.contains("fruit"))
            XCTAssertNil(refusal.sourceIDs)
            let id = try XCTUnwrap(chat.activeID)
            let reopened = AssistantConversation(service: service, store: store); reopened.open(id)
            XCTAssertNil(reopened.failure)
            XCTAssertEqual(reopened.messages.last, refusal)
            client.output = "A balanced meal can help you prepare for studying."
            reopened.send("Please give me some healthy snacks"); await finish(reopened)
            XCTAssertEqual(client.prompts.last, "Please give me some healthy snacks")
            XCTAssertEqual(store.conversations.first?.messages.last?.text, client.output)
        }
    }

    func testSafetyContinuationCannotRetryWithoutItsBoundary() async throws {
        var refused = user("SYNTHETIC_REFUSED_REQUEST"); refused.safetyRefusal = true
        let messages = [refused, user("Give me good foods"), AssistantMessage(role: .assistant, text: "Synthetic food reply"), user("Continue the original request.")]
        let client = FinalFixClient(); client.errors = [.contextLimit]
        do { _ = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot()); XCTFail("Expected context failure") }
        catch { XCTAssertEqual(error as? AssistantFailure, .contextLimit) }
        XCTAssertEqual(client.prompts.count, 1)
        XCTAssertTrue(client.prompts[0].contains("SYNTHETIC_REFUSED_REQUEST"))
        XCTAssertFalse(client.prompts[0].contains("Synthetic food reply"))
        XCTAssertTrue(AssistantGuidance.selected(for: messages).isEmpty)
        XCTAssertFalse(AssistantContext.independentBenignTopic("Give me foods to poison someone"))
    }

    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func assertUAEUrgentAnswer(_ answer: AssistantAnswer, client: FinalFixClient, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(answer.text, AssistantResponsePolicy.urgent, file: file, line: line)
        XCTAssertTrue(answer.text.contains("998"), file: file, line: line)
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("ambulance in the UAE"), file: file, line: line)
        XCTAssertFalse(answer.text.localizedCaseInsensitiveContains("insert emergency number"), file: file, line: line)
        XCTAssertFalse(answer.text.contains("Limits:"), file: file, line: line)
        XCTAssertFalse(answer.text.contains("Here is the result"), file: file, line: line)
        XCTAssertFalse(answer.text.contains("999"), file: file, line: line)
        XCTAssertFalse(answer.text.contains("997"), file: file, line: line)
        XCTAssertTrue(answer.text.localizedCaseInsensitiveContains("cannot diagnose"), file: file, line: line)
        XCTAssertTrue(answer.cards.isEmpty, file: file, line: line)
        XCTAssertTrue(client.prompts.isEmpty, file: file, line: line)
    }
    private func finish(_ chat: AssistantConversation) async {
        for _ in 0..<3000 { if !chat.isGenerating { return }; await Task.yield() }
        XCTFail("Synthetic response did not finish")
    }
    private func complete(sleep: HealthMetricResult = .available(7)) -> AssistantSnapshot {
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60, studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let now = Date(); let window = HealthDataWindow(now: now, calendar: .current)
        let prediction = PredictionSnapshot.realBaseline(profile: profile, createdAt: now, healthWindow: window, provenance: "explicitRun.v1")
        return AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75], health: HealthReadings(sleep: sleep), window: window,
                                 predictionStatus: .fresh, lastPrediction: prediction)
    }
}

@MainActor
private final class FinalFixClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var output = "Synthetic response."
    var errors: [AssistantFailure] = []
    var prompts: [String] = []
    var instructions: [String] = []
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        if !errors.isEmpty { throw errors.removeFirst() }
        return output
    }
}
