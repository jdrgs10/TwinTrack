import XCTest
@testable import twintrack

@MainActor
final class FocusedRegressionTests: XCTestCase {
    func testBMIImproveFollowupKeepsFreshTeenReference() async throws {
        let (store, service, client) = try fixture()
        let answer = try await followup("How can I improve it?", service: service)
        XCTAssertEqual(answer.cards.first?.message, store.assistantSummary().message)
        XCTAssertTrue(answer.text.contains("healthy BMI-for-age category"))
        XCTAssertTrue(answer.text.contains("not a diagnosis or a number to optimize"))
        XCTAssertFalse(answer.text.contains("adult"))
        XCTAssertEqual(client.calls, 0)
    }

    func testBMIHealthyFollowupUsesStoredCategory() async throws {
        let (store, service, client) = try fixture()
        let answer = try await followup("Is that healthy?", service: service)
        XCTAssertEqual(answer.cards.first?.message, store.assistantSummary().message)
        XCTAssertTrue(answer.text.contains("healthy BMI-for-age category"))
        XCTAssertEqual(client.calls, 0)
    }

    func testPercentileQuestionDoesNotUseQuotedNumberAsMeasurement() async throws {
        let (store, service, client) = try fixture()
        let answer = try await followup("What does 12th percentile mean?", service: service)
        XCTAssertTrue(answer.text.contains("same age and sex"))
        XCTAssertFalse(answer.text.contains("12th"))
        XCTAssertEqual(answer.cards.first?.message, store.assistantSummary().message)
        XCTAssertEqual(client.calls, 0)
    }

    func testMeasurementChangedBetweenTurnsUsesFreshRead() async throws {
        let (store, service, client) = try fixture()
        let history = try await startingChat(service)
        let old = history.last!.cards.first!.message
        let prior = store.measurements!
        let changed = BodyMeasurements(heightCM: prior.heightCM, weightKG: 58,
            dateOfBirth: prior.dateOfBirth, growthReferenceSex: prior.growthReferenceSex)
        try store.save(changed)
        let answer = try await service.respond(to: history + [user("How can I improve it?")], snapshot: AssistantSnapshot())
        XCTAssertNotEqual(answer.cards.first?.message, old)
        XCTAssertEqual(answer.cards.first?.message, store.assistantSummary().message)
        XCTAssertEqual(client.calls, 0)
    }

    func testRevokedPermissionStopsFollowupAndLaterElaboration() async throws {
        let (store, service, client) = try fixture()
        var history = try await startingChat(service)
        try store.setAssistantAccess(false)
        let answer = try await service.respond(to: history + [user("Is that healthy?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.cards.first?.title, "BMI access is off")
        XCTAssertNil(answer.cards.first?.wellbeingSummary)
        history += [user("Is that healthy?"), reply(answer), user("Why?")]
        let again = try await service.respond(to: history, snapshot: AssistantSnapshot())
        XCTAssertEqual(again.cards.first?.title, "BMI access is off")
        XCTAssertEqual(client.calls, 0)
    }

    func testRemovedMeasurementCannotReappearFromChat() async throws {
        let (store, service, _) = try fixture()
        let history = try await startingChat(service)
        try store.clear()
        let answer = try await service.respond(to: history + [user("Is that healthy?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.cards.first?.title, "No saved wellbeing profile")
        XCTAssertNil(answer.cards.first?.wellbeingSummary)
    }

    func testSavedAndLegacyCardsResolveSubjectButRereadCurrentSummary() async throws {
        let (store, service, client) = try fixture()
        var history = try await startingChat(service)
        history[1].cards[0].wellbeingSummary = nil // Previous schema did not contain interpretation metadata.
        history = try JSONDecoder().decode([AssistantMessage].self, from: JSONEncoder().encode(history))
        let answer = try await service.respond(to: history + [user("Is that healthy?")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.cards.first?.message, store.assistantSummary().message)
        XCTAssertEqual(answer.cards.first?.wellbeingSummary?.reference, .childTeen)
        XCTAssertEqual(client.calls, 0)
    }

    func testNewTopicDoesNotInheritWellbeingRoute() async throws {
        let (_, service, _) = try fixture()
        let history = try await startingChat(service)
        for text in ["How can I improve my study habits?", "Tell me a joke", "How can I use that to hurt somebody?"] {
            XCTAssertFalse(AssistantWellbeingContext.continuesSummary(history + [user(text)]))
        }
        let switched = history + [user("Tell me a joke"), AssistantMessage(role: .assistant, text: "A harmless joke."), user("Why?")]
        XCTAssertFalse(AssistantWellbeingContext.continuesSummary(switched))
    }

    func testUnsupportedPersonalBMINumbersAreReviewed() {
        XCTAssertTrue(AssistantReplyReview.containsPersonalNumbers("Your BMI is 29.4."))
        XCTAssertTrue(AssistantReplyReview.containsPersonalNumbers("The current BMI was 29.4."))
        XCTAssertFalse(AssistantReplyReview.containsPersonalNumbers("BMI is a screening measure."))
    }

    func testCrisisPrecedesWellbeingFollowup() async throws {
        let (_, service, client) = try fixture()
        let history = try await startingChat(service)
        let answer = try await service.respond(to: history + [user("I want to commit suicide.")], snapshot: AssistantSnapshot())
        XCTAssertEqual(answer.text, AssistantResponsePolicy.mentalHealthCrisis)
        XCTAssertTrue(answer.cards.isEmpty)
        XCTAssertEqual(client.calls, 0)
    }

    func testHomeSavedAndUnavailableStatesKeepAccurateActions() {
        let cases: [(PredictionStatus, Bool, Bool, String, Bool)] = [
            (.fresh, true, false, "Saved estimate · Inputs match", false),
            (.stale, true, false, "Saved estimate · Inputs changed", true),
            (.needsRefresh, true, false, "Saved estimate · Refresh Health inputs", false),
            (.missing, true, true, "Saved estimate · Confirm manual inputs", false),
            (.refreshing, true, false, "Saved estimate · Refreshing inputs", false),
            (.missing, false, false, "Inputs unavailable", false),
            (.ready, false, false, "Current inputs ready", true)
        ]
        for (status, saved, manual, copy, runnable) in cases {
            let presentation = HomePredictionPresentation(status: status, hasSaved: saved, needsManualUpdate: manual)
            XCTAssertEqual(presentation.stateLine, copy)
            XCTAssertEqual(presentation.canRun, runnable)
        }
    }

    func testHomePresentationDoesNotRecalculateAfterHealthChanges() async throws {
        let name = "FocusedHome.\(UUID())", defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        let health = FocusedHealth()
        let state = TwinTrackState(defaults: defaults, healthService: health)
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertTrue(state.runPrediction())
        let saved = state.lastPrediction
        XCTAssertEqual(state.predictionStatus(), .fresh)
        await state.refreshHealth()
        XCTAssertEqual(state.predictionStatus(), .fresh)
        health.steps = 6500
        await state.refreshHealth()
        XCTAssertEqual(state.predictionStatus(), .stale)
        let view = HomePredictionPresentation(status: state.predictionStatus(), hasSaved: true, needsManualUpdate: false)
        XCTAssertTrue(view.canRun)
        XCTAssertEqual(view.stateLine, "Saved estimate · Inputs changed")
        XCTAssertEqual(state.lastPrediction, saved)
        XCTAssertEqual(state.predictionHistory.count, 1)
    }

    func testHomeReconfirmationKeepsSavedResultAndExposesManualAction() async throws {
        let name = "FocusedHome.\(UUID())", defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        let state = TwinTrackState(defaults: defaults, healthService: FocusedHealth())
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        XCTAssertTrue(state.runPrediction())
        let saved = state.lastPrediction
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertNotNil(state.v2EligibilityIssue(now: tomorrow))
        let view = HomePredictionPresentation(status: state.predictionStatus(now: tomorrow), hasSaved: true, needsManualUpdate: true)
        XCTAssertFalse(view.canRun)
        XCTAssertEqual(view.stateLine, "Saved estimate · Confirm manual inputs")
        XCTAssertEqual(state.lastPrediction, saved)
    }

    private func fixture() throws -> (BodyWellbeingStore, FoundationAssistantService, FocusedClient) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("synthetic.json")
        let store = BodyWellbeingStore(fileURL: url)
        let birth = Calendar.current.date(byAdding: .year, value: -16, to: Date())!
        try store.save(BodyMeasurements(heightCM: 165, weightKG: 54,
            dateOfBirth: birth, growthReferenceSex: .female))
        try store.setAssistantAccess(true)
        let client = FocusedClient()
        return (store, FoundationAssistantService(client: client,
            wellbeing: { BodyWellbeingStore(fileURL: url).assistantSummary() }), client)
    }
    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func reply(_ answer: AssistantAnswer) -> AssistantMessage {
        var message = AssistantMessage(role: .assistant, text: answer.text, cards: answer.cards)
        message.provenance = answer.provenance
        return message
    }
    private func startingChat(_ service: FoundationAssistantService) async throws -> [AssistantMessage] {
        let request = user("How much is my BMI?")
        return [request, reply(try await service.respond(to: [request], snapshot: AssistantSnapshot()))]
    }
    private func followup(_ text: String, service: FoundationAssistantService) async throws -> AssistantAnswer {
        let messages = try await startingChat(service) + [user(text)]
        return try await service.respond(to: messages, snapshot: AssistantSnapshot())
    }
}

@MainActor
private final class FocusedClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var calls = 0
    func reply(to prompt: String, instructions: String) async throws -> String {
        calls += 1
        return "Your BMI is 29.4. Use adult BMI guidance."
    }
}

@MainActor
private final class FocusedHealth: HealthDataProviding {
    var isAvailable = true
    var steps = 5000.0
    func requestAccess() async throws {}
    func read(window: HealthDataWindow) async -> HealthReadings {
        HealthReadings(sleep: .available(7), steps: .available(steps), exercise: .available(30),
            restingHeartRate: .available(60), restingHeartRateSampleDate: window.day.start)
    }
}
