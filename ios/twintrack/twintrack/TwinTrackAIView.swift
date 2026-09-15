import SwiftUI

struct TwinTrackAIView: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var chat = AssistantConversation.forApp()
    @FocusState private var composerFocused: Bool
    @State private var draft = ""
    @State private var showingWhatIf = false
    @State private var showingLibrary = false
    @State private var showingInfo = false
#if DEBUG
    @State private var showingDiagnostic = false
#endif
    @State private var followsLatest = true
    let isActive: Bool

    private var palette: AssistantPalette { AssistantPalette(colorScheme) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        composerFocused = false
                        chat.cancel()
                        showingLibrary = true
                    } label: {
                        Image(systemName: "text.bubble").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Chat Library").accessibilityIdentifier("assistantLibrary")
                    Spacer()
                    Text("TwinTrack AI").font(.headline)
                        .accessibilityIdentifier("pageTitle.TwinTrack AI")
                        .appearanceTestValue()
                    Spacer()
                    Button { newChat() } label: {
                        Image(systemName: "square.and.pencil").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("New Chat").accessibilityIdentifier("assistantNewChat")
                }
                .padding(.horizontal, 12)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if chat.messages.isEmpty { welcome }
                            if chat.reopened {
                                Text("Saved cards are historical. New requests use your current TwinTrack inputs.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if chat.availability != .available {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(chat.availability.message)
                                    Text("Your predictions and manual What-If remain available when their inputs are complete.")
                                        .font(.footnote).foregroundStyle(.secondary)
                                    Button("Check availability") { chat.checkAvailability() }
                                }
                                .padding(14).accessibilityIdentifier("assistantUnavailable")
                            }
                            ForEach(chat.messages) { message in
                                HStack {
                                    if message.role == .user { Spacer(minLength: 28) }
                                    Text(message.role == .assistant ? AssistantReplyReview.formatted(message.text) : AttributedString(message.text))
                                        .textSelection(.enabled)
                                        .padding(14)
                                        .background(message.role == .user ? palette.card : palette.aiSurface,
                                                    in: RoundedRectangle(cornerRadius: 18))
                                        .privacySensitive()
                                    if message.role == .assistant { Spacer(minLength: 16) }
                                }
                                if message.role == .user && message.safetyRefusal == true
                                    && (chat.failure != .safety || message.id != chat.messages.last?.id) {
                                    Text(AssistantFailure.safety.message).font(.footnote).foregroundStyle(.secondary)
                                }
                                ForEach(chat.sources(for: message)) { source in
                                    Link("Guidance reference · \(source.organization): \(source.title)", destination: source.url)
                                        .font(.caption)
                                }
#if DEBUG
                                if message.role == .assistant || message.safetyRefusal == true {
                                    DisclosureGroup("Reply details") {
                                        Text(chat.liveReplyIDs.contains(message.id) ? "New reply this session" : "Saved reply")
                                        Text(message.provenance?.build ?? "Build not recorded")
                                        Text(message.provenance?.origin.rawValue ?? "Route not recorded")
                                        Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    }.font(.caption).foregroundStyle(.secondary)
                                }
#endif
                                if !message.cards.isEmpty {
                                    Text("Historical result · \(message.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption).foregroundStyle(.secondary)
                                    ForEach(message.cards) { AssistantResultCard(card: $0) }
                                }
                            }
                            if chat.isGenerating { ProgressView("Thinking…").accessibilityIdentifier("assistantGenerating") }
                            if let failure = chat.failure { failureCard(failure) }
                            if chat.needsFreshRetry {
                                Button("Try again with current inputs") {
                                    chat.retryWithCurrentInputs(AssistantSnapshot(state: state))
                                }
                                .accessibilityIdentifier("assistantFreshRetry")
                            } else if chat.wasCancelled {
                                Text("Response stopped.").font(.footnote)
                                Button("Retry") { chat.retry() }.accessibilityIdentifier("assistantRetry")
                            }
                            Color.clear.frame(height: 1).id("end")
                        }
                        .padding(16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollBounceBehavior(.always)
                    .accessibilityIdentifier("assistantMessages")
                    .onScrollGeometryChange(for: Bool.self) { geometry in
                        geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height - 80
                    } action: { _, nearEnd in followsLatest = nearEnd }
                    .onChange(of: chat.messages.count) {
                        if followsLatest { proxy.scrollTo("end", anchor: .bottom) }
                    }
                    .onChange(of: composerFocused) {
                        if composerFocused && followsLatest { proxy.scrollTo("end", anchor: .bottom) }
                    }
                }
                if let issue = chat.storageIssue {
                    VStack(alignment: .leading) {
                        Text(issue).font(.caption)
                        Button("Try saving again") { chat.retryStorage() }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 8)
                }
                composer
            }
            .background(palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(palette.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .sheet(isPresented: $showingLibrary) { ConversationLibraryView(chat: chat, onNewChat: newChat) }
            .sheet(isPresented: $showingWhatIf) {
                VStack(spacing: 0) {
                    HStack { Spacer(); Button("Done") { showingWhatIf = false }.padding() }
                    WhatIfView(isActive: isActive && showingWhatIf)
                }
            }
            .sheet(isPresented: $showingInfo) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Text("On-device chat").font(.title2); Spacer(); Button("Done") { showingInfo = false } }
                    Text("Build · \(AssistantProvenance.currentBuild)").accessibilityIdentifier("assistantBuild")
                    Text(AssistantResponsePolicy.disclosure)
#if DEBUG
                    Button("Minimal model check (DEBUG)") { showingDiagnostic = true }
                        .sheet(isPresented: $showingDiagnostic) { ModelDiagnosticView() }
#endif
                    Text("Saved chats stay in this app's local storage and are excluded from system backup. Delete them in Chat Library. Clearing Prediction History does not delete chats or their historical cards.")
                    Spacer()
                }.padding(24)
            }
        }
        .task { chat.checkAvailability() }
        .onChange(of: chat.activeID) { draft = ""; followsLatest = true }
        .onChange(of: isActive) { _, active in
            if !active {
                composerFocused = false
                chat.cancel()
                showingWhatIf = false
                showingLibrary = false
                showingInfo = false
            } else { chat.checkAvailability() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { chat.checkAvailability() }
            else { composerFocused = false; chat.cancel() }
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How can I help?").font(.title2.weight(.semibold))
                .accessibilityIdentifier("assistantWelcome")
            Text("Ask about studying, habits and wellbeing, or explore your TwinTrack data.")
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(chat.availability.message).font(.caption).foregroundStyle(.secondary)
            Button("About on-device chat") { showingInfo = true }.font(.caption)
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--synthetic-chat-ui-tests") {
                Text("Synthetic chat UI test fixture").font(.caption)
            }
#endif
        }
        .padding(.vertical, 12)
    }

    private var composer: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask TwinTrack AI…", text: $draft, axis: .vertical)
                    .focused($composerFocused)
                    .lineLimit(1...4).padding(12)
                    .background(palette.aiSurface, in: RoundedRectangle(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(composerFocused ? palette.aiAccent : palette.aiBorder, lineWidth: composerFocused ? 2 : 1) }
                    .tint(palette.aiAccent)
                    .accessibilityIdentifier("assistantComposer")
                if chat.isGenerating {
                    Button { chat.cancel() } label: { Image(systemName: "stop.fill").frame(width: 44, height: 44) }
                        .accessibilityLabel("Stop response").accessibilityIdentifier("assistantStop")
                } else {
                    Button {
                        followsLatest = true
                        let count = chat.messages.count
                        chat.send(draft, snapshot: AssistantSnapshot(state: state))
                        if chat.messages.count > count { draft = "" }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.title).frame(width: 44, height: 44)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chat.availability != .available)
                    .accessibilityLabel("Send").accessibilityIdentifier("assistantSend")
                }
            }
            HStack(spacing: 8) {
                Button {
                    composerFocused = false
                    showingWhatIf = true
                } label: {
                    Label("Manual What-If", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .background(palette.card, in: Capsule())
                        .overlay { Capsule().stroke(palette.border) }
                }
                .accessibilityIdentifier("assistantManualWhatIf")
                Spacer(minLength: 0)
                if composerFocused {
                    Button { composerFocused = false } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Dismiss keyboard")
                    .accessibilityIdentifier("assistantDismissKeyboard")
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
        .background(palette.background)
        .tint(palette.aiAccent)
        .overlay(alignment: .top) { Rectangle().fill(palette.border).frame(height: 1) }
    }

    private func failureCard(_ failure: AssistantFailure) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle").foregroundStyle(.secondary)
                Text(failure.message).font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            if failure != .safety {
                Button("Retry") { chat.retry() }
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    .accessibilityIdentifier("assistantRetry")
            }
            if failure == .contextLimit { Button("Start new chat") { newChat() } }
#if DEBUG
            DisclosureGroup("Diagnostic category") {
                Text(failure.rawValue).font(.caption).foregroundStyle(.secondary)
            }.font(.caption)
#endif
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(palette.border) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assistantError")
    }

    private func newChat() {
        composerFocused = false
        chat.reset()
        if chat.activeID == nil { draft = ""; followsLatest = true }
    }
}

private struct ConversationLibraryView: View {
    @ObservedObject var chat: AssistantConversation
    let onNewChat: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var renaming: SavedConversation?
    @State private var title = ""
    @State private var deleting: SavedConversation?

    var body: some View {
        NavigationStack {
            List {
                if let issue = chat.storageIssue {
                    Text(issue).font(.footnote)
                    Button("Try saving again") { chat.retryStorage() }
                }
                if chat.conversations.isEmpty {
                    Text("No saved chats").foregroundStyle(.secondary)
                }
                ForEach(chat.conversations) { conversation in
                    HStack {
                        Button {
                            chat.open(conversation.id)
                            if chat.activeID == conversation.id { dismiss() }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title).lineLimit(2)
                                Text(conversation.updatedAt, format: .dateTime.month().day().hour().minute())
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Menu {
                            Button("Rename") { title = conversation.title; renaming = conversation }
                            Button("Delete", role: .destructive) { deleting = conversation }
                        } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                        .accessibilityLabel("Chat options for \(conversation.title)")
                    }
                    .privacySensitive()
                }
                Text("Chats are stored locally. Historical cards are read-only. Deleting a chat does not delete Prediction History.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Chat Library").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onNewChat()
                        if chat.activeID == nil { dismiss() }
                    } label: { Image(systemName: "square.and.pencil") }
                    .accessibilityLabel("New Chat")
                }
            }
            .alert("Rename Chat", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                TextField("Chat title", text: $title)
                Button("Save") { if let renaming { _ = chat.rename(renaming.id, to: title) } }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Chat?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("Delete Chat", role: .destructive) { if let deleting { _ = chat.delete(deleting.id) } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes this chat and its historical cards only. Prediction History and TwinTrack inputs stay unchanged.")
            }
        }
    }
}

// Opt-in DEBUG fixtures never touch the real library or use health values.
// A disposable synthetic file lets UI tests verify an actual app relaunch.
extension AssistantConversation {
    static func forApp() -> AssistantConversation {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--synthetic-chat-ui-tests") {
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "--synthetic-chat-library"),
               arguments.indices.contains(index + 1),
               let fixtureID = UUID(uuidString: arguments[index + 1]) {
                let directory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("SyntheticChatUITests-\(fixtureID.uuidString)", isDirectory: true)
                return AssistantConversation(service: SyntheticChatUIService(), store: FileConversationStore(directory: directory))
            }
            return AssistantConversation(service: SyntheticChatUIService(), store: MemoryConversationStore())
        }
#endif
        return AssistantConversation()
    }
}

#if DEBUG
@MainActor
private final class SyntheticChatUIService: AssistantResponding {
    private var hasFailed = false
    let availability = AssistantAvailability.available
    func respond(to messages: [AssistantMessage], snapshot: AssistantSnapshot) async throws -> AssistantAnswer {
        if ProcessInfo.processInfo.arguments.contains("--synthetic-chat-error"), !hasFailed {
            hasFailed = true
            throw AssistantFailure.decoding
        }
        return AssistantAnswer(text: String(repeating: "Synthetic response: choose one study task, take a short break, and review what you learned.\n\n", count: 18))
    }
}
#endif

struct AssistantPalette {
    let scheme: ColorScheme
    init(_ scheme: ColorScheme) { self.scheme = scheme }
    var background: Color {
        scheme == .dark ? Color(red: 7/255, green: 11/255, blue: 18/255) : Color(red: 241/255, green: 244/255, blue: 248/255)
    }
    var border: Color { scheme == .dark ? Color.white.opacity(0.08) : Color(red: 221/255, green: 227/255, blue: 236/255) }
    var card: Color { scheme == .dark ? Color.white.opacity(0.045) : .white }
    // Approved violet tokens from the UI handoff; deterministic cards keep cyan.
    var aiAccent: Color {
        scheme == .dark ? Color(red: 154/255, green: 143/255, blue: 240/255) : Color(red: 91/255, green: 75/255, blue: 196/255)
    }
    var aiSurface: Color {
        scheme == .dark ? Color(red: 139/255, green: 127/255, blue: 232/255).opacity(0.06) : Color(red: 242/255, green: 240/255, blue: 253/255)
    }
    var aiBorder: Color {
        scheme == .dark ? Color(red: 139/255, green: 127/255, blue: 232/255).opacity(0.16) : Color(red: 218/255, green: 212/255, blue: 246/255)
    }
    var accent: Color {
        scheme == .dark ? Color(red: 90/255, green: 200/255, blue: 240/255) : Color(red: 14/255, green: 127/255, blue: 184/255)
    }
}
