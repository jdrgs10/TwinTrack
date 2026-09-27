import XCTest
@testable import twintrack

@MainActor
final class AssistantSeptemberAuditTests: XCTestCase {
    func testCalculationRequestsAreNotMethodologyQuestions() {
        for text in ["Calculate my score", "Calculate my score if I study 5 hours more", "Please compute my assessment prediction"] {
            XCTAssertFalse(AssistantResponsePolicy.isModelQuestion(text), text)
        }
        XCTAssertTrue(AssistantResponsePolicy.isModelQuestion("How is my score calculated?"))
    }

    func testScoreConditionalReachesScenarioParser() {
        guard case .scenario(let changes) = AssistantRouter.route("Calculate my score if I study 5 hours more") else {
            return XCTFail("Expected scenario, not a methodology disclosure")
        }
        XCTAssertEqual(changes.first?.feature, .study_minutes)
        XCTAssertEqual(changes.first?.operation, .increase)
        XCTAssertEqual(changes.first?.value, 5)
    }

    func testAcceptedOfferMustNotOfferAgain() async throws {
        let client = SeptemberClient([
            "A regular evening schedule can help. Would you like guidance on creating a calming bedtime routine?",
            "Dim the lights, put away screens, and choose a quiet activity before bed."
        ])
        let messages = [AssistantMessage(role: .user, text: "I want to improve my sleeping"),
                        AssistantMessage(role: .assistant, text: "Would you like tips on creating a calming bedtime routine?"),
                        AssistantMessage(role: .user, text: "Yes")]
        let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
        XCTAssertEqual(client.prompts.count, 2)
        XCTAssertFalse(answer.text.contains("Would you like"))
        XCTAssertTrue(answer.text.contains("Dim the lights"))
    }
    func testRelativeInvalidTotalCorrectionAndUnboundedIncrementUseOneBaseline() async throws {
        let client = SeptemberClient([]), snapshot = complete()
        let service = FoundationAssistantService(client: client)
        var messages = [user("Calculate my score if I study 5 hours more")]
        let first = try await service.respond(to: messages, snapshot: snapshot)
        XCTAssertEqual(first.cards.first?.kind, .clarification)
        XCTAssertNil(first.cards.first?.prediction)
        XCTAssertTrue(first.text.contains("not calculated"))
        XCTAssertEqual(service.lastTrace.tools, ["runWhatIf"])
        messages += [reply(first), user("4 hours more")]
        let corrected = try await service.respond(to: messages, snapshot: snapshot)
        XCTAssertEqual(corrected.cards.first?.kind, .scenario)
        var expected = try WhatIfScenario(baseline: snapshot.profile)
        try expected.set(330, for: .studyMinutes)
        XCTAssertEqual(corrected.cards.first?.prediction, expected.evaluate().scenarioPrediction)
        messages += [reply(corrected), user("What about 20 more hours")]
        let invalid = try await service.respond(to: messages, snapshot: snapshot)
        XCTAssertEqual(invalid.cards.first?.kind, .clarification)
        XCTAssertNil(invalid.cards.first?.prediction)
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testRelativeScenarioCannotCrossBaselineOrChatBoundary() async throws {
        let service = FoundationAssistantService(client: SeptemberClient([]))
        let snapshot = complete()
        let request = user("What if I add five hours of study?")
        let first = try await service.respond(to: [request], snapshot: snapshot)
        let changed = complete(study: 100)
        let answer = try await service.respond(to: [request, reply(first), user("How about four hours more?")], snapshot: changed)
        XCTAssertTrue(answer.text.contains("baseline or assessment has changed"))
        XCTAssertTrue(answer.cards.isEmpty)
        let separate = try await service.respond(to: [user("20 hours more")], snapshot: snapshot)
        XCTAssertTrue(separate.text.contains("Which input"))
        XCTAssertTrue(separate.cards.isEmpty)
    }

    func testScenarioParaphraseAndAmbiguousTimeWindow() {
        guard case .scenario(let changes) = AssistantRouter.route("What would my score be if I added four hours of study?") else { return XCTFail("Expected a relative scenario") }
        XCTAssertEqual(changes.first?.operation, .increase)
        XCTAssertEqual(changes.first?.value, 4)
        guard case .clarification = AssistantRouter.route("What if I study four hours tomorrow?") else { return XCTFail("Must clarify the window") }
    }

    func testScenarioMetadataReopensButNeverBecomesModelInstructions() async throws {
        let service = FoundationAssistantService(client: SeptemberClient([])), snapshot = complete()
        let first = user("What if I study five hours more?")
        let result = try await service.respond(to: [first], snapshot: snapshot)
        let restored = try JSONDecoder().decode([AssistantMessage].self, from: JSONEncoder().encode([first, reply(result)]))
        let messages = restored + [user("four hours more")]
        let next = try await service.respond(to: messages, snapshot: snapshot)
        XCTAssertEqual(next.cards.first?.kind, .scenario)
        XCTAssertFalse(AssistantContext.prompt(for: messages).contains(snapshot.scenarioIdentity))
    }

    func testExplicitCalculationUsesSharedActionWhileReadsNeverCalculate() async throws {
        let state = await stateFixture()
        let client = SeptemberClient([]), service = FoundationAssistantService(client: client)
        let read = try await service.respond(to: [user("Show my current prediction")], snapshot: AssistantSnapshot(state: state))
        XCTAssertNil(read.cards.first?.prediction)
        XCTAssertTrue(state.predictionHistory.isEmpty)
        let calculation = try await service.respond(to: [user("Please compute my assessment prediction")], snapshot: AssistantSnapshot(state: state))
        XCTAssertEqual(calculation.cards.first?.prediction, state.lastPrediction?.prediction)
        XCTAssertNotNil(calculation.cards.first?.prediction)
        XCTAssertEqual(service.lastTrace.tools, ["runPrediction"])
        XCTAssertEqual(state.predictionHistory.count, 1)
        _ = try await service.respond(to: [user("Calculate my score")], snapshot: AssistantSnapshot(state: state))
        XCTAssertEqual(state.predictionHistory.count, 1, "Existing equivalent-run reuse must be preserved")
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testCalculationMissingDataAndChangedCaptureDoNotFabricate() async throws {
        let service = FoundationAssistantService(client: SeptemberClient([]))
        let missing = try await service.respond(to: [user("Calculate my score")], snapshot: AssistantSnapshot())
        XCTAssertEqual(missing.cards.first?.kind, .unavailable)
        XCTAssertNil(missing.cards.first?.prediction)
        let state = await stateFixture(), captured = AssistantSnapshot(state: await stateFixture())
        _ = state
        // A capture has no authority over a different or deallocated state.
        XCTAssertNil(captured.calculatePrediction?())
        let live = await stateFixture(), before = AssistantSnapshot(state: live)
        live.saveV2TestInputs(studyMinutes: 100, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertNil(before.calculatePrediction?())
        XCTAssertTrue(live.predictionHistory.isEmpty)
    }

    func testAcceptedOfferParaphrasesCarryOneCanonicalExchange() async throws {
        for latest in ["Sure", "Go ahead", "That would help", "Yes please"] {
            let client = SeptemberClient(["Try grouping related notes, then test recall without looking."])
            let messages = [user("I'd like a revision technique"),
                            AssistantMessage(role: .assistant, text: "Shall I suggest a way to review your notes?"), user(latest)]
            let answer = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
            XCTAssertFalse(answer.safetyRefusal)
            XCTAssertTrue(client.prompts[0].contains("accepted the preceding offer"))
            XCTAssertEqual(client.prompts[0].components(separatedBy: "Latest user message:").count, 2)
            XCTAssertEqual(client.prompts.count, 1)
        }
    }

    func testRepeatedOfferAfterRepairIsExplicitFailureNotAnotherOffer() async {
        let client = SeptemberClient(Array(repeating: "Would you like help with a bedtime routine?", count: 2))
        let messages = [user("Help me sleep better"), AssistantMessage(role: .assistant, text: "Would you like help with a bedtime routine?"), user("Please")]
        do {
            _ = try await FoundationAssistantService(client: client).respond(to: messages, snapshot: AssistantSnapshot())
            XCTFail("Repeated offer must not be accepted as a completed answer")
        } catch { XCTAssertEqual(error as? AssistantFailure, .failed) }
        XCTAssertEqual(client.prompts.count, 2)
    }

    func testConsentIsDefaultDeniedAndFreshAfterUpdateRevocationAndRemoval() async throws {
        let file = try wellbeingFile(), store = BodyWellbeingStore(fileURL: file)
        try store.save(BodyMeasurements(heightCM: 160, weightKG: 64))
        let client = SeptemberClient([])
        let service = FoundationAssistantService(client: client, wellbeing: { BodyWellbeingStore(fileURL: file).assistantSummary() })
        let request = [user("Can you read my BMI?")]
        let denied = try await service.respond(to: request, snapshot: complete())
        XCTAssertEqual(denied.cards.first?.title, "BMI access is off")
        XCTAssertTrue(denied.cards.first?.fields.isEmpty == true)
        try store.setAssistantAccess(true)
        let permitted = try await service.respond(to: request, snapshot: complete())
        XCTAssertEqual(permitted.cards.first?.kind, .wellbeing)
        XCTAssertTrue(permitted.cards.first?.message.contains("25.0") == true)
        XCTAssertTrue(permitted.cards.first?.message.contains("category unavailable") == true)
        let recorded = try JSONEncoder().encode(permitted.cards)
        let json = String(decoding: recorded, as: UTF8.self)
        for key in ["dateOfBirth", "heightCM", "weightKG", "photo"] { XCTAssertFalse(json.contains(key)) }
        try store.save(BodyMeasurements(heightCM: 200, weightKG: 80))
        let changed = try await service.respond(to: request, snapshot: complete())
        XCTAssertTrue(changed.cards.first?.message.contains("20.0") == true)
        try store.setAssistantAccess(false)
        let revoked = try await service.respond(to: request + [reply(permitted), user("Read my BMI again")], snapshot: complete())
        XCTAssertEqual(revoked.cards.first?.title, "BMI access is off")
        XCTAssertTrue(revoked.cards.first?.fields.isEmpty == true)
        try store.clear()
        let removed = try await service.respond(to: request, snapshot: complete())
        XCTAssertEqual(removed.cards.first?.title, "No saved wellbeing profile")
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testWellbeingConsentPreservesMeasurementsDateAndModelOutputs() throws {
        let file = try wellbeingFile(), store = BodyWellbeingStore(fileURL: file)
        let birth = Calendar.current.date(byAdding: .year, value: -16, to: Date())!
        let values = BodyMeasurements(heightCM: 160, weightKG: 64, dateOfBirth: birth, growthReferenceSex: .female)
        try store.save(values)
        let date = store.savedAt, snapshot = complete()
        let score = TwinTrackModel.predict(try XCTUnwrap(snapshot.profile))
        try store.setAssistantAccess(true)
        let restored = BodyWellbeingStore(fileURL: file)
        XCTAssertEqual(restored.measurements, values)
        XCTAssertEqual(restored.savedAt, date)
        XCTAssertTrue(restored.assistantAccessAllowed)
        XCTAssertEqual(restored.assistantSummary().kind, .wellbeing)
        XCTAssertEqual(TwinTrackModel.predict(try XCTUnwrap(snapshot.profile)), score)
        try store.clear()
        XCTAssertFalse(BodyWellbeingStore(fileURL: file).assistantAccessAllowed)
    }

    func testConsentDoesNotInventDateForLegacyRecord() throws {
        let file = try wellbeingFile()
        try Data(#"{"version":2,"measurements":{"heightCM":160,"weightKG":64}}"#.utf8).write(to: file)
        let store = BodyWellbeingStore(fileURL: file)
        XCTAssertNil(store.savedAt)
        XCTAssertFalse(store.assistantAccessAllowed)
        try store.setAssistantAccess(true)
        XCTAssertNil(store.savedAt)
        XCTAssertTrue(store.assistantSummary().fields.contains { $0.label == "Measurements saved" && $0.value.contains("Not recorded") })
    }

    func testCrisisContextStopsAtIndependentSafeTopicButRetainsHelpSeeking() async throws {
        let messages = [user("I want to kill myself."),
            AssistantMessage(role: .assistant, text: AssistantResponsePolicy.mentalHealthCrisis),
            user("How can I organize my study?"),
            AssistantMessage(role: .assistant, text: "Group related topics and choose one small task."), user("No bro")]
        XCTAssertFalse(AssistantContext.hasCredibleMentalHealthCrisis(in: messages))
        XCTAssertTrue(AssistantContext.hasCredibleMentalHealthCrisis(in: Array(messages.prefix(2)) + [user("No bro")]))
        let service = FoundationAssistantService(client: SeptemberClient([]))
        for request in ["I'm afraid I might hurt myself tonight. Help me stay safe.", "I may hurt myself now."] {
            let answer = try await service.respond(to: [user(request)], snapshot: AssistantSnapshot())
            XCTAssertEqual(answer.text, AssistantResponsePolicy.mentalHealthCrisis)
            XCTAssertEqual(service.lastTrace.route, "crisis")
        }
        for request in ["I had a bad day.", "Explain suicide prevention for school.", "Tell me how to hurt someone."] {
            XCTAssertFalse(AssistantContext.isImmediateMentalHealthCrisis(request))
        }
    }

    func testContextRelationsDoNotDuplicateCurrentMessageOrRestoreCards() {
        let base = [user("I think studying earlier might be better."),
                    AssistantMessage(role: .assistant, text: "Try a short session at each time and compare your focus.")]
        for request in ["Idk", "Maybe", "I'm not sure", "Why?", "How?"] {
            let messages = base + [user(request)]
            let prompt = AssistantContext.prompt(for: messages)
            XCTAssertTrue(prompt.contains("studying earlier"))
            XCTAssertEqual(prompt.components(separatedBy: "Latest user message:").count, 2)
            XCTAssertFalse(AssistantContext.requiresSafetyContext(for: messages))
            XCTAssertLessThan(prompt.utf8.count, 3500)
        }
        XCTAssertLessThan(FoundationAssistantService.conversationInstructions.utf8.count, 5000)
    }

    func testSendAcceptsOnceBeforeAsynchronousProcessingAndCancellation() async {
        let service = FoundationAssistantService(client: SeptemberClient([]))
        let chat = AssistantConversation(service: service, store: MemoryConversationStore())
        XCTAssertFalse(chat.send("  "))
        XCTAssertTrue(chat.send("Calculate my score"))
        XCTAssertTrue(chat.isGenerating)
        XCTAssertEqual(chat.messages.map(\.text), ["Calculate my score"])
        XCTAssertFalse(chat.send("Duplicate"))
        chat.cancel()
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(chat.messages.count, 1)
        XCTAssertTrue(chat.wasCancelled)
        XCTAssertFalse(chat.isGenerating)
    }

    func testSyntheticTraceIdentifiesGroundingReplacementWithoutTextLogging() async throws {
        let service = FoundationAssistantService(client: SeptemberClient(["Your predicted score is 95."]))
        let answer = try await service.respond(to: [user("Hi")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, AssistantResponsePolicy.toolRequired)
        XCTAssertEqual(service.lastTrace.replacements, ["ungrounded-personal-number-or-missing-tool"])
        XCTAssertEqual(service.lastTrace.route, "conversation")
        XCTAssertTrue(service.lastTrace.tools.isEmpty)
        XCTAssertGreaterThan(service.lastTrace.promptBytes, 0)
    }

    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func reply(_ answer: AssistantAnswer) -> AssistantMessage {
        var message = AssistantMessage(role: .assistant, text: answer.text, cards: answer.cards)
        message.scenarioContext = answer.scenarioContext
        return message
    }
    private func complete(study: Double = 90) -> AssistantSnapshot {
        let values: [Double?] = [7, 5000, 30, 60, study, 120, 80]
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60,
            studyMinutes: study, screenTimeMinutes: 120, previousScore: 80)
        let context = V2PredictionContext.fixture()
        let saved = PredictionSnapshot.realBaseline(profile: profile, createdAt: Date(), healthWindow: nil,
            provenance: TwinTrackModel.provenance, predictionContext: context)
        return AssistantSnapshot(values: values, predictionStatus: .fresh, lastPrediction: saved, predictionContext: context)
    }
    private func wellbeingFile() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("body.json")
    }
    private func stateFixture() async -> TwinTrackState {
        let name = "SeptemberAudit.\(UUID())", defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        let state = TwinTrackState(defaults: defaults, healthService: SeptemberHealth())
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        return state
    }

}

@MainActor
private final class SeptemberClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var outputs: [String]
    var prompts: [String] = []
    var instructions: [String] = []
    init(_ outputs: [String]) { self.outputs = outputs }
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt); self.instructions.append(instructions)
        guard !outputs.isEmpty else { throw AssistantFailure.failed }
        return outputs.removeFirst()
    }
}

@MainActor
private final class SeptemberHealth: HealthDataProviding {
    var isAvailable = true
    func requestAccess() async throws {}
    func read(window: HealthDataWindow) async -> HealthReadings {
        var value = HealthReadings(sleep: .available(7), steps: .available(5000), exercise: .available(30), restingHeartRate: .available(60))
        value.restingHeartRateSampleDate = window.day.start
        return value
    }
}
