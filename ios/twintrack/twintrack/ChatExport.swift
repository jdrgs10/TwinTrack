import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A value snapshot, not a store reference. Only the explicit visible-content
/// projection crosses the share boundary; no archive or diagnostic is exported.
nonisolated struct ChatExport: Transferable {
    let title: String?
    let messages: [AssistantMessage]
    let exportedAt: Date

    init(title: String?, messages: [AssistantMessage], exportedAt: Date = Date()) {
        self.title = title
        self.messages = messages
        self.exportedAt = exportedAt
    }

    var filename: String {
        "TwinTrack-Chat-\(exportedAt.ISO8601Format().prefix(10)).txt"
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { item in
            await MainActor.run { Data(item.text.utf8) }
        }
        .suggestedFileName { $0.filename }
        .exportingCondition { !$0.messages.isEmpty }
    }

    @MainActor var text: String {
        guard !messages.isEmpty else { return "" }
        var sections = ["TwinTrack AI", title.map { "Conversation: \($0)" } ?? "Conversation",
                        "Exported: \(exportedAt.formatted(date: .abbreviated, time: .shortened))"]
        for (index, message) in messages.enumerated() {
            let visible = message.role == .assistant
                ? String(AssistantReplyReview.formatted(message.text).characters) : message.text
            sections.append("\(message.role == .user ? "You" : "TwinTrack AI")\n\(visible)")
            if message.role == .user && message.safetyRefusal == true {
                sections.append(AssistantFailure.safety.message)
            }
            let context = Array(messages.prefix(index))
            for sourceID in message.sourceIDs ?? [] {
                if let source = AssistantGuidance.resolve(sourceID, for: context) {
                    sections.append("Guidance reference · \(source.organization): \(source.title)\n\(source.url.absoluteString)")
                }
            }
            if !message.cards.isEmpty {
                sections.append("Historical result · \(message.createdAt.formatted(date: .abbreviated, time: .shortened))")
            }
            for card in message.cards {
                var lines = [card.title]
                if let value = card.baseline { lines.append("Baseline: \(HomeDisplay.prediction(value))") }
                if let value = card.prediction {
                    lines.append("\(card.kind == .scenario ? "Scenario" : "Predicted assessment score"): \(HomeDisplay.prediction(value))")
                }
                if let value = card.delta { lines.append("Predicted change: \(PredictionHistoryDisplay.delta(value))") }
                lines.append(card.message)
                if !card.fields.isEmpty {
                    lines.append("Inputs and source details")
                    lines += card.fields.map { "\($0.label): \($0.value)" }
                }
                sections.append(lines.joined(separator: "\n"))
            }
        }
        return sections.joined(separator: "\n\n") + "\n"
    }
}
