import Foundation
import XCTest
@testable import twintrack

@MainActor
final class ChatLibraryTests: XCTestCase {
    func testNewChatDoesNotAccumulateEmptyRecords() async {
        let chat = AssistantConversation(service: LibraryService())
        for _ in 0..<5 { chat.reset(); chat.send(" \n ") }
        XCTAssertTrue(chat.conversations.isEmpty)
        XCTAssertNil(chat.activeID)
        chat.send("  Study plan\nfor tomorrow  ")
        await finish(chat)
        XCTAssertEqual(chat.conversations.count, 1)
        XCTAssertEqual(chat.conversations.first?.title, "Study plan for tomorrow")
        chat.reset()
        XCTAssertNil(chat.activeID)
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.conversations.count, 1)
    }

    func testSaveAndReopenPreservesMessageIDsDatesAndCards() async throws {
        let store = MemoryConversationStore()
        let service = LibraryService()
        service.cards = [card(.current), card(.scenario)]
        let chat = AssistantConversation(service: service, store: store)
        chat.send("Synthetic study question")
        await finish(chat)
        let original = chat.messages
        let id = try XCTUnwrap(chat.activeID)
        chat.reset()
        chat.open(id)
        XCTAssertTrue(chat.reopened)
        XCTAssertEqual(chat.messages, original)
        XCTAssertEqual(chat.messages.last?.cards.count, 2)
        XCTAssertTrue(service.snapshots.count == 1, "Opening must never generate or run a tool.")
    }

    func testRenamePersistsAndRejectsBlankTitle() async throws {
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: LibraryService(), store: store)
        chat.send("First meaningful question")
        await finish(chat)
        let id = try XCTUnwrap(chat.activeID)
        XCTAssertFalse(chat.rename(id, to: " \n "))
        XCTAssertTrue(chat.rename(id, to: "  Revision plan  "))
        let restored = AssistantConversation(service: LibraryService(), store: store)
        XCTAssertEqual(restored.conversations.first?.title, "Revision plan")
        chat.send("Follow up")
        await finish(chat)
        XCTAssertEqual(chat.conversations.first?.title, "Revision plan")
    }

    func testDeleteRemovesOnlyChosenChatAcrossReload() async throws {
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: LibraryService(), store: store)
        chat.send("One"); await finish(chat)
        let first = try XCTUnwrap(chat.activeID)
        chat.reset()
        chat.send("Two"); await finish(chat)
        let second = try XCTUnwrap(chat.activeID)
        XCTAssertTrue(chat.delete(first))
        XCTAssertEqual(chat.activeID, second)
        XCTAssertEqual(chat.conversations.map(\.id), [second])
        XCTAssertTrue(chat.delete(second))
        XCTAssertNil(chat.activeID)
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertTrue(try store.load().isEmpty)
    }

    func testFilePersistenceAcrossConversationRelaunch() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = AssistantConversation(service: LibraryService(), store: FileConversationStore(directory: directory))
        first.send("Synthetic disk persistence")
        await finish(first)
        let id = try XCTUnwrap(first.activeID)
        let saved = first.messages
        let relaunched = AssistantConversation(service: LibraryService(), store: FileConversationStore(directory: directory))
        relaunched.open(id)
        XCTAssertEqual(relaunched.messages, saved)
        XCTAssertEqual(relaunched.conversations, first.conversations)
        XCTAssertNil(relaunched.storageIssue)
    }

    func testDeferredFileLoadKeepsNewConversationAndExistingLibrary() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileConversationStore(directory: directory)
        let existing = saved()
        try store.save([existing])

        let chat = AssistantConversation(service: LibraryService(), store: store, deferFileLoad: true)
        chat.send("Synthetic message sent while the library loads")
        await finish(chat)
        for _ in 0..<5000 {
            if chat.conversations.count == 2 { break }
            await Task.yield()
        }

        XCTAssertEqual(chat.conversations.count, 2)
        XCTAssertTrue(chat.conversations.contains { $0.id == existing.id })
        XCTAssertTrue(chat.conversations.contains { $0.id == chat.activeID })
        XCTAssertEqual(try store.load().count, 2)
        XCTAssertNil(chat.storageIssue)
    }

    func testVersionOneRoundTripAndProtectedBackupExcludedFile() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileConversationStore(directory: directory)
        let record = saved()
        try store.save([record])
        XCTAssertEqual(try store.load(), [record])
        let file = directory.appendingPathComponent("conversations.json")
        let archive = try JSONDecoder().decode(FileConversationStore.Archive.self, from: Data(contentsOf: file))
        XCTAssertEqual(archive.version, 1)
        XCTAssertEqual(try file.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
#if targetEnvironment(simulator)
        // Simulator can omit protection metadata; it cannot prove at-rest encryption.
        if let protection = attributes[.protectionKey] as? FileProtectionType {
            XCTAssertEqual(protection, .complete)
        }
#else
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
#endif
        try store.save([])
        XCTAssertTrue(try store.load().isEmpty)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["conversations.json"])
    }

    func testUnknownVersionIsNotReplaced() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("conversations.json")
        let data = try JSONEncoder().encode(FileConversationStore.Archive(version: 2, conversations: [saved()]))
        try data.write(to: file)
        let chat = AssistantConversation(service: LibraryService(), store: FileConversationStore(directory: directory))
        XCTAssertNotNil(chat.storageIssue)
        chat.send("Synthetic unsaved conversation"); await finish(chat)
        XCTAssertEqual(try Data(contentsOf: file), data)
        chat.reset()
        XCTAssertFalse(chat.messages.isEmpty)
    }

    func testCorruptLibraryIsNotOverwrittenAndCanRecover() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("conversations.json")
        let corrupt = Data("invalid synthetic archive".utf8)
        try corrupt.write(to: file)
        let store = FileConversationStore(directory: directory)
        let chat = AssistantConversation(service: LibraryService(), store: store)
        chat.send("Keep this unsaved chat"); await finish(chat)
        XCTAssertNotNil(chat.storageIssue)
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
        // Simulate an externally restored valid file, never delete it on load failure.
        try store.save([])
        chat.retryStorage()
        XCTAssertNil(chat.storageIssue)
        XCTAssertEqual(try store.load().first?.messages, chat.messages)
    }

    func testDuplicateIDsAndEmptyChatsFailDecoding() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("conversations.json")
        let record = saved()
        var empty = record
        empty.messages = []
        for records in [[record, record], [empty]] {
            try JSONEncoder().encode(FileConversationStore.Archive(version: 1, conversations: records)).write(to: file)
            XCTAssertThrowsError(try FileConversationStore(directory: directory).load())
        }
    }

    func testWriteFailurePreservesOpenConversationUntilRetry() async throws {
        let store = FailingLibraryStore()
        let chat = AssistantConversation(service: LibraryService(), store: store)
        chat.send("Saved first"); await finish(chat)
        let first = try XCTUnwrap(chat.activeID)
        chat.reset()
        store.fails = true
        chat.send("Unsaved second"); await finish(chat)
        let unsaved = chat.messages
        let second = chat.activeID
        chat.reset()
        chat.open(first)
        XCTAssertEqual(chat.activeID, second)
        XCTAssertEqual(chat.messages, unsaved)
        XCTAssertFalse(chat.rename(first, to: "Do not mask unsaved changes"))
        XCTAssertFalse(chat.delete(first))
        XCTAssertNotNil(chat.storageIssue)
        store.fails = false
        chat.retryStorage()
        XCTAssertNil(chat.storageIssue)
        XCTAssertEqual(store.records.count, 2)
        chat.reset()
        XCTAssertTrue(chat.messages.isEmpty)
    }

    func testDeletedChatRejectsLateGeneratedOutput() async throws {
        let service = LibraryService()
        service.hold = true
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: service, store: store)
        chat.send("Slow synthetic request")
        let pending = try await pending(service)
        let id = try XCTUnwrap(chat.activeID)
        XCTAssertTrue(chat.delete(id))
        pending.resume(returning: AssistantAnswer(text: "Late output"))
        await drain()
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertTrue(store.conversations.isEmpty)
        XCTAssertNil(chat.activeID)
    }

    func testNewChatRejectsPreviousLateOutputAndIsolatesTranscript() async throws {
        let service = LibraryService()
        service.hold = true
        let chat = AssistantConversation(service: service)
        chat.send("Old question")
        let pending = try await pending(service)
        let old = try XCTUnwrap(chat.activeID)
        chat.reset()
        chat.send("New question"); await finish(chat)
        let current = chat.messages
        pending.resume(returning: AssistantAnswer(text: "Old late answer"))
        await drain()
        XCTAssertEqual(chat.messages, current)
        XCTAssertEqual(service.transcripts.last?.map(\.text), ["New question"])
        XCTAssertNotEqual(chat.activeID, old)
        XCTAssertEqual(chat.conversations.first(where: { $0.id == old })?.messages.count, 1)
    }

    func testEditLatestUserMessageReplacesItAndRegenerates() async throws {
        let service = LibraryService()
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: service, store: store)
        chat.send("What is 2+2?"); await finish(chat)
        let originalAnswerID = try XCTUnwrap(chat.messages.last?.id)
        let userID = try XCTUnwrap(chat.messages.first?.id)

        XCTAssertTrue(chat.editUserMessage(userID, to: "What is 3+3?"))
        await finish(chat)

        XCTAssertEqual(chat.messages.map(\.text), ["What is 3+3?", "Synthetic library response"])
        XCTAssertNotEqual(chat.messages.last?.id, originalAnswerID)
        XCTAssertEqual(service.transcripts.last?.map(\.text), ["What is 3+3?"])
        XCTAssertEqual(store.conversations.first?.messages, chat.messages)
    }

    func testEditEarlierUserMessageRemovesAllLaterTurnsBeforeRegenerating() async throws {
        let service = LibraryService()
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: service, store: store)
        chat.send("What is 2+2?"); await finish(chat)
        let firstUserID = try XCTUnwrap(chat.messages.first?.id)
        chat.send("Why?"); await finish(chat)
        XCTAssertEqual(chat.messages.count, 4)

        XCTAssertTrue(chat.editUserMessage(firstUserID, to: "What is 3+3?"))
        await finish(chat)

        XCTAssertEqual(chat.messages.map(\.text), ["What is 3+3?", "Synthetic library response"])
        XCTAssertEqual(service.transcripts.last?.map(\.text), ["What is 3+3?"])
        XCTAssertFalse(chat.messages.contains { $0.text == "Why?" })
        XCTAssertEqual(store.conversations.first?.messages, chat.messages)
    }

    func testRejectedEditLeavesConversationUnchanged() async throws {
        let service = LibraryService()
        let chat = AssistantConversation(service: service)
        chat.send("Original question"); await finish(chat)
        let original = chat.messages
        let assistantID = try XCTUnwrap(chat.messages.last?.id)

        XCTAssertFalse(chat.editUserMessage(assistantID, to: "Attempted assistant edit"))
        XCTAssertFalse(chat.editUserMessage(try XCTUnwrap(chat.messages.first?.id), to: "  \n "))
        XCTAssertEqual(chat.messages, original)
        XCTAssertEqual(service.transcripts.count, 1)
    }

    func testEditedConversationPersistsWithoutResurrectingDownstreamTurns() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileConversationStore(directory: directory)
        let service = LibraryService()
        let chat = AssistantConversation(service: service, store: store)
        chat.send("First version"); await finish(chat)
        let firstUserID = try XCTUnwrap(chat.messages.first?.id)
        chat.send("Downstream follow-up"); await finish(chat)
        let id = try XCTUnwrap(chat.activeID)

        XCTAssertTrue(chat.editUserMessage(firstUserID, to: "Edited version"))
        await finish(chat)
        let edited = chat.messages
        XCTAssertEqual(edited.map(\.text), ["Edited version", "Synthetic library response"])

        let reopened = AssistantConversation(service: LibraryService(), store: FileConversationStore(directory: directory))
        reopened.open(id)
        XCTAssertEqual(reopened.messages, edited)
        XCTAssertFalse(reopened.messages.contains { $0.text == "Downstream follow-up" })
    }

    func testInterruptedReopenedChatRequiresExplicitCurrentInputRetry() async throws {
        let service = LibraryService()
        service.hold = true
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: service, store: store)
        chat.send("Synthetic interrupted request", snapshot: AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75]))
        let pending = try await pending(service)
        let id = try XCTUnwrap(chat.activeID)
        chat.cancel()
        pending.resume(returning: AssistantAnswer(text: "Cancelled"))
        await drain()
        let resumedService = LibraryService()
        let resumed = AssistantConversation(service: resumedService, store: store)
        resumed.open(id)
        XCTAssertTrue(resumed.needsFreshRetry)
        resumed.retry()
        XCTAssertTrue(resumedService.snapshots.isEmpty)
        let fresh = AssistantSnapshot(values: [8, 6000, 40, 62, 150, 180, 80])
        resumed.retryWithCurrentInputs(fresh)
        await finish(resumed)
        XCTAssertEqual(resumedService.snapshots.last?.values, fresh.values)
        XCTAssertEqual(resumed.messages.filter { $0.role == .user }.count, 1)
    }

    func testReopenAndContinueCaptureCurrentDataWithoutChangingHistoricalCardsOrState() async throws {
        let name = "ChatLibraryTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let state = TwinTrackState(defaults: defaults, healthService: LibraryHealthFixture())
        await state.requestHealthAccess()
        state.saveV2TestInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        XCTAssertTrue(state.runPrediction())
        let service = LibraryService()
        service.cards = [card(.current), card(.scenario)]
        let store = MemoryConversationStore()
        let chat = AssistantConversation(service: service, store: store)
        chat.send("Original request", snapshot: AssistantSnapshot(state: state))
        await finish(chat)
        let id = try XCTUnwrap(chat.activeID)
        let originalMessages = chat.messages
        state.saveV2TestInputs(studyMinutes: 180, screenTimeMinutes: 200, previousScore: 80)
        let inputs = AssistantSnapshot(state: state).values
        let prediction = state.lastPrediction
        let history = state.predictionHistory
        chat.reset()
        chat.open(id)
        XCTAssertEqual(AssistantSnapshot(state: state).values, inputs)
        XCTAssertEqual(state.lastPrediction, prediction)
        XCTAssertEqual(state.predictionHistory, history)
        chat.send("New personalized question", snapshot: AssistantSnapshot(state: state))
        await finish(chat)
        XCTAssertEqual(service.snapshots.last?.values, inputs)
        XCTAssertEqual(service.snapshots.first?.values[4], 120)
        XCTAssertEqual(Array(chat.messages.prefix(originalMessages.count)), originalMessages)
        XCTAssertEqual(AssistantSnapshot(state: state).values, inputs)
        XCTAssertEqual(state.predictionHistory, history)
        XCTAssertTrue(chat.delete(id))
        XCTAssertEqual(state.predictionHistory, history)
        chat.send("Separate saved chat"); await finish(chat)
        let records = store.conversations
        XCTAssertTrue(state.clearPredictionHistory())
        XCTAssertEqual(store.conversations, records)
        XCTAssertTrue(state.predictionHistory.isEmpty)
    }

    func testArchiveOmitsRequestSnapshotsInternalErrorsAndHiddenTranscripts() async throws {
        let service = LibraryService()
        service.failure = .failed
        let chat = AssistantConversation(service: service)
        chat.send("Synthetic visible question", snapshot: AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75]))
        await finish(chat)
        let data = try JSONEncoder().encode(FileConversationStore.Archive(version: 1, conversations: chat.conversations))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let records = try XCTUnwrap(json["conversations"] as? [[String: Any]])
        XCTAssertEqual(Set(records[0].keys), Set(["id", "title", "createdAt", "updatedAt", "messages", "completion"]))
        let messages = try XCTUnwrap(records[0]["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(Set(messages[0].keys), Set(["id", "role", "text", "cards", "createdAt"]))
        XCTAssertEqual(messages[0]["text"] as? String, "Synthetic visible question")
        XCTAssertEqual(records[0]["completion"] as? String, "failed")
    }

    private func card(_ kind: AssistantCard.Kind) -> AssistantCard {
        AssistantCard(kind: kind, title: "Synthetic historical result", message: "Fixture only",
                      prediction: 75, baseline: 70, delta: 5)
    }
    private func saved() -> SavedConversation {
        SavedConversation(id: UUID(), title: "Synthetic saved chat", createdAt: Date(), updatedAt: Date(),
                          messages: [AssistantMessage(role: .user, text: "Synthetic message")], completion: .idle)
    }
    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ChatLibraryTests-\(UUID())", isDirectory: true)
    }
    private func finish(_ chat: AssistantConversation) async {
        for _ in 0..<2000 { if !chat.isGenerating { break }; await Task.yield() }
        XCTAssertFalse(chat.isGenerating)
    }
    private func pending(_ service: LibraryService) async throws -> CheckedContinuation<AssistantAnswer, Never> {
        for _ in 0..<2000 { if service.pending != nil { break }; await Task.yield() }
        return try XCTUnwrap(service.pending)
    }
    private func drain() async { for _ in 0..<30 { await Task.yield() } }
}

@MainActor
private final class LibraryService: AssistantResponding {
    let availability = AssistantAvailability.available
    var snapshots: [AssistantSnapshot] = []
    var transcripts: [[AssistantMessage]] = []
    var cards: [AssistantCard] = []
    var hold = false
    var failure: AssistantFailure?
    var pending: CheckedContinuation<AssistantAnswer, Never>?
    func respond(to messages: [AssistantMessage], snapshot: AssistantSnapshot) async throws -> AssistantAnswer {
        snapshots.append(snapshot)
        transcripts.append(messages)
        if let failure { throw failure }
        if hold { hold = false; return await withCheckedContinuation { pending = $0 } }
        return AssistantAnswer(text: "Synthetic library response", cards: cards)
    }
}

private final class FailingLibraryStore: ConversationPersisting {
    var records: [SavedConversation] = []
    var fails = false
    func load() throws -> [SavedConversation] { records }
    func save(_ conversations: [SavedConversation]) throws {
        if fails { throw ConversationStorageError.invalidData }
        records = conversations
    }
}

@MainActor
private struct LibraryHealthFixture: HealthDataProviding {
    let isAvailable = true
    func requestAccess() async throws {}
    func read(window: HealthDataWindow) async -> HealthReadings {
        HealthReadings(sleep: .available(7), steps: .available(5000), exercise: .available(30), restingHeartRate: .available(60), restingHeartRateSampleDate: window.day.start)
    }
}
