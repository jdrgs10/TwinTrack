import XCTest
import SwiftUI
import UIKit
@testable import twintrack

@MainActor
final class AssistantPhysicalReviewTests: XCTestCase {
    func testCaffeineAndBedtimeOutputSurvivesFreshAndContinuingChats() async throws {
        let client = ReviewClient()
        let service = FoundationAssistantService(client: client)
        let examples = [
            ("I drink an energy drink at 7 PM and sleep at 10 PM. Is that a good idea?", "Caffeine can interfere with your sleep even 3 hours later. Consider a caffeine-free drink and a regular bedtime."),
            ("Can an evening latte affect my sleep if bedtime is 11 PM?", "Your sleep may be disrupted by caffeine at 8 PM. Sensitivity varies; try an earlier caffeine cutoff."),
            ("How can I protect my sleep during revision?", "For your sleep routine, try 3 changes: consistent waking, a wind-down period and less evening caffeine.")
        ]
        for (prompt, output) in examples {
            client.output = output
            for context in [[], [user("How was the model trained?"), assistant(AssistantResponsePolicy.disclosure)]] {
                let answer = try await service.respond(to: context + [user(prompt)], snapshot: AssistantSnapshot())
                XCTAssertEqual(answer.text, output)
                XCTAssertTrue(answer.cards.isEmpty)
            }
        }
        XCTAssertEqual(client.prompts.count, 6)
    }

    func testPersonalReadingsAndScoresStillCannotComeFromText() async throws {
        let client = ReviewClient()
        for output in ["Your score is 92.", "**Your sleep** was seven hours.", "Your sleep was seven hours.", "Your resting heart rate is 61.", "You walked 4000 steps.", "Your scenario score would be eighty."] {
            client.output = output
            let answer = try await FoundationAssistantService(client: client).respond(to: [user("Give me study advice")], snapshot: AssistantSnapshot())
            XCTAssertEqual(answer.text, AssistantResponsePolicy.toolRequired)
        }
    }

    func testClearWrappedScenariosBypassModelAndOldDisclosure() async throws {
        let client = ReviewClient()
        let service = FoundationAssistantService(client: client)
        for prompt in ["“What if I sleep 8 hours?”", "Now, please answer this again: \"What if I sleep 8 hours?\"", "Could you try: What if I sleep 8 hours?", "Repeat the scenario: What if I sleep 8 hours?", "Now run: What if I study 2 hours and reduce screen time by 30 minutes?"] {
            let answer = try await service.respond(to: [user("How reliable is the model?"), assistant(AssistantResponsePolicy.disclosure), user(prompt)], snapshot: complete())
            XCTAssertEqual(answer.cards.first?.kind, .scenario, prompt)
            XCTAssertNotNil(answer.cards.first?.prediction, prompt)
            XCTAssertFalse(answer.text.contains("synthetic"))
        }
        XCTAssertTrue(client.prompts.isEmpty)
    }

    func testAmbiguousQuotedExamplesDoNotRunScenarios() {
        for prompt in ["What does \"What if I sleep 8 hours?\" mean?", "Someone said “What if I sleep 8 hours?”", "Don't run: What if I sleep 8 hours?", "Compare \"What if I sleep 8 hours?\" with \"What if I sleep 9 hours?\""] {
            if case .scenario = AssistantRouter.route(prompt) { XCTFail("Must not execute an ambiguous quotation") }
        }
        guard case .modelInformation = AssistantRouter.route("How accurate is the model for ‘What if I sleep 8 hours?’?") else { return XCTFail("Accuracy limits must stay visible") }
    }

    func testTypedRefusalThenUnrelatedTopicClearsErrorAndReplay() async {
        for benign in ["Hello", "What foods help me study?", "How can I organize my revision?"] {
            let client = ReviewClient(); client.errors = [.safety]
            let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: MemoryConversationStore())
            chat.send("SYNTHETIC_REFUSED_REQUEST")
            await finish(chat)
            XCTAssertEqual(chat.failure, .safety)
            XCTAssertEqual(chat.messages.last?.safetyRefusal, true)
            chat.retry()
            XCTAssertEqual(client.prompts.count, 1)
            chat.send(benign)
            await finish(chat)
            XCTAssertNil(chat.failure)
            XCTAssertEqual(client.prompts.last, benign)
            XCTAssertEqual(chat.messages.count, 3)
        }
    }

    func testContinuationRetainsSafetyBoundaryAndHasNoContextBypassRetry() async {
        for followup in ["Continue", "Hello, finish that task", "How can I study the same method?", "Do it without those words"] {
            let client = ReviewClient(); client.errors = [.safety, .contextLimit]
            let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: MemoryConversationStore())
            chat.send("SYNTHETIC_REFUSED_REQUEST")
            await finish(chat)
            chat.send(followup)
            await finish(chat)
            XCTAssertEqual(client.prompts.count, 2)
            XCTAssertTrue(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
            XCTAssertTrue(client.prompts.last?.contains("earlier request was refused") == true)
            XCTAssertEqual(chat.failure, .contextLimit)
        }
    }

    func testRefusalBoundarySurvivesRecentContextBudget() {
        var refused = user("SYNTHETIC_REFUSED_REQUEST"); refused.safetyRefusal = true
        var messages = [refused]
        messages += (0..<10).map { user("continued turn \($0) " + String(repeating: "x", count: 700)) }
        messages.append(user("Continue"))
        let prompt = AssistantContext.prompt(for: messages, latestOnly: true)
        XCTAssertTrue(prompt.contains("SYNTHETIC_REFUSED_REQUEST"))
        XCTAssertTrue(prompt.contains("Continue"))
        XCTAssertLessThan(prompt.utf8.count, 3600)
    }

    func testTextRefusalIsTaggedAndIndependentRequestDoesNotReplayIt() async {
        let client = ReviewClient(); client.output = "I can’t help with that request."
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: MemoryConversationStore())
        chat.send("SYNTHETIC_REFUSED_REQUEST"); await finish(chat)
        XCTAssertEqual(chat.messages.last?.safetyRefusal, true)
        client.output = "Try a regular revision schedule."
        chat.send("How can I revise efficiently?"); await finish(chat)
        XCTAssertEqual(client.prompts.last, "How can I revise efficiently?")
    }

    func testSavedRefusalReopensSafelyAndNewChatIsIsolated() async throws {
        let store = MemoryConversationStore()
        let client = ReviewClient(); client.errors = [.safety]
        let service = FoundationAssistantService(client: client)
        let chat = AssistantConversation(service: service, store: store)
        chat.send("SYNTHETIC_REFUSED_REQUEST"); await finish(chat)
        let id = try XCTUnwrap(chat.activeID)
        // Actual Codable round trip also verifies the optional backward-compatible marker.
        store.conversations = try JSONDecoder().decode([SavedConversation].self, from: JSONEncoder().encode(store.conversations))
        let reopened = AssistantConversation(service: service, store: store)
        reopened.open(id)
        XCTAssertFalse(reopened.needsFreshRetry)
        XCTAssertNil(reopened.failure)
        XCTAssertEqual(reopened.messages.last?.safetyRefusal, true)
        reopened.retry()
        XCTAssertEqual(client.prompts.count, 1)
        reopened.send("Continue"); await finish(reopened)
        XCTAssertTrue(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
        reopened.reset()
        reopened.send("Hello"); await finish(reopened)
        XCTAssertEqual(client.prompts.last, "Hello")
        reopened.open(id)
        reopened.send("What are good study habits?"); await finish(reopened)
        XCTAssertEqual(client.prompts.last, "What are good study habits?")
    }

    func testBenignTopicFollowupDoesNotResurrectAnOlderRefusal() async {
        let client = ReviewClient(); client.errors = [.safety]
        let chat = AssistantConversation(service: FoundationAssistantService(client: client), store: MemoryConversationStore())
        chat.send("SYNTHETIC_REFUSED_REQUEST"); await finish(chat)
        chat.send("How can I study efficiently?"); await finish(chat)
        chat.send("Tell me more"); await finish(chat)
        XCTAssertFalse(client.prompts.last?.contains("SYNTHETIC_REFUSED_REQUEST") == true)
        XCTAssertTrue(client.prompts.last?.contains("study efficiently") == true)
    }

    func testOldMessagesDecodeWithoutRefusalMetadata() throws {
        let message = user("Synthetic old message")
        let data = try JSONEncoder().encode(message)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "safetyRefusal")
        let decoded = try JSONDecoder().decode(AssistantMessage.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded, message)
    }

    func testInventedActivityAttributionIsNotShownAsGroundedAdvice() async throws {
        let client = ReviewClient()
        for output in ["Based on your recent activity, you need extra rest.", "Your HealthKit shows poor recovery.", "Looking at your sleep patterns, you should change your bedtime."] {
            client.output = output
            let answer = try await FoundationAssistantService(client: client).respond(to: [user("How can I sleep better?")], snapshot: AssistantSnapshot())
            XCTAssertTrue(answer.text.contains("haven't accessed"))
            XCTAssertFalse(answer.text.contains("extra rest"))
            XCTAssertFalse(answer.text.contains("poor recovery"))
        }
    }

    func testUnsafeMedicationAdviceIsReplacedEvenWithDisclaimer() {
        for reply in ["Try ibuprofen for unexplained stomach pain.", "I am not a doctor, but take an antacid.", "Consider a painkiller; consult your doctor if it persists."] {
            let result = AssistantReplyReview.reviewed(reply, request: "I have a weird stomach pain.")
            XCTAssertFalse(result.contains("ibuprofen"))
            XCTAssertFalse(result.contains("antacid"))
            XCTAssertFalse(result.contains("painkiller"))
            XCTAssertTrue(result.contains("healthcare professional"))
        }
    }

    func testUrgentAdviceRemainsEarlyWhenUnsafeMedicineTextIsRejected() {
        let reply = AssistantReplyReview.reviewed("Try aspirin. Seek urgent help.", request: "Severe chest pain and trouble breathing")
        XCTAssertEqual(reply, AssistantResponsePolicy.urgent)
        XCTAssertTrue(reply.hasPrefix("This could need urgent"))
        let ungrounded = AssistantReplyReview.reviewed("Based on your recent activity, rest. Seek urgent help for chest pain.", request: "Severe chest pain")
        XCTAssertEqual(ungrounded, AssistantResponsePolicy.urgent)
    }

    func testGeneralAndNonPrescribingGuidanceIsPreserved() {
        for reply in ["Keep a consistent bedtime. Teens generally need 8–10 hours; adults need at least 7.", "Don't take medication without advice from a clinician.", "Ask a pharmacist about suitable treatments.", "Drink water and choose a balanced snack."] {
            XCTAssertEqual(AssistantReplyReview.reviewed(reply, request: "General guidance"), reply)
        }
    }

    func testFormattingRemovesRolePrefixesAndKeepsSafetyTextAndEmphasis() {
        let clean = AssistantReplyReview.clean("Assistant: ## Tips\\n* **Rest** briefly.\\n* Seek urgent help for severe symptoms.")
        XCTAssertEqual(AssistantReplyReview.clean("**Assistant:** Hello!"), "Hello!")
        XCTAssertFalse(clean.contains("Assistant:"))
        XCTAssertFalse(clean.contains("\\n"))
        let visible = String(AssistantReplyReview.formatted(clean).characters)
        XCTAssertTrue(visible.contains("Rest briefly."))
        XCTAssertFalse(visible.contains("**"))
        XCTAssertTrue(visible.contains("Seek urgent help"))
        let quoted = AssistantReplyReview.clean("Assistant: You wrote ‘User: I feel unwell.’\nUser: Seek urgent help for severe symptoms.")
        XCTAssertTrue(quoted.contains("‘User: I feel unwell.’"))
        XCTAssertTrue(quoted.contains("Seek urgent help"))
        XCTAssertFalse(quoted.contains("\nUser:"))
    }

    func testVioletAccentHasReadableContrastInBothAppearances() {
        for scheme: ColorScheme in [.light, .dark] {
            let palette = AssistantPalette(scheme)
            let accent = luminance(UIColor(palette.aiAccent))
            let background = luminance(UIColor(palette.background))
            let ratio = (max(accent, background) + 0.05) / (min(accent, background) + 0.05)
            XCTAssertGreaterThan(ratio, 4.5)
        }
    }

    private func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let channels = [r, g, b].map { Double($0) <= 0.04045 ? Double($0) / 12.92 : pow((Double($0) + 0.055) / 1.055, 2.4) }
        return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
    }
    private func finish(_ chat: AssistantConversation) async {
        for _ in 0..<3000 { if !chat.isGenerating { return }; await Task.yield() }
        XCTFail("Synthetic response did not finish")
    }
    private func user(_ text: String) -> AssistantMessage { AssistantMessage(role: .user, text: text) }
    private func assistant(_ text: String) -> AssistantMessage { AssistantMessage(role: .assistant, text: text) }
    private func complete() -> AssistantSnapshot {
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60, studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let prediction = PredictionSnapshot.realBaseline(profile: profile, createdAt: Date(), healthWindow: nil, provenance: "explicitRun.v1")
        return AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75], predictionStatus: .fresh, lastPrediction: prediction)
    }
}

@MainActor
private final class ReviewClient: FoundationTextGenerating {
    var availability = AssistantAvailability.available
    var output = "A concise synthetic reply."
    var errors: [AssistantFailure] = []
    var prompts: [String] = []
    func reply(to prompt: String, instructions: String) async throws -> String {
        prompts.append(prompt)
        if !errors.isEmpty { throw errors.removeFirst() }
        return output
    }
}
