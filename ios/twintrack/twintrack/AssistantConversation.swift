import Combine
import Foundation

enum AssistantAvailability: Equatable {
    case available, unsupported, disabled, notReady, unavailable

    var message: String {
        switch self {
        case .available: "Apple Intelligence · On-device"
        case .unsupported: "On-device chat needs an Apple Intelligence-compatible iPhone."
        case .disabled: "Enable Apple Intelligence in Settings to use on-device chat."
        case .notReady: "The on-device model is not ready yet. Try again after it finishes downloading."
        case .unavailable: "On-device chat is currently unavailable."
        }
    }
}

enum AssistantFailure: String, Error, Equatable {
    case contextLimit, safety, language, unavailable, failed
    case assetsNotReady, decoding, unsupportedGuide, toolFailure, busy, cancelled, rateLimited, emptyResponse

    var message: String {
        switch self {
        case .contextLimit: "This request needs less context. Shorten it or start a new chat; your saved chat stays intact."
        case .safety: "I can’t help with that request. You can ask about a different topic."
        case .language: "The on-device model does not support this language or region yet."
        case .unavailable: "On-device chat is unavailable. Check Apple Intelligence availability."
        case .failed: "Couldn’t complete that response. Please try again."
        case .assetsNotReady: "Required on-device model resources aren’t ready. Try again later."
        case .decoding: "The model couldn’t format this response. Please retry."
        case .unsupportedGuide: "The model couldn’t use this response format."
        case .toolFailure: "The TwinTrack action couldn’t finish. Your data is unchanged."
        case .busy: "Another model request is still finishing. Try again shortly."
        case .cancelled: "Response stopped."
        case .rateLimited: "The on-device model needs a moment. Try again shortly."
        case .emptyResponse: "The model returned an empty response. Please retry."
        }
    }
}

nonisolated struct AssistantMessage: Identifiable, Equatable, Codable, Sendable {
    nonisolated enum Role: String, Codable, Sendable { case user, assistant }
    let id: UUID
    let role: Role
    var text: String
    var cards: [AssistantCard] = []
    let createdAt: Date
    var safetyRefusal: Bool? = nil
    var provenance: AssistantProvenance? = nil
    var sourceIDs: [String]? = nil
    var scenarioContext: AssistantScenarioContext? = nil

    init(id: UUID = UUID(), role: Role, text: String, cards: [AssistantCard] = [], createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.cards = cards
        self.createdAt = createdAt
    }
}

struct AssistantAnswer {
    let text: String
    var cards: [AssistantCard] = []
    var safetyRefusal = false
    var provenance: AssistantProvenance? = nil
    var sourceIDs: [String]? = nil
    var scenarioContext: AssistantScenarioContext? = nil
    var reviewReason: String? = nil
}

@MainActor
protocol AssistantResponding {
    var availability: AssistantAvailability { get }
    func respond(to messages: [AssistantMessage], snapshot: AssistantSnapshot) async throws -> AssistantAnswer
}

/// Chat presentation/library only; production inputs still have one TwinTrackState.
@MainActor
final class AssistantConversation: ObservableObject {
    @Published private(set) var messages: [AssistantMessage] = []
    @Published private(set) var availability: AssistantAvailability
    @Published private(set) var isGenerating = false
    @Published private(set) var failure: AssistantFailure?
    @Published private(set) var wasCancelled = false
    @Published private(set) var conversations: [SavedConversation] = []
    @Published private(set) var activeID: UUID?
    @Published private(set) var storageIssue: String?
    @Published private(set) var reopened = false
    @Published private(set) var liveReplyIDs: Set<UUID> = []
    @Published private(set) var needsFreshRetry = false
    private let store: any ConversationPersisting
    private var libraryReadable = true
    private var activeCreatedAt = Date()
    private var activeTitle = ""
    private var libraryLoadInProgress = false

    private let service: any AssistantResponding
    private var task: Task<Void, Never>?
    private var generation = 0
    private var requestSnapshot = AssistantSnapshot()

    init(service: (any AssistantResponding)? = nil, store: (any ConversationPersisting)? = nil,
         deferFileLoad: Bool = false) {
        let began = ProcessInfo.processInfo.systemUptime
        defer { AssistantPerformance.mark(.conversationInit, duration: ProcessInfo.processInfo.systemUptime - began) }
        let service = service ?? FoundationAssistantService()
        self.service = service
        // Injected services default to an isolated memory library for unit tests.
        self.store = store ?? (service is FoundationAssistantService ? FileConversationStore() as any ConversationPersisting : MemoryConversationStore())
        availability = AssistantPerformance.measure(.availability) { service.availability }
        if deferFileLoad, let fileStore = self.store as? FileConversationStore {
            libraryLoadInProgress = true
            Task { [weak self] in
                do {
                    let began = ProcessInfo.processInfo.systemUptime
                    let loaded = try await fileStore.loadAsync()
                    AssistantPerformance.mark(.historyLoad, duration: ProcessInfo.processInfo.systemUptime - began)
                    guard let self else { return }
                    self.libraryLoadInProgress = false
                    self.conversations = loaded
                    if !self.messages.isEmpty {
                        self.persistActive(self.isGenerating ? .generating : .idle)
                    }
                } catch {
                    guard let self else { return }
                    self.libraryLoadInProgress = false
                    self.libraryReadable = false
                    self.storageIssue = "Saved chats could not be opened. The existing file has not been replaced."
                }
            }
        } else {
            do { conversations = try self.store.load() }
            catch {
                libraryReadable = false
                storageIssue = "Saved chats could not be opened. The existing file has not been replaced."
            }
        }
    }

    func sources(for message: AssistantMessage) -> [AssistantGuidanceSource] {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return [] }
        let context = Array(messages.prefix(index))
        return (message.sourceIDs ?? []).compactMap { AssistantGuidance.resolve($0, for: context) }
    }

    func checkAvailability() { availability = AssistantPerformance.measure(.availability) { service.availability } }

    @discardableResult
    func send(_ text: String, snapshot: AssistantSnapshot? = nil) -> Bool {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isGenerating, !text.isEmpty else { return false }
        guard text.count <= 2000, text.utf8.count <= 4000 else {
            failure = .contextLimit
            return false
        }
        messages.append(AssistantMessage(role: .user, text: text))
        if activeID == nil {
            activeID = UUID()
            activeCreatedAt = Date()
            activeTitle = String(text.replacingOccurrences(of: "\n", with: " ").prefix(60))
        }
        needsFreshRetry = false
        requestSnapshot = snapshot ?? AssistantSnapshot()
        start()
        return true
    }

    func retry() {
        guard !isGenerating, !needsFreshRetry, failure != .safety, messages.last?.safetyRefusal != true, messages.last?.role == .user else { return }
        checkAvailability()
        start()
    }

    func cancel() {
        guard isGenerating else { return }
        generation += 1
        task?.cancel()
        task = nil
        isGenerating = false
        wasCancelled = true
        persistActive(.cancelled)
    }

    func reset() {
        cancel()
        guard storageIssue == nil || messages.isEmpty else { return }
        messages = []
        failure = nil
        wasCancelled = false
        requestSnapshot = AssistantSnapshot()
        activeID = nil
        activeTitle = ""
        reopened = false
        liveReplyIDs = []
        needsFreshRetry = false
    }

    func open(_ id: UUID) {
        cancel()
        guard storageIssue == nil || messages.isEmpty else { return }
        guard let saved = conversations.first(where: { $0.id == id }) else { return }
        activeID = saved.id
        activeTitle = saved.title
        activeCreatedAt = saved.createdAt
        messages = saved.messages
        failure = nil
        liveReplyIDs = []
        wasCancelled = saved.completion == .cancelled || saved.completion == .generating
        needsFreshRetry = saved.messages.last?.role == .user && saved.messages.last?.safetyRefusal != true
        reopened = true
        requestSnapshot = AssistantSnapshot()
    }

    func retryWithCurrentInputs(_ snapshot: AssistantSnapshot) {
        guard needsFreshRetry, !isGenerating, messages.last?.role == .user else { return }
        checkAvailability()
        requestSnapshot = snapshot
        needsFreshRetry = false
        start()
    }

    @discardableResult
    func editUserMessage(_ id: UUID, to replacement: String,
                         snapshot: AssistantSnapshot? = nil) -> Bool {
        let replacement = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isGenerating, !replacement.isEmpty,
              replacement.count <= 2000, replacement.utf8.count <= 4000,
              let index = messages.firstIndex(where: { $0.id == id && $0.role == .user }) else {
            return false
        }
        checkAvailability()

        messages[index].text = replacement
        messages[index].cards = []
        messages[index].safetyRefusal = nil
        messages[index].provenance = nil
        messages[index].sourceIDs = nil
        messages[index].scenarioContext = nil
        if index + 1 < messages.endIndex {
            messages.removeSubrange((index + 1)..<messages.endIndex)
        }
        liveReplyIDs.formIntersection(Set(messages.map(\.id)))
        failure = nil
        wasCancelled = false
        needsFreshRetry = false
        requestSnapshot = snapshot ?? AssistantSnapshot()
        start()
        return true
    }

    @discardableResult
    func rename(_ id: UUID, to title: String) -> Bool {
        guard storageIssue == nil else { return false }
        let title = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !title.isEmpty, let index = conversations.firstIndex(where: { $0.id == id }) else { return false }
        var updated = conversations
        updated[index].title = title
        updated[index].updatedAt = Date()
        guard saveLibrary(updated) else { return false }
        if activeID == id { activeTitle = title }
        return true
    }

    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard storageIssue == nil || activeID == id || messages.isEmpty else { return false }
        if activeID == id { cancel() }
        guard saveLibrary(conversations.filter { $0.id != id }) else { return false }
        if activeID == id { reset() }
        return true
    }

    func retryStorage() {
        guard !libraryLoadInProgress else { return }
        if !libraryReadable {
            do { conversations = try store.load(); libraryReadable = true; storageIssue = nil }
            catch { return }
        }
        if !messages.isEmpty { persistActive(isGenerating ? .generating : .idle) }
    }

    private func persistActive(_ completion: ChatCompletion) {
        guard !libraryLoadInProgress, let activeID, !messages.isEmpty else { return }
        let record = SavedConversation(id: activeID, title: activeTitle, createdAt: activeCreatedAt,
            updatedAt: Date(), messages: messages, completion: completion)
        var updated = conversations.filter { $0.id != activeID }
        updated.append(record)
        _ = saveLibrary(updated.sorted { $0.updatedAt > $1.updatedAt })
    }

    @discardableResult
    private func saveLibrary(_ updated: [SavedConversation]) -> Bool {
        guard libraryReadable else { return false }
        do { try store.save(updated); conversations = updated; storageIssue = nil; return true }
        catch {
            storageIssue = "Chats could not be saved. Keep this conversation open and try saving again."
            return false
        }
    }

    private func start() {
        generation += 1
        let requestGeneration = generation
        let transcript = messages
        let snapshot = requestSnapshot
        failure = nil
        wasCancelled = false
        isGenerating = true
        task = Task { [weak self, service] in
            // Return the accepted send to SwiftUI before file IO/model setup.
            await Task.yield()
            guard let self, self.generation == requestGeneration, !Task.isCancelled else { return }
            self.persistActive(.generating)
            do {
                let response = try await service.respond(to: transcript, snapshot: snapshot)
                guard self.generation == requestGeneration, !Task.isCancelled else { return }
                var message = AssistantMessage(role: .assistant, text: response.text, cards: response.cards)
                message.safetyRefusal = response.safetyRefusal ? true : nil
                message.provenance = response.provenance
                message.sourceIDs = response.sourceIDs
                message.scenarioContext = response.scenarioContext
                self.liveReplyIDs.insert(message.id)
                self.messages.append(message)
                self.isGenerating = false
                self.task = nil
                self.persistActive(.idle)
            } catch {
                guard self.generation == requestGeneration else { return }
                self.isGenerating = false
                self.task = nil
                let failure = AssistantFailure.classify(error)
                if failure == .cancelled { self.wasCancelled = true }
                else {
                    self.failure = failure
                    if failure == .safety, let index = self.messages.indices.last {
                        self.messages[index].safetyRefusal = true
                        self.messages[index].provenance = AssistantProvenance(.frameworkRefusal)
                        self.liveReplyIDs.insert(self.messages[index].id)
                    }
                }
                self.persistActive(failure == .cancelled ? .cancelled : .failed)
            }
        }
    }
}
