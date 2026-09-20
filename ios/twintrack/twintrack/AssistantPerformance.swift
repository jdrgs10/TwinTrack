import Foundation

/// Timing-only DEBUG diagnostics. Never records text, paths, images or identifiers.
@MainActor
enum AssistantPerformance {
    enum Event: String {
        case tabSelected, tabActivationObserved, tabAppeared, composerTapped, composerFocused, keyboardWillShow, keyboardVisible
        case availability, conversationInit, historyLoad, sessionInit, profileImageLoad
    }
#if DEBUG
    private static var records: [(Event, Double, Double)] = []
    private static let start = ProcessInfo.processInfo.systemUptime
    static var summary: String {
        records.map { "\($0.0.rawValue) at \(String(format: "%.2f", $0.1)) ms; duration \(String(format: "%.2f", $0.2)) ms" }.joined(separator: "\n")
    }
#endif
    static func mark(_ event: Event, duration: Double = 0) {
#if DEBUG
        let elapsed = max(0, (ProcessInfo.processInfo.systemUptime - start) * 1000)
        records.append((event, elapsed, duration * 1000))
        if records.count > 100 { records.removeFirst() }
#endif
    }

    static func measure<T>(_ event: Event, _ operation: () throws -> T) rethrows -> T {
#if DEBUG
        let began = ProcessInfo.processInfo.systemUptime
        defer { mark(event, duration: ProcessInfo.processInfo.systemUptime - began) }
#endif
        return try operation()
    }
}
