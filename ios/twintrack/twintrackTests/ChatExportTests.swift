import XCTest
@testable import twintrack

@MainActor
final class ChatExportTests: XCTestCase {
    func testExportVisibleOrderingFormattingAndSafeFilename() {
        let messages = [AssistantMessage(role: .user, text: "First\nline"),
                        AssistantMessage(role: .assistant, text: "**Second** reply"),
                        AssistantMessage(role: .user, text: "Third")]
        let item = ChatExport(title: "A title / with punctuation", messages: messages, exportedAt: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(item.filename, "TwinTrack-Chat-1970-01-01.txt")
        XCTAssertTrue(item.text.hasPrefix("TwinTrack AI\n\nConversation: A title / with punctuation\n\nExported:"))
        XCTAssertTrue(item.text.contains("You\nFirst\nline\n\nTwinTrack AI\nSecond reply\n\nYou\nThird"))
        XCTAssertEqual(messages, item.messages)
    }

    func testExportExcludesInternalMetadataWithoutRewritingUserText() {
        var reply = AssistantMessage(role: .assistant, text: "Visible answer")
        reply.provenance = AssistantProvenance(.review)
        reply.sourceIDs = ["hidden-unresolved-source"]
        let item = ChatExport(title: nil, messages: [AssistantMessage(role: .user, text: "My question"), reply])
        for excluded in ["Reply details", "DEBUG", "FMQ-", "hidden-unresolved-source", "sourceIDs", "safetyRefusal", "provenance", reply.id.uuidString] {
            XCTAssertFalse(item.text.contains(excluded), excluded)
        }
        XCTAssertTrue(item.text.contains("Visible answer"))
    }

    func testExportCardsUseVisibleFormattingAndHistoricalLabel() {
        let card = AssistantCard(kind: .scenario, title: "What-If", message: "Synthetic scenario only.",
                                 prediction: 81, baseline: 80, delta: 1,
                                 fields: [AssistantField(label: "Study time", value: "Synthetic 2 hours")])
        let item = ChatExport(title: "Synthetic", messages: [AssistantMessage(role: .assistant, text: "Result", cards: [card])])
        XCTAssertTrue(item.text.contains("Historical result"))
        XCTAssertTrue(item.text.contains("Baseline: " + HomeDisplay.prediction(80)))
        XCTAssertTrue(item.text.contains("Scenario: " + HomeDisplay.prediction(81)))
        XCTAssertTrue(item.text.contains("Predicted change: " + PredictionHistoryDisplay.delta(1)))
        XCTAssertTrue(item.text.contains("Study time: Synthetic 2 hours"))
        XCTAssertFalse(item.text.contains(card.id.uuidString))
    }

    func testEmptyChatProducesNoExportContent() {
        XCTAssertEqual(ChatExport(title: "Empty", messages: []).text, "")
    }

    func testExportDoesNotMutateSavedChatAndRemainsSnapshotAfterEditing() throws {
        let store = MemoryConversationStore()
        let original = SavedConversation(id: UUID(), title: "Synthetic saved chat", createdAt: Date(), updatedAt: Date(),
                                         messages: [AssistantMessage(role: .user, text: "Before")], completion: .idle)
        try store.save([original])
        let export = ChatExport(title: original.title, messages: original.messages)
        _ = export.text
        XCTAssertEqual(try store.load(), [original])
        var edited = original
        edited.messages[0].text = "After"
        try store.save([edited])
        XCTAssertTrue(export.text.contains("Before"))
        XCTAssertFalse(export.text.contains("After"))
        XCTAssertEqual(try store.load(), [edited])
    }

    func testFrameworkRefusalExportsVisibleNoticeNotClassification() {
        var message = AssistantMessage(role: .user, text: "Synthetic safety fixture")
        message.safetyRefusal = true
        let text = ChatExport(title: nil, messages: [message]).text
        XCTAssertTrue(text.contains(AssistantFailure.safety.message))
        XCTAssertFalse(text.contains("safetyRefusal"))
    }
}
