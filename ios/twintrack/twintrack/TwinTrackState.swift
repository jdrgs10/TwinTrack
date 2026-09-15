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
    @Published private(set) var predictionHistory: [PredictionSnapshot]
    @Published private(set) var lastPrediction: PredictionSnapshot?
    @Published private(set) var predictionIssue: String?
    private var historyReadable = true

    private let defaults: UserDefaults
    private let healthService: any HealthDataProviding
    private let historyStore: any PredictionHistoryPersisting
    private var healthGeneration = 0
    private var isHealthSceneActive = true

    private enum Key {
        static let studyMinutes = "twintrack.manual.study_minutes"
        static let screenTimeMinutes = "twintrack.manual.screen_time_minutes"
        static let previousScore = "twintrack.manual.previous_score"
        static let healthRequestCompleted = "twintrack.health.fourTypeRequestCompleted"
    }

    init(
        defaults: UserDefaults = .standard,
        healthService: (any HealthDataProviding)? = nil,
        historyStore: (any PredictionHistoryPersisting)? = nil
    ) {
        self.defaults = defaults
        self.healthService = healthService ?? HealthKitService()
        self.historyStore = historyStore ?? UserDefaultsPredictionHistoryStore(defaults: defaults)
        do {
            let loaded = try self.historyStore.load()
            predictionHistory = loaded
            lastPrediction = loaded.last
        } catch {
            predictionHistory = []
            historyReadable = false
            predictionIssue = "Saved history could not be read. It has not been replaced."
        }
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
        // Completed setup is not a read-permission verdict. Reuse refresh without
        // clearing values or presenting the authorization workflow again.
        if defaults.bool(forKey: Key.healthRequestCompleted) {
            await refreshHealth()
            return
        }
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
        isRefreshingHealth = true
        let readings = await healthService.read(window: window)
        guard generation == healthGeneration else { return }
        defer { isRefreshingHealth = false }
        guard !Task.isCancelled else { return }
        // Keep the last committed values and their source window while awaiting
        // queries. Commit all four results together, with no intervening suspension.
        healthWindow = window
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
        previousScore: Double?,
        now: Date = Date()
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

    @discardableResult
    func clearPredictionHistory() -> Bool {
        guard historyReadable else { return false }
        do {
            try historyStore.save([])
            predictionHistory = []
            return true
        } catch {
            return false
        }
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

    /// Reading state never executes Ridge. Only an eligible explicit run is current.
    var currentPrediction: Double? {
        predictionStatus() == .fresh ? lastPrediction?.prediction : nil
    }

    func predictionStatus(now: Date = Date(), calendar: Calendar = .current) -> PredictionStatus {
        if isRefreshingHealth { return .refreshing }
        guard let profile = completeProfile else { return .missing }
        guard TwinTrackFeature.allCases.allSatisfy({ WhatIfScenario.isValid(WhatIfScenario.value($0, in: profile), for: $0) }),
              let window = healthWindow else { return .needsRefresh }
        let expected = HealthDataWindow(now: now, calendar: calendar)
        guard window.day == expected.day, window.sleep.start == expected.sleep.start,
              window.timeZone == expected.timeZone else { return .needsRefresh }
        if let sampleDate = healthReadings.restingHeartRateSampleDate,
           !(expected.restingHeartRate.start...expected.restingHeartRate.end).contains(sampleDate) { return .needsRefresh }
        guard let lastPrediction else { return .ready }
        let source = PredictionHealthWindow(window, restingHeartRateSampleDate: healthReadings.restingHeartRateSampleDate)
        return lastPrediction.provenance == "explicitRun.v1"
            && lastPrediction.inputs == PredictionInputs(profile: profile)
            && lastPrediction.healthWindow?.hasSameSourceIdentity(as: source) == true ? .fresh : .stale
    }

    @discardableResult
    func runPrediction(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let status = predictionStatus(now: now, calendar: calendar)
        guard [.ready, .fresh, .stale].contains(status), historyReadable else { return false }
        // This synchronous main-actor action cannot see half a Health commit or
        // overlap another tap. An equivalent run is reused even after Clear History.
        if status == .fresh { return true }
        guard let profile = completeProfile,
              let snapshot = PredictionSnapshot.realBaseline(profile: profile, createdAt: now,
                healthWindow: healthWindow, restingHeartRateSampleDate: healthReadings.restingHeartRateSampleDate,
                provenance: "explicitRun.v1") else { return false }
        do {
            let updated = (predictionHistory + [snapshot]).sorted { $0.createdAt < $1.createdAt }
            try historyStore.save(updated)
            predictionHistory = updated
            lastPrediction = snapshot
            predictionIssue = nil
            return true
        } catch {
            predictionIssue = "Prediction could not be saved. Your existing history is unchanged. Try Run Prediction again."
            return false
        }
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
