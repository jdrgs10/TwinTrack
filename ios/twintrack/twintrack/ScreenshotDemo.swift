#if DEBUG && targetEnvironment(simulator)
import Foundation

/// Enable in Scheme → Run → Arguments with --screenshot-mode.
/// Disable the argument and relaunch to return to the normal HealthKit path.
/// Manual entries persist only in the demo suite; predictions last for this launch only.
@MainActor
enum ScreenshotDemo {
    static let launchArgument = "--screenshot-mode"

    static func state(arguments: [String] = ProcessInfo.processInfo.arguments) -> TwinTrackState {
        // UI tests use an isolated UUID session without overwriting screenshot entries.
        let session: String
        if let index = arguments.firstIndex(of: "--screenshot-session"),
           arguments.indices.contains(index + 1), let id = UUID(uuidString: arguments[index + 1]) {
            session = id.uuidString
        } else { session = "Home" }
        let defaults = UserDefaults(suiteName: suiteName(session: session))!
        defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        return TwinTrackState(defaults: defaults, healthService: Readings(), historyStore: TransientHistory())
    }

    static func suiteName(session: String) -> String { "TwinTrack.DebugScreenshot.\(session)" }

    private struct Readings: HealthDataProviding {
        let isAvailable = true
        func requestAccess() async throws {}
        func read(window: HealthDataWindow) async -> HealthReadings {
            HealthReadings(sleep: .available(7 + 42.0 / 60), steps: .available(7850),
                exercise: .available(42), restingHeartRate: .available(62),
                restingHeartRateSampleDate: window.day.start)
        }
    }

    private final class TransientHistory: PredictionHistoryPersisting {
        private var snapshots: [PredictionSnapshot] = []
        func load() throws -> [PredictionSnapshot] { snapshots }
        func save(_ snapshots: [PredictionSnapshot]) throws { self.snapshots = snapshots }
    }
}
#endif
