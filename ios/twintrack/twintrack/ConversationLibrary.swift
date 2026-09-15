import Foundation

enum ChatCompletion: String, Codable { case idle, generating, cancelled, failed }

struct SavedConversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [AssistantMessage]
    var completion: ChatCompletion
}

protocol ConversationPersisting {
    func load() throws -> [SavedConversation]
    func save(_ conversations: [SavedConversation]) throws
}

enum ConversationStorageError: Error { case unsupportedVersion, invalidData }

struct FileConversationStore: ConversationPersisting {
    struct Archive: Codable {
        let version: Int
        let conversations: [SavedConversation]
    }
    let directory: URL
    private var file: URL { directory.appendingPathComponent("conversations.json") }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TwinTrackConversations", isDirectory: true)
    }

    func load() throws -> [SavedConversation] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        let archive = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: file))
        guard archive.version == 1 else { throw ConversationStorageError.unsupportedVersion }
        guard Set(archive.conversations.map(\.id)).count == archive.conversations.count,
              archive.conversations.allSatisfy({ !$0.messages.isEmpty && !$0.title.isEmpty
                  && Set($0.messages.map(\.id)).count == $0.messages.count }) else {
            throw ConversationStorageError.invalidData
        }
        return archive.conversations
    }

    func save(_ conversations: [SavedConversation]) throws {
        // No request snapshots, raw Health samples, model internals or debug errors
        // enter this archive. Protect both the atomic replacement and its directory.
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        var directoryURL = directory
        var resources = URLResourceValues()
        resources.isExcludedFromBackup = true
        try directoryURL.setResourceValues(resources)
        let data = try JSONEncoder().encode(Archive(version: 1, conversations: conversations))
        try data.write(to: file, options: [.atomic, .completeFileProtection])
        var fileURL = file
        try fileURL.setResourceValues(resources)
    }
}

final class MemoryConversationStore: ConversationPersisting {
    var conversations: [SavedConversation] = []
    func load() throws -> [SavedConversation] { conversations }
    func save(_ conversations: [SavedConversation]) throws { self.conversations = conversations }
}
