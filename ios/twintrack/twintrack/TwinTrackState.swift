import Combine
import Foundation

enum ManualDuration {
    static let maximumHours = 15

    static func totalMinutes(hours: Int, minutes: Int) -> Int? {
        guard (0...maximumHours).contains(hours), (0...59).contains(minutes) else {
            return nil
        }

        return (hours * 60) + minutes
    }

    static func parts(from totalMinutes: Int) -> (hours: Int, minutes: Int)? {
        guard totalMinutes >= 0, totalMinutes <= (maximumHours * 60) + 59 else {
            return nil
        }

        return (totalMinutes / 60, totalMinutes % 60)
    }
}

enum PreviousScoreInput {
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let value = Double(trimmed),
              value.isFinite,
              (0...100).contains(value) else {
            return nil
        }

        return value
    }

    static func isValidDraft(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parse(text) != nil
    }
}

@MainActor
final class TwinTrackState: ObservableObject {
    // One published snapshot replaces all four values together. Computed properties
    // preserve the existing Ridge boundary without creating duplicate health storage.
    @Published private(set) var healthReadings = HealthReadings()
    @Published private(set) var healthWindow: HealthDataWindow?
    @Published private(set) var healthAccess: HealthAccessState
    @Published private(set) var isRefreshingHealth = false

    var sleepHours: Double? { healthReadings.sleep.value }
    var steps: Double? { healthReadings.steps.value }
    var exerciseMinutes: Double? { healthReadings.exercise.value }
    var restingHeartRate: Double? { healthReadings.restingHeartRate.value }

    @Published private(set) var studyMinutes: Int?
    @Published private(set) var screenTimeMinutes: Int?
    @Published private(set) var previousScore: Double?

    private let defaults: UserDefaults
    private let healthService: any HealthDataProviding
    private var healthGeneration = 0
    private var isHealthSceneActive = true

    private enum Key {
        static let studyMinutes = "twintrack.manual.study_minutes"
        static let screenTimeMinutes = "twintrack.manual.screen_time_minutes"
        static let previousScore = "twintrack.manual.previous_score"
        static let healthRequestCompleted = "twintrack.health.fourTypeRequestCompleted"
    }

    init(defaults: UserDefaults = .standard, healthService: (any HealthDataProviding)? = nil) {
        self.defaults = defaults
        self.healthService = healthService ?? HealthKitService()
        healthAccess = defaults.bool(forKey: Key.healthRequestCompleted) ? .completed : .notRequested

        if defaults.object(forKey: Key.studyMinutes) != nil {
            studyMinutes = defaults.integer(forKey: Key.studyMinutes)
        }

        if defaults.object(forKey: Key.screenTimeMinutes) != nil {
            screenTimeMinutes = defaults.integer(forKey: Key.screenTimeMinutes)
        }

        if defaults.object(forKey: Key.previousScore) != nil {
            previousScore = defaults.double(forKey: Key.previousScore)
        }
    }

    func requestHealthAccess() async {
        guard healthAccess != .requesting else { return }
        guard healthService.isAvailable else {
            clearHealthValues()
            healthAccess = .unavailable
            return
        }
        clearHealthValues()
        healthAccess = .requesting
        do {
            try await healthService.requestAccess()
            // Persist only that the system request completed, never a read permission
            // decision. Denying all reads may still successfully complete this request.
            defaults.set(true, forKey: Key.healthRequestCompleted)
            healthAccess = .completed
            await refreshHealth()
        } catch {
            healthAccess = .failed
        }
    }

    func refreshHealth(now: Date = Date(), calendar: Calendar = .current) async {
        guard isHealthSceneActive, !isRefreshingHealth, healthAccess != .requesting else { return }
        guard healthService.isAvailable else {
            clearHealthValues()
            healthAccess = .unavailable
            return
        }
        // Launch/foreground never springs an authorization sheet on the user. The
        // Apple Health action initiates it; subsequent launches refresh accessible data.
        guard defaults.bool(forKey: Key.healthRequestCompleted) else { return }
        healthAccess = .completed
        healthGeneration += 1
        let generation = healthGeneration
        let window = HealthDataWindow(now: now, calendar: calendar)
        healthWindow = window
        healthReadings = HealthReadings()
        isRefreshingHealth = true
        let readings = await healthService.read(window: window)
        guard generation == healthGeneration else { return }
        isRefreshingHealth = false
        guard !Task.isCancelled else { return }
        healthReadings = readings
    }

    func clearHealthValues() {
        // Clear on scene deactivation to limit private values in inactive UI, and
        // invalidate in-flight work so it cannot overwrite a later foreground refresh.
        healthGeneration += 1
        healthReadings = HealthReadings()
        healthWindow = nil
        isRefreshingHealth = false
    }

    func healthSceneChanged(isActive: Bool) {
        isHealthSceneActive = isActive
        if !isActive { clearHealthValues() }
    }

    var missingInputs: [TwinTrackFeature] {
        let values: [Double?] = [sleepHours, steps, exerciseMinutes, restingHeartRate,
                                 studyMinutes.map(Double.init), screenTimeMinutes.map(Double.init), previousScore]
        return TwinTrackFeature.allCases.filter { values[$0.rawValue] == nil }
    }

    @discardableResult
    func setStudyTime(hours: Int, minutes: Int) -> Bool {
        guard let total = ManualDuration.totalMinutes(hours: hours, minutes: minutes) else {
            return false
        }

        studyMinutes = total
        defaults.set(total, forKey: Key.studyMinutes)
        return true
    }

    @discardableResult
    func setScreenTime(hours: Int, minutes: Int) -> Bool {
        guard let total = ManualDuration.totalMinutes(hours: hours, minutes: minutes) else {
            return false
        }

        screenTimeMinutes = total
        defaults.set(total, forKey: Key.screenTimeMinutes)
        return true
    }

    @discardableResult
    func setPreviousScore(_ score: Double) -> Bool {
        guard score.isFinite, (0...100).contains(score) else {
            return false
        }

        previousScore = score
        defaults.set(score, forKey: Key.previousScore)
        return true
    }

    @discardableResult
    func saveManualInputs(
        studyMinutes: Int?,
        screenTimeMinutes: Int?,
        previousScore: Double?
    ) -> Bool {
        guard isValidDuration(studyMinutes),
              isValidDuration(screenTimeMinutes),
              previousScore.map({ $0.isFinite && (0...100).contains($0) }) ?? true else {
            return false
        }

        self.studyMinutes = studyMinutes
        self.screenTimeMinutes = screenTimeMinutes
        self.previousScore = previousScore

        persist(studyMinutes, key: Key.studyMinutes)
        persist(screenTimeMinutes, key: Key.screenTimeMinutes)
        persist(previousScore, key: Key.previousScore)
        return true
    }

    var completeProfile: TwinTrackProfile? {
        guard let sleepHours,
              let steps,
              let exerciseMinutes,
              let restingHeartRate,
              let studyMinutes,
              let screenTimeMinutes,
              let previousScore else {
            return nil
        }

        return TwinTrackProfile(
            sleepHours: sleepHours,
            steps: steps,
            exerciseMinutes: exerciseMinutes,
            restingHeartRate: restingHeartRate,
            studyMinutes: Double(studyMinutes),
            screenTimeMinutes: Double(screenTimeMinutes),
            previousScore: previousScore
        )
    }

    /// The frozen Ridge engine is reached only through a complete seven-value profile.
    /// Missing inputs therefore cannot become fabricated prediction inputs.
    var currentPrediction: Double? {
        completeProfile.map(TwinTrackModel.predict)
    }

    private func isValidDuration(_ value: Int?) -> Bool {
        value.map { ManualDuration.parts(from: $0) != nil } ?? true
    }

    private func persist(_ value: Int?, key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func persist(_ value: Double?, key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
