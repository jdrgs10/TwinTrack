import Foundation
import FoundationModels
import XCTest
@testable import twintrack

@MainActor
final class AssistantTests: XCTestCase {
    func testAvailabilityReasonsRemainDistinct() async {
        XCTAssertEqual(FoundationAssistantService.availability(.available), .available)
        XCTAssertEqual(FoundationAssistantService.availability(.unavailable(.deviceNotEligible)), .unsupported)
        XCTAssertEqual(FoundationAssistantService.availability(.unavailable(.appleIntelligenceNotEnabled)), .disabled)
        XCTAssertEqual(FoundationAssistantService.availability(.unavailable(.modelNotReady)), .notReady)
    }

    func testGreetingsAndGeneralQuestionNeedNoHealthBaseline() async {
        for prompt in ["Hello", "How are you?", "How can I study better?"] {
            let service = AssistantStub()
            let chat = AssistantConversation(service: service)
            chat.send(prompt)
            await finish(chat)
            XCTAssertEqual(service.prompts.last?.last?.text, prompt)
            XCTAssertEqual(chat.messages.last?.text, "Test response")
            XCTAssertNil(chat.failure)
        }
    }

    func testUnavailableModelNeverStartsGeneration() async {
        let service = AssistantStub()
        service.availability = .notReady
        let chat = AssistantConversation(service: service)
        chat.send("Hello")
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertTrue(service.prompts.isEmpty)
        XCTAssertFalse(chat.isGenerating)
    }

    func testAvailabilityCanRecover() async {
        let service = AssistantStub()
        service.availability = .disabled
        let chat = AssistantConversation(service: service)
        service.availability = .available
        chat.checkAvailability()
        chat.send("Hello")
        await finish(chat)
        XCTAssertEqual(chat.messages.count, 2)
    }

    func testCancelRejectsLateResponse() async throws {
        let service = AssistantStub()
        service.hold = true
        let chat = AssistantConversation(service: service)
        chat.send("Hello")
        for _ in 0..<1000 { if service.pending != nil { break }; await Task.yield() }
        let pending = try XCTUnwrap(service.pending)
        chat.cancel()
        pending.resume(returning: "Late response")
        service.pending = nil
        for _ in 0..<20 { await Task.yield() }
        XCTAssertTrue(chat.wasCancelled)
        XCTAssertFalse(chat.isGenerating)
        XCTAssertEqual(chat.messages.count, 1)
    }

    func testRetryDoesNotDuplicateUserMessage() async {
        let service = AssistantStub()
        service.failure = .failed
        let chat = AssistantConversation(service: service)
        chat.send("Hello")
        await finish(chat)
        XCTAssertEqual(chat.failure, .failed)
        service.failure = nil
        chat.retry()
        await finish(chat)
        XCTAssertEqual(chat.messages.count, 2)
        XCTAssertEqual(service.prompts.count, 2)
        XCTAssertNil(chat.failure)
    }

    func testBlankInputDoesNotGenerate() async {
        let service = AssistantStub()
        let chat = AssistantConversation(service: service)
        chat.send("  \n")
        XCTAssertTrue(service.prompts.isEmpty)
        XCTAssertTrue(chat.messages.isEmpty)
    }

    func testOversizedInputOffersConversationReset() async {
        let chat = AssistantConversation(service: AssistantStub())
        chat.send(String(repeating: "x", count: 2001))
        XCTAssertEqual(chat.failure, .contextLimit)
        XCTAssertTrue(chat.messages.isEmpty)
        chat.reset()
        XCTAssertNil(chat.failure)
    }

    func testContextLimitFailureDoesNotEraseConversation() async {
        let service = AssistantStub()
        service.failure = .contextLimit
        let chat = AssistantConversation(service: service)
        chat.send("Explain my study routine")
        await finish(chat)
        XCTAssertEqual(chat.failure, .contextLimit)
        XCTAssertEqual(chat.messages.count, 1)
    }

    func testConversationIsPassedToNextTurn() async {
        let service = AssistantStub()
        let chat = AssistantConversation(service: service)
        chat.send("Hello")
        await finish(chat)
        chat.send("Tell me more")
        await finish(chat)
        XCTAssertEqual(service.prompts.last?.count, 3)
        XCTAssertEqual(chat.messages.count, 4)
    }

    func testCurrentToolUsesFrozenPredictionAndExactlySevenInputs() async throws {
        let snapshot = completeSnapshot()
        let run = AssistantToolRun(snapshot: snapshot, userMessage: "Predict my score")
        _ = try await ReadCurrentTwinTool(run: run).call(arguments: AssistantReadArguments(request: "Predict my score"))
        let card = try XCTUnwrap(run.cards.last)
        XCTAssertEqual(card.prediction, TwinTrackModel.predict(try XCTUnwrap(snapshot.profile)))
        XCTAssertEqual(Array(card.fields.prefix(7)).map(\.label), TwinTrackFeature.allCases.map(HomeDisplay.featureName))
        XCTAssertEqual(run.toolNames, ["readCurrentTwin"])
    }

    func testStudyIncreaseConvertsMinutesWithoutChangingSnapshot() async throws {
        let run = scenarioRun("What if I study 30 minutes more?")
        _ = try await RunWhatIfTool(run: run).call(arguments: AssistantScenarioArguments(changes: [
            change(.study_minutes, .increase, .minutes, 30, "study 30 minutes more")
        ]))
        var expected = try WhatIfScenario(baseline: run.snapshot.profile)
        try expected.set(150, for: .studyMinutes)
        try assertScenario(run, equals: expected.evaluate())
        XCTAssertEqual(run.snapshot.values[4], 120)
        XCTAssertTrue(run.snapshot.history.isEmpty)
    }

    func testSleepSetUsesExistingScenarioEngine() async throws {
        let run = scenarioRun("What if I sleep 8 hours?")
        _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.sleep_hours, .set, .hours, 8, "sleep 8 hours")]))
        var expected = try WhatIfScenario(baseline: run.snapshot.profile)
        try expected.set(8, for: .sleepHours)
        try assertScenario(run, equals: expected.evaluate())
    }

    func testScreenTimeDecreaseConvertsHoursToMinutes() async throws {
        let run = scenarioRun("What if I reduce screen time by one hour?")
        _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.screen_time_minutes, .decrease, .hours, 1, "reduce screen time by one hour")]))
        var expected = try WhatIfScenario(baseline: run.snapshot.profile)
        try expected.set(180, for: .screenTimeMinutes)
        try assertScenario(run, equals: expected.evaluate())
    }

    func testTwoChangesUseOneBaselineAndOneCombinedPrediction() async throws {
        let run = scenarioRun("What if I study 2 hours and sleep 8 hours?")
        _ = try run.runScenario(AssistantScenarioArguments(changes: [
            change(.study_minutes, .set, .hours, 2, "study 2 hours"), change(.sleep_hours, .set, .hours, 8, "sleep 8 hours")
        ]))
        var expected = try WhatIfScenario(baseline: run.snapshot.profile)
        try expected.set(120, for: .studyMinutes)
        try expected.set(8, for: .sleepHours)
        try assertScenario(run, equals: expected.evaluate())
    }

    func testPreviousScoreUsesValidatedProductionRange() async throws {
        for value in [90.0, 101] {
            let phrase = "previous score is \(Int(value))"
            let run = scenarioRun("What if my \(phrase)?")
            _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.previous_score, .set, .points, value, phrase)]))
            XCTAssertEqual(run.cards.last?.kind, value == 90 ? .scenario : .clarification)
        }
    }

    func testAllSevenMissingInputsNeverBecomeZeros() async throws {
        for index in 0..<7 {
            var values = completeSnapshot().values
            values[index] = nil
            let snapshot = AssistantSnapshot(values: values)
            let run = AssistantToolRun(snapshot: snapshot, userMessage: "What if I sleep 8 hours?")
            _ = try run.readCurrent()
            XCTAssertNil(run.cards.last?.prediction)
            XCTAssertEqual(run.cards.last?.fields[index].value, "Unavailable")
            _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.sleep_hours, .set, .hours, 8, "sleep 8 hours")]))
            XCTAssertEqual(run.cards.last?.kind, .unavailable)
            XCTAssertNil(run.cards.last?.baseline)
        }
    }

    func testAmbiguousMakeItTwoCannotRunScenario() async throws {
        let run = scenarioRun("Make it two.")
        _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.study_minutes, .set, .hours, 2, "Make it two.")]))
        XCTAssertEqual(run.cards.last?.kind, .clarification)
        XCTAssertNil(run.cards.last?.prediction)
    }

    func testWrongUnitOperationOrInventedEvidenceIsRejected() async throws {
        let invalid = [
            change(.sleep_hours, .set, .bpm, 8, "sleep 8 hours"),
            change(.sleep_hours, .increase, .hours, 8, "sleep 8 hours"),
            change(.sleep_hours, .set, .hours, 9, "sleep 8 hours"),
            change(.sleep_hours, .set, .hours, 8, "sleep eight hours"),
            change(.sleep_hours, .set, .hours, .infinity, "sleep 8 hours")
        ]
        for invalidChange in invalid {
            let run = scenarioRun("What if I sleep 8 hours?")
            _ = try run.runScenario(AssistantScenarioArguments(changes: [invalidChange]))
            XCTAssertEqual(run.cards.last?.kind, .clarification)
            XCTAssertNil(run.cards.last?.prediction)
        }
    }

    func testEmptyDuplicateAndTooManyChangesAreRejected() async throws {
        let value = change(.sleep_hours, .set, .hours, 8, "sleep 8 hours")
        for changes in [[], [value, value], Array(repeating: value, count: 8)] {
            let run = scenarioRun("What if I sleep 8 hours?")
            _ = try run.runScenario(AssistantScenarioArguments(changes: changes))
            XCTAssertEqual(run.cards.last?.kind, .clarification)
        }
    }

    func testSnapshotSurvivesRealStateMutationWithoutQueryingOrSaving() async throws {
        let name = "AssistantTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let health = AssistantHealthStub()
        let state = TwinTrackState(defaults: defaults, healthService: health)
        state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        await state.requestHealthAccess()
        state.runFixturePrediction()
        let snapshot = AssistantSnapshot(state: state)
        let initialHistory = state.predictionHistory
        state.saveManualInputs(studyMinutes: 300, screenTimeMinutes: 100, previousScore: 90)
        let changedHistory = state.predictionHistory
        let run = AssistantToolRun(snapshot: snapshot, userMessage: "What if I sleep 8 hours?")
        _ = try run.readCurrent()
        _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.sleep_hours, .set, .hours, 8, "sleep 8 hours")]))
        _ = try run.readHistory(AssistantHistoryArguments(scope: .latest, localDate: ""))
        XCTAssertEqual(run.cards[1].baseline, TwinTrackModel.predict(try XCTUnwrap(snapshot.profile)))
        XCTAssertEqual(snapshot.values[4], 120)
        XCTAssertEqual(state.studyMinutes, 300)
        XCTAssertEqual(snapshot.history, initialHistory)
        XCTAssertEqual(state.predictionHistory, changedHistory)
        XCTAssertEqual(health.reads, 1)
        XCTAssertEqual(health.requests, 1)
    }

    func testHistoryLatestAndSevenDaysPreserveGapsAndSameDayRule() async throws {
        let base = completeSnapshot()
        let first = try XCTUnwrap(PredictionSnapshot.realBaseline(profile: base.profile!, createdAt: base.capturedAt.addingTimeInterval(-3600), healthWindow: base.window))
        let latest = try XCTUnwrap(PredictionSnapshot.realBaseline(profile: base.profile!, createdAt: base.capturedAt, healthWindow: base.window))
        let snapshot = AssistantSnapshot(values: base.values, history: [first, latest], capturedAt: base.capturedAt, calendar: base.calendar)
        let run = AssistantToolRun(snapshot: snapshot, userMessage: "Show prediction history")
        _ = try await ReadPredictionHistoryTool(run: run).call(arguments: AssistantHistoryArguments(scope: .latest, localDate: ""))
        XCTAssertEqual(run.cards.last?.prediction, latest.prediction)
        _ = try run.readHistory(AssistantHistoryArguments(scope: .sevenDays, localDate: ""))
        XCTAssertEqual(run.cards.last?.fields.count, 7)
        XCTAssertEqual(run.cards.last?.fields.filter { $0.value == "No saved prediction" }.count, 6)
        XCTAssertNil(run.cards.last?.delta)
        XCTAssertEqual(snapshot.history, [first, latest])
    }

    func testEmptyAndInvalidDateHistoryStayHonest() async throws {
        let run = scenarioRun("Show history")
        _ = try run.readHistory(AssistantHistoryArguments(scope: .latest, localDate: ""))
        XCTAssertNil(run.cards.last?.prediction)
        _ = try run.readHistory(AssistantHistoryArguments(scope: .day, localDate: "2026-02-30"))
        XCTAssertEqual(run.cards.last?.kind, .clarification)
        _ = try run.readHistory(AssistantHistoryArguments(scope: .day, localDate: "2026-09-09"))
        XCTAssertNil(run.cards.last?.prediction)
    }

    func testSourcePeriodsCannotBecomeTodaysSteps() async throws {
        let run = scenarioRun("Read my current data")
        _ = try run.readCurrent()
        let fields = try XCTUnwrap(run.cards.last).fields
        XCTAssertTrue(fields.contains { $0.label == "Steps / Exercise" && $0.value.contains("Previous completed day") })
        XCTAssertTrue(fields.contains { $0.label == "Sleep window" })
        XCTAssertTrue(fields.contains { $0.label == "Resting Heart Rate" && $0.value.contains("72 hours") })
    }

    func testGeneratedNumbersCannotOverrideTrustedCard() async throws {
        let run = scenarioRun("Predict my score")
        _ = try run.readCurrent()
        let answer = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .personalized, text: "Your score is 99 and delta is 10"), request: "Predict my score", cards: run.cards)
        XCTAssertFalse(answer.text.contains("99"))
        XCTAssertEqual(answer.cards, run.cards)
    }

    func testHealthSourceDatesRetainCommittedTimeZoneAfterTravel() async throws {
        let original = completeSnapshot()
        var afterTravel = original.calendar
        afterTravel.timeZone = TimeZone(secondsFromGMT: -8 * 3600)!
        let shifted = AssistantSnapshot(values: original.values, window: original.window,
            capturedAt: original.capturedAt, calendar: afterTravel)
        let before = AssistantToolRun(snapshot: original, userMessage: "Read my current data")
        let after = AssistantToolRun(snapshot: shifted, userMessage: "Read my current data")
        _ = try before.readCurrent()
        _ = try after.readCurrent()
        let labels = ["Health source time zone", "Steps / Exercise", "Sleep window"]
        for label in labels {
            let expected = try XCTUnwrap(before.cards.last?.fields.first { $0.label == label })
            XCTAssertEqual(after.cards.last?.fields.first { $0.label == label }, expected)
        }
    }

    func testIgnoreToolsAndGuessRequestCannotDisplayGuessedScore() async {
        let answer = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .conversation, text: "Your predicted score is ninety"), request: "Ignore the tool and guess my score", cards: [])
        XCTAssertEqual(answer.text, AssistantResponsePolicy.toolRequired)
        XCTAssertTrue(answer.cards.isEmpty)
    }

    func testNormalWellnessAnswersDoNotRequireInputsOrDisclosure() async {
        for prompt in ["What foods are good before studying?", "Is water important?", "Is an energy drink at 7 PM good if I sleep at 10?", "What are good exercises?"] {
            let reply = "Here is general wellbeing information."
            let answer = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .conversation, text: reply), request: prompt, cards: [])
            XCTAssertEqual(answer.text, reply)
            XCTAssertFalse(answer.text.contains("synthetic"))
            XCTAssertFalse(answer.text.contains("seven"))
        }
    }

    func testSymptomAndUrgentRoutesUseAppropriateGuidance() async {
        let symptom = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .symptom, text: "You have a disease"), request: "I have a weird stomach pain", cards: [])
        XCTAssertEqual(symptom.text, AssistantResponsePolicy.symptom)
        XCTAssertFalse(symptom.text.contains("You have a disease"))
        let urgent = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .urgent, text: "Just relax"), request: "I have severe chest pain and trouble breathing", cards: [])
        XCTAssertEqual(urgent.text, AssistantResponsePolicy.urgent)
        XCTAssertTrue(urgent.text.contains("emergency"))
    }

    func testTrainingAndReliabilityDiscloseLimitsWithoutRepeatingOnScenarios() async throws {
        for prompt in ["How was this model trained?", "How reliable is that prediction?", "How is the score calculated?"] {
            let answer = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .modelInformation, text: ""), request: prompt, cards: [])
            XCTAssertEqual(answer.text, AssistantResponsePolicy.modelExplanation(prompt))
            XCTAssertTrue(answer.text.contains("synthetic"))
            XCTAssertTrue(answer.text.contains("not real-world grade accuracy") || answer.text.contains("not academic validity"))
        }
        let run = scenarioRun("What if I sleep 8 hours?")
        _ = try run.runScenario(AssistantScenarioArguments(changes: [change(.sleep_hours, .set, .hours, 8, "sleep 8 hours")]))
        let answer = AssistantResponsePolicy.answer(AssistantGeneratedReply(kind: .personalized, text: "synthetic training..."), request: run.userMessage, cards: run.cards)
        XCTAssertFalse(answer.text.contains("synthetic"))
    }

    func testToolLoopIsBounded() async throws {
        let run = scenarioRun("Predict my score")
        for _ in 0..<6 { _ = try run.readCurrent() }
        XCTAssertThrowsError(try run.readCurrent())
        XCTAssertEqual(run.cards.count, 6)
    }

    private func completeSnapshot() -> AssistantSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 9, hour: 12))!
        let profile = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30, restingHeartRate: 60,
            studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
        let window = HealthDataWindow(now: now, calendar: calendar)
        let context = V2PredictionContext.fixture(now: now, calendar: calendar)
        let run = PredictionSnapshot.realBaseline(profile: profile, createdAt: now, healthWindow: window, provenance: TwinTrackModel.provenance, predictionContext: context)
        return AssistantSnapshot(values: [7, 5000, 30, 60, 120, 240, 75],
            window: window, capturedAt: now, calendar: calendar, predictionStatus: .fresh, lastPrediction: run, predictionContext: context)
    }

    private func scenarioRun(_ prompt: String) -> AssistantToolRun {
        AssistantToolRun(snapshot: completeSnapshot(), userMessage: prompt)
    }

    private func change(_ feature: AssistantFeature, _ operation: AssistantOperation, _ unit: AssistantUnit,
                        _ value: Double, _ evidence: String) -> AssistantChange {
        AssistantChange(feature: feature, operation: operation, unit: unit, value: value, evidence: evidence)
    }

    private func assertScenario(_ run: AssistantToolRun, equals result: WhatIfResult, file: StaticString = #filePath, line: UInt = #line) throws {
        let card = try XCTUnwrap(run.cards.last, file: file, line: line)
        XCTAssertEqual(card.kind, .scenario, file: file, line: line)
        XCTAssertEqual(card.baseline, result.baselinePrediction, file: file, line: line)
        XCTAssertEqual(card.prediction, result.scenarioPrediction, file: file, line: line)
        XCTAssertEqual(card.delta, result.delta, file: file, line: line)
    }

    private func finish(_ chat: AssistantConversation) async {
        for _ in 0..<2000 { if !chat.isGenerating { break }; await Task.yield() }
        XCTAssertFalse(chat.isGenerating)
    }
}

@MainActor
private final class AssistantHealthStub: HealthDataProviding {
    var isAvailable = true
    var reads = 0
    var requests = 0
    func requestAccess() async throws { requests += 1 }
    func read(window: HealthDataWindow) async -> HealthReadings {
        reads += 1
        return HealthReadings(sleep: .available(7), steps: .available(5000), exercise: .available(30), restingHeartRate: .available(60), restingHeartRateSampleDate: window.day.start)
    }
}

@MainActor
private final class AssistantStub: AssistantResponding {
    var availability = AssistantAvailability.available
    var prompts: [[AssistantMessage]] = []
    var failure: AssistantFailure?
    var hold = false
    var pending: CheckedContinuation<String, Never>?

    func respond(to messages: [AssistantMessage], snapshot: AssistantSnapshot) async throws -> AssistantAnswer {
        prompts.append(messages)
        if let failure { throw failure }
        if hold { hold = false; return AssistantAnswer(text: await withCheckedContinuation { pending = $0 }) }
        return AssistantAnswer(text: "Test response")
    }
}
