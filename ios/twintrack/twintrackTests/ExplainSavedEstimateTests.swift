import Foundation
import XCTest
@testable import twintrack

@MainActor
final class ExplainSavedEstimateTests: XCTestCase {
    func testExactSameDayRecordDoesNotResolveLatest() throws {
        let first = record(score: 61, study: 90)
        let second = record(score: 82, study: 180, date: first.createdAt.addingTimeInterval(60))
        let chat = AssistantConversation(service: ExplanationService())
        XCTAssertTrue(chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: first.id),
            snapshot: AssistantSnapshot(history: [first, second])))
        XCTAssertEqual(chat.messages.last?.savedEstimateID, first.id)
        XCTAssertEqual(chat.messages.last?.cards.first?.prediction, first.prediction)
        XCTAssertEqual(chat.messages.last?.cards.first?.fields, AssistantSavedEstimateContext.card(for: first).fields)
        XCTAssertFalse(chat.messages.map(\.text).joined().contains(first.id.uuidString))
    }

    func testOpeningNeverCalculatesOrChangesCurrentSnapshot() {
        let saved = record()
        let counter = ExplanationCounter()
        var snapshot = AssistantSnapshot(values: [8, 9000, 40, 55, 200, 100, 95], history: [saved])
        snapshot.calculatePrediction = { counter.value += 1; return nil }
        let original = snapshot.history
        let chat = AssistantConversation(service: ExplanationService())
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: snapshot)
        XCTAssertEqual(counter.value, 0)
        XCTAssertEqual(snapshot.history, original)
        XCTAssertEqual(snapshot.values, [8, 9000, 40, 55, 200, 100, 95])
        XCTAssertEqual(chat.messages.last?.cards.first?.prediction, saved.prediction)
    }

    func testInitialExplanationWorksForEveryUnavailableModelWithoutGeneration() {
        for status in [AssistantAvailability.unsupported, .disabled, .notReady, .unavailable] {
            let service = ExplanationService()
            service.availability = status
            let saved = record()
            let chat = AssistantConversation(service: service)
            chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
            XCTAssertEqual(service.calls, 0)
            XCTAssertEqual(chat.messages.count, 2)
            XCTAssertEqual(chat.messages.last?.cards.first?.prediction, saved.prediction)
            XCTAssertFalse(chat.isGenerating)
        }
    }

    func testOneNavigationEventCreatesOnlyOneConversation() {
        let saved = record()
        let request = ExplainSavedEstimateRequest(snapshotID: saved.id)
        let chat = AssistantConversation(service: ExplanationService())
        XCTAssertTrue(chat.openExplanation(request, snapshot: AssistantSnapshot(history: [saved])))
        let messages = chat.messages
        XCTAssertFalse(chat.openExplanation(request, snapshot: AssistantSnapshot(history: [saved])))
        XCTAssertEqual(chat.conversations.count, 1)
        XCTAssertEqual(chat.messages, messages)
    }

    func testMissingIDDoesNotSubstituteAnotherRecord() {
        let chat = AssistantConversation(service: ExplanationService())
        let missing = UUID()
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: missing), snapshot: AssistantSnapshot(history: [record()]))
        XCTAssertEqual(chat.messages.last?.text, AssistantSavedEstimateContext.unavailableText)
        XCTAssertNil(chat.messages.last?.cards.first?.prediction)
        XCTAssertEqual(chat.messages.last?.savedEstimateID, missing)
    }

    func testChangedCurrentHealthAndManualValuesNeverEnterHistoricalPrompt() async throws {
        let saved = record()
        let client = ExplanationTextClient()
        let service = FoundationAssistantService(client: client)
        var current = AssistantSnapshot(values: [9.99, 987654, 123, 99, 888, 999, 98], history: [saved])
        let counter = ExplanationCounter()
        current.calculatePrediction = { counter.value += 1; return nil }
        let answer = try await service.respond(to: historicalMessages(saved, followup: "Why?"), snapshot: current)
        XCTAssertEqual(answer.cards.first?.prediction, saved.prediction)
        XCTAssertEqual(answer.savedEstimateID, saved.id)
        XCTAssertEqual(counter.value, 0)
        let prompt = try XCTUnwrap(client.prompts.first)
        XCTAssertFalse(prompt.contains("987654"))
        XCTAssertFalse(prompt.contains("9.99"))
        XCTAssertFalse(prompt.contains(saved.id.uuidString))
        XCTAssertTrue(prompt.contains("recordedInputs"))
        XCTAssertFalse(prompt.contains("dateOfBirth"))
    }

    func testGroundedQualitativeFollowupIsKeptWithoutRepeatingInitialExplanation() async throws {
        let saved = record()
        let client = ExplanationTextClient()
        let service = FoundationAssistantService(client: client)
        let answer = try await service.respond(to: historicalMessages(saved, followup: "What do these inputs mean?"),
            snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertEqual(answer.text, client.text)
        XCTAssertNotEqual(answer.text, AssistantSavedEstimateContext.introduction)
        XCTAssertEqual(answer.cards.first?.prediction, saved.prediction)
    }

    func testInventedNumbersAndCausalOutputAreRejected() async throws {
        let saved = record()
        for generated in ["Your saved score is 99.9.", "Your saved score is ninety.",
                          "Your result was lower because you slept less.", "Your current BMI is healthy."] {
            let client = ExplanationTextClient()
            client.text = generated
            let answer = try await FoundationAssistantService(client: client).respond(
                to: historicalMessages(saved, followup: "Why?"), snapshot: AssistantSnapshot(history: [saved]))
            XCTAssertNotEqual(answer.text, generated)
            XCTAssertEqual(answer.text, AssistantSavedEstimateContext.fallback(for: "Why?"))
            XCTAssertEqual(answer.cards.first?.prediction, saved.prediction)
        }
    }

    func testDeletedRecordRecheckedBeforePublishingModelResponse() async throws {
        let saved = record()
        let records = ExplanationRecords([saved])
        let client = ExplanationTextClient()
        client.beforeReturn = { records.values = [] }
        var snapshot = AssistantSnapshot(history: [saved, record(score: 90)])
        snapshot.lookupSavedEstimate = { id in records.values.first { $0.id == id } }
        let answer = try await FoundationAssistantService(client: client).respond(
            to: historicalMessages(saved, followup: "Why?"), snapshot: snapshot)
        XCTAssertEqual(answer.text, AssistantSavedEstimateContext.unavailableText)
        XCTAssertNil(answer.cards.first?.prediction)
    }

    func testReopenedChatUsesExactIDAndFreshAvailabilityLookup() async throws {
        let saved = record()
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: ExplanationService(), store: store)
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        let id = try XCTUnwrap(chat.activeID)
        let client = ExplanationTextClient()
        let restored = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        restored.open(id)
        XCTAssertEqual(restored.messages.last?.savedEstimateID, saved.id)
        restored.send("Explain why.", snapshot: AssistantSnapshot(history: [saved, record(score: 91)]))
        await finish(restored)
        XCTAssertEqual(restored.messages.last?.cards.first?.prediction, saved.prediction)
        restored.send("Why?", snapshot: AssistantSnapshot(history: [record(score: 93)]))
        await finish(restored)
        XCTAssertEqual(restored.messages.last?.text, AssistantSavedEstimateContext.unavailableText)
    }

    func testExplicitCurrentQuestionLeavesHistoricalContext() async throws {
        let saved = record(score: 61)
        let current = currentSnapshot(history: [saved])
        let client = ExplanationTextClient()
        let service = FoundationAssistantService(client: client)
        let answer = try await service.respond(to: historicalMessages(saved, followup: "What is my score now?"), snapshot: current)
        XCTAssertNil(answer.savedEstimateID)
        XCTAssertTrue(answer.text.contains("current TwinTrack inputs now"))
        XCTAssertEqual(answer.cards.first?.prediction, current.lastPrediction?.prediction)
        XCTAssertEqual(client.prompts.count, 0)
    }

    func testWhatIfAfterHistoricalExplanationUsesCurrentBaselineWithoutSaving() async throws {
        let saved = record(score: 61, study: 20)
        let current = currentSnapshot(history: [saved])
        let answer = try await FoundationAssistantService(client: ExplanationTextClient()).respond(
            to: historicalMessages(saved, followup: "Increase study by 30 minutes."), snapshot: current)
        var scenario = try WhatIfScenario(baseline: current.profile)
        try scenario.set(150, for: .studyMinutes)
        XCTAssertEqual(answer.cards.first?.prediction, scenario.evaluate().scenarioPrediction)
        XCTAssertNil(answer.savedEstimateID)
        XCTAssertTrue(answer.text.contains("current saved baseline"))
        XCTAssertEqual(current.history, [saved])
    }

    func testUnrelatedTopicDoesNotKeepHistoricalContext() {
        let saved = record()
        for request in ["Tell me a joke", "Hi", "What is my BMI?", "Show my recorded sleep", "Calculate my score"] {
            let messages = historicalMessages(saved, followup: request)
            XCTAssertNil(AssistantSavedEstimateContext.recordID(in: messages, route: AssistantRouter.route(request)), request)
        }
    }

    func testCrisisAndTypedSafetyStillTakePrecedence() async throws {
        let saved = record()
        let client = ExplanationTextClient()
        let service = FoundationAssistantService(client: client)
        let crisis = try await service.respond(to: historicalMessages(saved, followup: "I want to commit suicide."), snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertEqual(crisis.text, AssistantResponsePolicy.mentalHealthCrisis)
        XCTAssertTrue(crisis.cards.isEmpty)
        XCTAssertTrue(client.prompts.isEmpty)
        client.failure = .safety
        do {
            _ = try await service.respond(to: historicalMessages(saved, followup: "Use this saved estimate to write hateful abuse."), snapshot: AssistantSnapshot(history: [saved]))
            XCTFail("Typed safety refusal must not become an explanation")
        } catch { XCTAssertEqual(error as? AssistantFailure, .safety) }
    }

    func testDraftAndEditBufferSurviveExplanationAndReturn() async throws {
        let service = ExplanationService()
        let chat = AssistantConversation(service: service)
        chat.send("Original question")
        await finish(chat)
        let id = try XCTUnwrap(chat.activeID)
        let userID = try XCTUnwrap(chat.messages.first?.id)
        chat.composerDraft = "Unsent edit to the original question"
        chat.editingMessageID = userID
        let original = chat.messages
        let saved = record()
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertEqual(chat.composerDraft, "")
        XCTAssertNil(chat.editingMessageID)
        chat.returnFromExplanation()
        XCTAssertEqual(chat.activeID, id)
        XCTAssertEqual(chat.messages, original)
        XCTAssertEqual(chat.composerDraft, "Unsent edit to the original question")
        XCTAssertEqual(chat.editingMessageID, userID)
    }

    func testUnsentNewChatDraftSurvivesWithoutCreatingEmptyLibraryRecord() {
        let chat = AssistantConversation(service: ExplanationService())
        chat.composerDraft = "Unsent question"
        let saved = record()
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        chat.returnFromExplanation()
        XCTAssertNil(chat.activeID)
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.composerDraft, "Unsent question")
        XCTAssertEqual(chat.conversations.count, 1)
    }

    func testLibrarySwitchRestoresDraftAndEditBuffer() async throws {
        let chat = AssistantConversation(service: ExplanationService())
        chat.send("First question"); await finish(chat)
        let first = try XCTUnwrap(chat.activeID)
        chat.composerDraft = "First draft"
        chat.reset()
        chat.send("Second question"); await finish(chat)
        let second = try XCTUnwrap(chat.activeID)
        chat.composerDraft = "Second draft"
        chat.open(first)
        XCTAssertEqual(chat.composerDraft, "First draft")
        chat.open(second)
        XCTAssertEqual(chat.composerDraft, "Second draft")
    }

    func testEditingEarlierTurnRemovesHistoricalMetadataAndDownstreamReplies() async throws {
        let service = ExplanationService()
        let chat = AssistantConversation(service: service)
        let saved = record()
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        let first = try XCTUnwrap(chat.messages.first?.id)
        XCTAssertTrue(chat.editUserMessage(first, to: "Tell me a joke", snapshot: AssistantSnapshot(history: [saved])))
        await finish(chat)
        XCTAssertEqual(chat.messages.count, 2)
        XCTAssertTrue(chat.messages.allSatisfy { $0.savedEstimateID == nil })
        XCTAssertTrue(service.lastMessages.allSatisfy { $0.savedEstimateID == nil && $0.cards.isEmpty })
    }

    func testStopRejectsLateOutputAndPreservesNewerDraft() async throws {
        let service = ExplanationService()
        let chat = AssistantConversation(service: service)
        let saved = record()
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        service.hold = true
        chat.send("Why?", snapshot: AssistantSnapshot(history: [saved]))
        let pending = try await waitForPending(service)
        chat.composerDraft = "Newer unsent text"
        chat.cancel()
        pending.resume(returning: AssistantSavedEstimateContext.answer(for: saved, text: "Late answer"))
        await drain()
        XCTAssertEqual(chat.messages.count, 3)
        XCTAssertEqual(chat.composerDraft, "Newer unsent text")
        XCTAssertTrue(chat.wasCancelled)
    }

    func testSwitchingToExplanationRejectsPreviousLateCallback() async throws {
        let service = ExplanationService()
        service.hold = true
        let chat = AssistantConversation(service: service)
        chat.send("Slow question")
        let pending = try await waitForPending(service)
        let saved = record()
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        let expected = chat.messages
        pending.resume(returning: AssistantAnswer(text: "Late output from old chat"))
        await drain()
        XCTAssertEqual(chat.messages, expected)
    }

    func testLateServiceResponseCannotPublishDeletedRecord() async throws {
        let saved = record()
        let records = ExplanationRecords([saved])
        var snapshot = AssistantSnapshot(history: [saved])
        snapshot.lookupSavedEstimate = { id in records.values.first { $0.id == id } }
        let service = ExplanationService()
        let chat = AssistantConversation(service: service)
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: snapshot)
        service.hold = true
        chat.send("Why?", snapshot: snapshot)
        let pending = try await waitForPending(service)
        records.values = []
        pending.resume(returning: AssistantSavedEstimateContext.answer(for: saved))
        await finish(chat)
        XCTAssertEqual(chat.messages.last?.text, AssistantSavedEstimateContext.unavailableText)
        XCTAssertNil(chat.messages.last?.cards.first?.prediction)
    }

    func testLegacyArchiveStillDecodesAndInternalIDIsNotExported() throws {
        let old = AssistantMessage(role: .user, text: "An old ordinary question")
        let encoded = try JSONEncoder().encode(old)
        XCTAssertFalse(String(decoding: encoded, as: UTF8.self).contains("savedEstimateID"))
        XCTAssertNil(try JSONDecoder().decode(AssistantMessage.self, from: encoded).savedEstimateID)
        let saved = record()
        let chat = AssistantConversation(service: ExplanationService())
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        let data = try JSONEncoder().encode(FileConversationStore.Archive(version: 1, conversations: chat.conversations))
        let decoded = try JSONDecoder().decode(FileConversationStore.Archive.self, from: data)
        XCTAssertEqual(decoded.conversations.first?.messages.last?.savedEstimateID, saved.id)
        let exported = ChatExport(title: nil, messages: chat.messages).text
        XCTAssertFalse(exported.contains(saved.id.uuidString))
        XCTAssertFalse(exported.contains("savedEstimateID"))
        XCTAssertTrue(exported.contains(HomeDisplay.prediction(saved.prediction)))
    }

    func testReopenedInterruptedHistoricalRetryKeepsExactRecord() async throws {
        let saved = record()
        let store = MemoryConversationStore()
        let held = ExplanationService()
        let chat = AssistantConversation(service: held, store: store)
        chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved]))
        let id = try XCTUnwrap(chat.activeID)
        held.hold = true
        chat.send("Why?", snapshot: AssistantSnapshot(history: [saved]))
        let pending = try await waitForPending(held)
        chat.cancel()
        pending.resume(returning: AssistantAnswer(text: "Ignored"))
        await drain()
        let client = ExplanationTextClient()
        client.availability = .notReady
        let restored = AssistantConversation(service: FoundationAssistantService(client: client), store: store)
        restored.open(id)
        XCTAssertTrue(restored.needsFreshRetry)
        XCTAssertTrue(restored.retryUsesSavedEstimate)
        restored.retryWithCurrentInputs(AssistantSnapshot(history: [saved, record(score: 99)]))
        await finish(restored)
        XCTAssertEqual(restored.messages.last?.cards.first?.prediction, saved.prediction)
        XCTAssertEqual(restored.messages.last?.savedEstimateID, saved.id)
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testSelectedContextIncludesStoredSourceMetadataWithoutCurrentData() throws {
        let context = V2PredictionContext.fixture()
        let window = HealthDataWindow(now: Date(), calendar: .current)
        let base = record()
        let saved = PredictionSnapshot(createdAt: base.createdAt, prediction: base.prediction, inputs: base.inputs,
            healthWindow: PredictionHealthWindow(window, restingHeartRateSampleDate: window.day.start),
            provenance: TwinTrackModel.provenance, modelVersion: TwinTrackModel.version, predictionContext: context)
        let card = AssistantSavedEstimateContext.card(for: saved)
        XCTAssertEqual(card.fields.filter { $0.label == "Assessment" }.first?.value, context.summary)
        XCTAssertEqual(card.fields.filter { $0.label == "Model" }.first?.value, saved.modelLabel)
        XCTAssertTrue(card.fields.contains { $0.label == "Sleep source period" })
        XCTAssertTrue(card.fields.contains { $0.label == "Resting Heart Rate sample" })
        XCTAssertEqual(card.fields.filter { $0.label == "Source time zone" }.first?.value, window.timeZone.identifier)
        XCTAssertFalse(card.fields.contains { $0.label.contains("BMI") || $0.label.contains("birth") })
    }

    func testRepeatedOrInventedPersonalNarrativeUsesBoundedFallback() async throws {
        let saved = record()
        for generated in [AssistantSavedEstimateContext.introduction, "I went for a walk after looking at your saved result."] {
            let client = ExplanationTextClient()
            client.text = generated
            let answer = try await FoundationAssistantService(client: client).respond(
                to: historicalMessages(saved, followup: "Why?"), snapshot: AssistantSnapshot(history: [saved]))
            XCTAssertEqual(answer.text, AssistantSavedEstimateContext.fallback(for: "Why?"))
            XCTAssertEqual(answer.cards.first?.prediction, saved.prediction)
        }
    }

    func testExplanationDuringDeferredLoadPreservesPriorConversationAndDraft() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ExplainLibraryTests-\(UUID())", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileConversationStore(directory: directory)
        let existing = SavedConversation(id: UUID(), title: "Earlier saved chat", createdAt: Date(), updatedAt: Date(),
            messages: [AssistantMessage(role: .user, text: "Earlier synthetic message")], completion: .idle)
        try store.save([existing])
        let chat = AssistantConversation(service: ExplanationService(), store: store, deferFileLoad: true)
        chat.send("Accepted before library load completed")
        let firstID = try XCTUnwrap(chat.activeID)
        chat.composerDraft = "Keep this newer draft"
        let saved = record()
        XCTAssertTrue(chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved])))
        for _ in 0..<5000 {
            if (try? store.load().count) == 3 { break }
            await Task.yield()
        }
        let restored = try store.load()
        XCTAssertEqual(restored.count, 3)
        XCTAssertTrue(restored.contains { $0.id == existing.id })
        XCTAssertEqual(restored.first { $0.id == firstID }?.messages.first?.text, "Accepted before library load completed")
        chat.returnFromExplanation()
        XCTAssertEqual(chat.activeID, firstID)
        XCTAssertEqual(chat.composerDraft, "Keep this newer draft")
    }

    func testExplanationSaveFailureKeepsPreviousChatAndDraftVisible() async throws {
        let store = ExplanationFailingStore()
        let chat = AssistantConversation(service: ExplanationService(), store: store)
        chat.send("Existing conversation"); await finish(chat)
        let original = chat.messages, id = chat.activeID
        chat.composerDraft = "Important unsent draft"
        store.rejectSave = true
        let saved = record()
        XCTAssertFalse(chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved])))
        XCTAssertEqual(chat.activeID, id)
        XCTAssertEqual(chat.messages, original)
        XCTAssertEqual(chat.composerDraft, "Important unsent draft")
        XCTAssertEqual(chat.conversations.count, 1)
        XCTAssertNotNil(chat.storageIssue)
    }

    func testUnreadableLibraryBlocksExplanationEvenWithEmptyActiveChat() {
        let store = ExplanationFailingStore()
        store.rejectLoad = true
        let chat = AssistantConversation(service: ExplanationService(), store: store)
        chat.composerDraft = "Keep the unsent draft"
        let saved = record()
        XCTAssertFalse(chat.openExplanation(ExplainSavedEstimateRequest(snapshotID: saved.id), snapshot: AssistantSnapshot(history: [saved])))
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.composerDraft, "Keep the unsent draft")
        XCTAssertTrue(store.records.isEmpty)
    }

    func testExplicitSavedMetricReferencesOverrideBroadCurrentReadMatching() async throws {
        let selected = record(score: 61, study: 90)
        let current = currentSnapshot(history: [selected, record(score: 92, study: 180)])
        for request in ["What was my sleep in that saved estimate?", "What was my score in that saved estimate?",
                        "Show my recorded sleep in this saved result", "What were my steps for that run?",
                        "What was my study time in that saved prediction?"] {
            let messages = historicalMessages(selected, followup: request)
            XCTAssertEqual(AssistantSavedEstimateContext.recordID(in: messages, route: AssistantRouter.route(request)), selected.id, request)
            let answer = try await FoundationAssistantService(client: ExplanationTextClient()).respond(to: messages, snapshot: current)
            XCTAssertEqual(answer.savedEstimateID, selected.id, request)
            XCTAssertEqual(answer.cards.first?.prediction, selected.prediction, request)
            XCTAssertEqual(answer.cards.first?.fields, AssistantSavedEstimateContext.card(for: selected).fields, request)
            XCTAssertFalse(answer.text.contains("current TwinTrack inputs now"), request)
        }
    }

    func testTodayCanDateTheSelectedSavedRecordWithoutSwitchingToCurrentInputs() async throws {
        let today = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600)
        let selected = record(score: 61, study: 90, date: today)
        let later = record(score: 92, study: 180, date: today.addingTimeInterval(60))
        let current = currentSnapshot(history: [selected, later])
        for request in ["What was my sleep in today’s saved estimate?", "What was my score in today's saved estimate?"] {
            let messages = historicalMessages(selected, followup: request)
            XCTAssertEqual(AssistantSavedEstimateContext.recordID(in: messages, route: AssistantRouter.route(request)), selected.id)
            let answer = try await FoundationAssistantService(client: ExplanationTextClient()).respond(to: messages, snapshot: current)
            XCTAssertEqual(answer.savedEstimateID, selected.id)
            XCTAssertEqual(answer.cards.first?.prediction, selected.prediction)
            XCTAssertEqual(answer.cards.first?.fields, AssistantSavedEstimateContext.card(for: selected).fields)
        }
        for request in ["What is my sleep today?", "What is my score now compared with today's saved estimate?",
                        "Show my current score rather than today's saved estimate", "Show my latest prediction today"] {
            XCTAssertNil(AssistantSavedEstimateContext.recordID(in: historicalMessages(selected, followup: request),
                route: AssistantRouter.route(request)), request)
        }
    }

    func testExplicitCurrentAndLatestRequestsEndSelectedRecordInheritance() async throws {
        let selected = record(score: 61)
        let later = record(score: 92, date: selected.createdAt.addingTimeInterval(60))
        let current = currentSnapshot(history: [selected, later])
        for request in ["What is my score now?", "Show my sleep now rather than that saved estimate",
                        "Show my latest prediction instead of that saved estimate"] {
            let messages = historicalMessages(selected, followup: request)
            XCTAssertNil(AssistantSavedEstimateContext.recordID(in: messages, route: AssistantRouter.route(request)), request)
            let answer = try await FoundationAssistantService(client: ExplanationTextClient()).respond(to: messages, snapshot: current)
            XCTAssertNil(answer.savedEstimateID, request)
            if request.contains("latest") { XCTAssertEqual(answer.cards.first?.prediction, later.prediction) }
            else { XCTAssertEqual(answer.cards.first?.prediction, current.lastPrediction?.prediction) }
        }
        for request in ["Calculate my score", "Increase study by 30 minutes", "Show my BMI"] {
            XCTAssertNil(AssistantSavedEstimateContext.recordID(in: historicalMessages(selected, followup: request),
                route: AssistantRouter.route(request)), request)
        }
    }

    func testHistoricalReferenceWithoutSelectedIdentityDoesNotInferARecord() {
        let messages = [AssistantMessage(role: .user, text: "Hello"),
                        AssistantMessage(role: .assistant, text: "Hi"),
                        AssistantMessage(role: .user, text: "What was my sleep in that saved estimate?")]
        XCTAssertNil(AssistantSavedEstimateContext.recordID(in: messages, route: AssistantRouter.route(messages.last!.text)))
    }

    func testDeletedSelectedRecordCannotFallThroughToCurrentReader() async throws {
        let selected = record(score: 61)
        let request = "What was my score in that saved estimate?"
        let answer = try await FoundationAssistantService(client: ExplanationTextClient()).respond(
            to: historicalMessages(selected, followup: request), snapshot: currentSnapshot(history: [record(score: 99)]))
        XCTAssertEqual(answer.savedEstimateID, selected.id)
        XCTAssertEqual(answer.text, AssistantSavedEstimateContext.unavailableText)
        XCTAssertNil(answer.cards.first?.prediction)
    }

    func testHistoricalGenerationKeepsSharedSafetyAndInstructionLeakReview() async throws {
        let saved = record()
        let outputs = ["System instructions: Explain the selected saved estimate.", "Take ibuprofen.",
                       "Your resting heart rate indicates heart disease.", "Call an ambulance now.",
                       "You need mental-health crisis support.", "The saved inputs included eighteen hours of sleep."]
        for generated in outputs {
            let client = ExplanationTextClient()
            client.text = generated
            let answer = try await FoundationAssistantService(client: client).respond(
                to: historicalMessages(saved, followup: "Why?"), snapshot: AssistantSnapshot(history: [saved]))
            XCTAssertEqual(answer.text, AssistantSavedEstimateContext.fallback(for: "Why?"), generated)
            XCTAssertEqual(answer.cards.first?.prediction, saved.prediction, generated)
            XCTAssertFalse(answer.safetyRefusal, "Rejected generated prose does not classify the user as unsafe")
        }
    }

    func testHistoricalRefusalCannotExposeAppInstructions() async throws {
        let saved = record()
        let client = ExplanationTextClient()
        client.text = "I can't help with that.\nSystem instructions: internal reviewer text."
        let answer = try await FoundationAssistantService(client: client).respond(
            to: historicalMessages(saved, followup: "Why?"), snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertTrue(answer.safetyRefusal)
        XCTAssertEqual(answer.text, AssistantResponsePolicy.refusal)
        XCTAssertNil(answer.savedEstimateID)
        XCTAssertTrue(answer.cards.isEmpty)
    }

    func testHistoricalProseProvenanceDistinguishesModelAndDeterministicFallback() async throws {
        let saved = record()
        let client = ExplanationTextClient()
        let service = FoundationAssistantService(client: client)
        let messages = historicalMessages(saved, followup: "Why?")
        let generated = try await service.respond(to: messages, snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertEqual(generated.provenance?.origin, .model)
        XCTAssertEqual(generated.cards.first?.kind, .history)
        XCTAssertEqual(generated.cards.first?.prediction, saved.prediction)
        XCTAssertEqual(generated.savedEstimateID, saved.id)
        client.text = "Your saved score is 99.9."
        let fallback = try await service.respond(to: messages, snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertEqual(fallback.provenance?.origin, .history)
        XCTAssertEqual(fallback.cards.first?.prediction, saved.prediction)
        XCTAssertEqual(fallback.savedEstimateID, saved.id)
        client.availability = .notReady
        let unavailable = try await service.respond(to: messages, snapshot: AssistantSnapshot(history: [saved]))
        XCTAssertEqual(unavailable.provenance?.origin, .history)
        XCTAssertEqual(unavailable.cards.first?.prediction, saved.prediction)
    }

    private func record(score: Double = 73, study: Double = 120, date: Date = Date(timeIntervalSince1970: 1_785_000_000)) -> PredictionSnapshot {
        PredictionSnapshot(createdAt: date, prediction: score,
            inputs: PredictionInputs(profile: TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30,
                restingHeartRate: 60, studyMinutes: study, screenTimeMinutes: 240, previousScore: 75)),
            healthWindow: nil)
    }

    private func historicalMessages(_ saved: PredictionSnapshot, followup: String) -> [AssistantMessage] {
        var question = AssistantMessage(role: .user, text: AssistantSavedEstimateContext.openingRequest)
        question.savedEstimateID = saved.id
        var answer = AssistantMessage(role: .assistant, text: AssistantSavedEstimateContext.introduction,
            cards: [AssistantSavedEstimateContext.card(for: saved)])
        answer.savedEstimateID = saved.id
        answer.provenance = AssistantProvenance(.history)
        return [question, answer, AssistantMessage(role: .user, text: followup)]
    }

    private func currentSnapshot(history: [PredictionSnapshot]) -> AssistantSnapshot {
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60,
                                       studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let context = V2PredictionContext.fixture()
        let current = PredictionSnapshot.realBaseline(profile: profile, createdAt: Date(), healthWindow: nil,
            provenance: TwinTrackModel.provenance, predictionContext: context)
        return AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75], history: history,
            predictionStatus: .fresh, lastPrediction: current, predictionContext: context)
    }

    private func finish(_ chat: AssistantConversation) async {
        for _ in 0..<200 where chat.isGenerating { await Task.yield() }
        XCTAssertFalse(chat.isGenerating)
    }

    private func drain() async { for _ in 0..<50 { await Task.yield() } }

    private func waitForPending(_ service: ExplanationService) async throws -> CheckedContinuation<AssistantAnswer, Error> {
        for _ in 0..<200 where service.pending == nil { await Task.yield() }
        return try XCTUnwrap(service.pending)
    }
}

@MainActor private final class ExplanationTextClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var text = "The estimate summarizes the model's recorded inputs. It is distinct from your actual assessment result and does not establish a causal explanation."
    var prompts: [String] = []
    var failure: AssistantFailure?
    var beforeReturn: (() -> Void)?
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt)
        if let failure { throw failure }
        beforeReturn?()
        return text
    }
}

@MainActor private final class ExplanationService: AssistantResponding {
    var availability = AssistantAvailability.available
    var calls = 0
    var hold = false
    var lastMessages: [AssistantMessage] = []
    var pending: CheckedContinuation<AssistantAnswer, Error>?
    func respond(to messages: [AssistantMessage], snapshot: AssistantSnapshot) async throws -> AssistantAnswer {
        calls += 1
        lastMessages = messages
        if hold { return try await withCheckedThrowingContinuation { pending = $0 } }
        return AssistantAnswer(text: "A normal synthetic reply")
    }
}

@MainActor private final class ExplanationRecords {
    var values: [PredictionSnapshot]
    init(_ values: [PredictionSnapshot]) { self.values = values }
}

@MainActor private final class ExplanationCounter { var value = 0 }

@MainActor private final class ExplanationFailingStore: ConversationPersisting {
    var records: [SavedConversation] = []
    var rejectSave = false
    var rejectLoad = false
    func load() throws -> [SavedConversation] {
        if rejectLoad { throw ConversationStorageError.invalidData }
        return records
    }
    func save(_ conversations: [SavedConversation]) throws {
        if rejectSave { throw ConversationStorageError.invalidData }
        records = conversations
    }
}
