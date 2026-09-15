import Foundation
import FoundationModels
import Combine

@MainActor
protocol FoundationTextGenerating {
    var availability: AssistantAvailability { get }
    func reply(to prompt: String, instructions: String) async throws -> String
}

/// Each attempt gets a fresh, text-only session. No tool schema or app data is
/// implicitly attached. Tests replace this boundary without invoking the model.
@MainActor
struct FoundationTextClient: FoundationTextGenerating {
    var availability: AssistantAvailability {
        FoundationAssistantService.availability(SystemLanguageModel.default.availability)
    }

    func reply(to prompt: String, instructions: String) async throws -> String {
        guard availability == .available else { throw AssistantFailure.forAvailability(availability) }
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt,
                options: GenerationOptions(maximumResponseTokens: 450))
            try Task.checkCancellation()
            guard !response.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AssistantFailure.emptyResponse
            }
            return response.content
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AssistantFailure.classify(error)
        }
    }
}

extension AssistantFailure {
    static func forAvailability(_ status: AssistantAvailability) -> AssistantFailure {
        switch status {
        case .available: .failed
        case .notReady: .assetsNotReady
        case .disabled, .unsupported, .unavailable: .unavailable
        }
    }

    // Only typed categories cross this boundary. Never inspect or retain an
    // error's description, transcript, underlying tool output, or refusal text.
    static func classify(_ error: Error) -> AssistantFailure {
        if let failure = error as? AssistantFailure { return failure }
        if error is CancellationError { return .cancelled }
        if error is LanguageModelSession.ToolCallError { return .toolFailure }
        guard let error = error as? LanguageModelSession.GenerationError else { return .failed }
        switch error {
        case .exceededContextWindowSize: return .contextLimit
        case .assetsUnavailable: return .assetsNotReady
        case .guardrailViolation, .refusal: return .safety
        case .unsupportedGuide: return .unsupportedGuide
        case .unsupportedLanguageOrLocale: return .language
        case .decodingFailure: return .decoding
        case .rateLimited: return .rateLimited
        case .concurrentRequests: return .busy
        @unknown default: return .failed
        }
    }
}

#if DEBUG
import SwiftUI

enum ModelProbePrompt: String, CaseIterable, Identifiable {
    case greeting = "Hello"
    case food = "What are some good foods to eat before studying?"
    case revision = "How can I organize an evening revision session?"
    case caffeine = "I drink an energy drink at 7 PM and want to sleep at 10 PM. What should I consider?"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .greeting: "Greeting"
        case .food: "Study food"
        case .revision: "Revision"
        case .caffeine: "Caffeine timing"
        }
    }
}

struct ModelProbeResult: Identifiable {
    let prompt: ModelProbePrompt
    let failure: AssistantFailure?
    var id: String { prompt.id }
    var status: String { failure?.rawValue ?? "PASS" }
}

@MainActor
final class ModelDiagnostic: ObservableObject {
    @Published private(set) var results: [ModelProbeResult] = []
    @Published private(set) var running = false
    @Published private(set) var originalFoodStatus: String?
    @Published private(set) var checkingUpdatedPath = false
    @Published private(set) var availability: AssistantAvailability
    private let client: any FoundationTextGenerating
    private var task: Task<Void, Never>?
    private var generation = 0

    init(client: (any FoundationTextGenerating)? = nil) {
        let client = client ?? FoundationTextClient()
        self.client = client
        availability = client.availability
    }

    func run(updatedPath: Bool = false) {
        guard !running else { return }
        availability = client.availability
        guard availability == .available else { return }
        generation += 1
        let token = generation
        results = []
        originalFoodStatus = nil
        checkingUpdatedPath = updatedPath
        running = true
        task = Task { [weak self, client] in
            for prompt in ModelProbePrompt.allCases {
                let failure: AssistantFailure?
                do {
                    if updatedPath {
                        _ = try await FoundationAssistantService().respond(
                            to: [AssistantMessage(role: .user, text: prompt.rawValue)], snapshot: AssistantSnapshot())
                    } else {
                        _ = try await client.reply(to: prompt.rawValue, instructions: "Answer briefly and helpfully.")
                    }
                    failure = nil
                } catch {
                    failure = AssistantFailure.classify(error)
                }
                guard let self, self.generation == token, !Task.isCancelled else { return }
                self.results.append(ModelProbeResult(prompt: prompt, failure: failure))
            }
            guard let self, self.generation == token else { return }
            self.running = false
            self.task = nil
        }
    }

    func stop() {
        generation += 1
        task?.cancel()
        task = nil
        running = false
    }

    func compareOriginalFoodPath() {
        guard !running, !checkingUpdatedPath, results.count == 4, results.allSatisfy({ $0.failure == nil }) else { return }
        generation += 1
        let token = generation
        running = true
        task = Task { [weak self] in
            let status: String
            do { status = try await FoundationAssistantService.originalFoodProbe() }
            catch { status = AssistantFailure.classify(error).rawValue }
            guard let self, self.generation == token, !Task.isCancelled else { return }
            self.originalFoodStatus = status
            self.running = false
            self.task = nil
        }
    }
}

struct ModelDiagnosticView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diagnostic = ModelDiagnostic()

    var body: some View {
        NavigationStack {
            List {
                Section("Minimal session — DEBUG only") {
                    Text("Four fixed synthetic prompts. Fresh text-only sessions. No tools, app inputs, chat replay or saved results.")
                    Text(diagnostic.availability.message)
                        .accessibilityIdentifier("modelDiagnosticAvailability")
                    if diagnostic.availability != .available {
                        Text("PHYSICAL TEST REQUIRED")
                    }
                    Text(diagnostic.checkingUpdatedPath ? "Updated chat path" : "Minimal text path")
                    ForEach(diagnostic.results) { result in
                        Text("\(result.prompt.label): \(result.status)")
                    }
                    if let status = diagnostic.originalFoodStatus { Text("Original food path: \(status)") }
                    if diagnostic.running {
                        ProgressView("Checking minimal sessions…")
                        Button("Stop") { diagnostic.stop() }
                    } else {
                        Button("Run minimal check") { diagnostic.run() }
                            .disabled(diagnostic.availability != .available)
                            .accessibilityIdentifier("modelDiagnosticRun")
                        Button("Check updated chat path") { diagnostic.run(updatedPath: true) }
                            .disabled(diagnostic.availability != .available)
                        Button("Compare original food path") { diagnostic.compareOriginalFoodPath() }
                            .disabled(diagnostic.checkingUpdatedPath || diagnostic.results.count != 4 || diagnostic.results.contains { $0.failure != nil })
                    }
                }
            }
            .navigationTitle("Model check").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { diagnostic.stop(); dismiss() }
                }
            }
        }
        .onDisappear { diagnostic.stop() }
    }
}
#endif
