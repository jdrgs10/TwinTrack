import Foundation

struct PredictionInputs: Codable, Equatable, Sendable {
    let sleepHours: Double
    let steps: Double
    let exerciseMinutes: Double
    let restingHeartRate: Double
    let studyMinutes: Double
    let screenTimeMinutes: Double
    let previousScore: Double

    init(profile: TwinTrackProfile) {
        sleepHours = profile.sleepHours
        steps = profile.steps
        exerciseMinutes = profile.exerciseMinutes
        restingHeartRate = profile.restingHeartRate
        studyMinutes = profile.studyMinutes
        screenTimeMinutes = profile.screenTimeMinutes
        previousScore = profile.previousScore
    }

    var profile: TwinTrackProfile {
        TwinTrackProfile(
            sleepHours: sleepHours,
            steps: steps,
            exerciseMinutes: exerciseMinutes,
            restingHeartRate: restingHeartRate,
            studyMinutes: studyMinutes,
            screenTimeMinutes: screenTimeMinutes,
            previousScore: previousScore
        )
    }

    var isValid: Bool {
        let nonnegative = [sleepHours, steps, exerciseMinutes, studyMinutes, screenTimeMinutes]
        return nonnegative.allSatisfy { $0.isFinite && $0 >= 0 }
            && restingHeartRate.isFinite && restingHeartRate > 0
            && previousScore.isFinite && (0...100).contains(previousScore)
    }
}

struct PredictionHealthWindow: Codable, Equatable, Sendable {
    let dayStart: Date
    let dayEnd: Date
    let sleepStart: Date
    let sleepEnd: Date
    let timeZoneIdentifier: String
    // Missing on legacy snapshots: their RHR used the completed-day average.
    let semanticsVersion: Int?
    let restingHeartRateSampleDate: Date?

    init(_ window: HealthDataWindow, restingHeartRateSampleDate: Date? = nil) {
        dayStart = window.day.start
        dayEnd = window.day.end
        sleepStart = window.sleep.start
        sleepEnd = window.sleep.end
        timeZoneIdentifier = window.timeZone.identifier
        semanticsVersion = 2
        self.restingHeartRateSampleDate = restingHeartRateSampleDate
    }

    var isValid: Bool {
        dayStart < dayEnd && sleepStart < sleepEnd && !timeZoneIdentifier.isEmpty
            && (restingHeartRateSampleDate?.timeIntervalSinceReferenceDate.isFinite ?? true)
    }

    func hasSameSourceIdentity(as other: Self) -> Bool {
        guard semanticsVersion == 2, other.semanticsVersion == 2 else { return self == other }
        // A morning query ends at now. That advancing cutoff alone is not a new
        // source when the inputs, overnight period, activity day and RHR sample match.
        return dayStart == other.dayStart && dayEnd == other.dayEnd
            && sleepStart == other.sleepStart && timeZoneIdentifier == other.timeZoneIdentifier
            && restingHeartRateSampleDate == other.restingHeartRateSampleDate
    }
}

struct PredictionSnapshot: Identifiable, Codable, Equatable, Sendable {
    // Value semantics and let-only fields keep past predictions independent from
    // later edits to TwinTrackState.
    let id: UUID
    let createdAt: Date
    let prediction: Double
    let inputs: PredictionInputs
    let healthWindow: PredictionHealthWindow?
    // Absent means a legacy event; never relabel it as an explicit user run.
    let provenance: String?

    init(
        id: UUID = UUID(),
        createdAt: Date,
        prediction: Double,
        inputs: PredictionInputs,
        healthWindow: PredictionHealthWindow?,
        provenance: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.prediction = prediction
        self.inputs = inputs
        self.healthWindow = healthWindow
        self.provenance = provenance
    }

    static func realBaseline(
        profile: TwinTrackProfile,
        createdAt: Date,
        healthWindow: HealthDataWindow?,
        restingHeartRateSampleDate: Date? = nil,
        provenance: String? = nil
    ) -> PredictionSnapshot? {
        let inputs = PredictionInputs(profile: profile)
        let prediction = TwinTrackModel.predict(profile)
        guard inputs.isValid,
              createdAt.timeIntervalSinceReferenceDate.isFinite,
              prediction.isFinite,
              (0...100).contains(prediction) else {
            return nil
        }

        let storedHealthWindow: PredictionHealthWindow?
        if let healthWindow {
            storedHealthWindow = PredictionHealthWindow(
                healthWindow, restingHeartRateSampleDate: restingHeartRateSampleDate
            )
        } else {
            storedHealthWindow = nil
        }

        return PredictionSnapshot(
            createdAt: createdAt,
            prediction: prediction,
            inputs: inputs,
            healthWindow: storedHealthWindow,
            provenance: provenance
        )
    }

    var isValid: Bool {
        createdAt.timeIntervalSinceReferenceDate.isFinite
            && prediction.isFinite
            && (0...100).contains(prediction)
            && inputs.isValid
            && (healthWindow?.isValid ?? true)
    }

    func hasSameSourceIdentity(as other: PredictionSnapshot) -> Bool {
        // Timestamp and derived prediction are deliberately excluded. The real
        // inputs and Health source metadata define whether a snapshot is new.
        guard inputs == other.inputs else { return false }
        switch (healthWindow, other.healthWindow) {
        case (nil, nil): return true
        case let (window?, otherWindow?): return window.hasSameSourceIdentity(as: otherWindow)
        default: return false
        }
    }
}

protocol PredictionHistoryPersisting {
    func load() throws -> [PredictionSnapshot]
    func save(_ snapshots: [PredictionSnapshot]) throws
}

struct UserDefaultsPredictionHistoryStore: PredictionHistoryPersisting {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "twintrack.prediction.history.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> [PredictionSnapshot] {
        guard let stored = defaults.object(forKey: key) else { return [] }
        guard let data = stored as? Data else { throw PredictionStorageError.unreadable }
        let decoded = try JSONDecoder().decode([PredictionSnapshot].self, from: data)
        guard decoded.allSatisfy(\.isValid) else { throw PredictionStorageError.unreadable }
        return decoded.sorted { $0.createdAt < $1.createdAt }
    }

    func save(_ snapshots: [PredictionSnapshot]) throws {
        guard !snapshots.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(try JSONEncoder().encode(snapshots), forKey: key)
    }
}

enum PredictionStorageError: Error { case unreadable }

enum PredictionStatus: Equatable, Sendable {
    case missing, refreshing, needsRefresh, ready, fresh, stale
}

struct PredictionTrendPoint: Equatable, Sendable {
    let day: Date
    let snapshot: PredictionSnapshot
}

enum PredictionHistoryTrend {
    static func points(
        from snapshots: [PredictionSnapshot],
        now: Date,
        calendar: Calendar
    ) -> [PredictionTrendPoint] {
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -6, to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else {
            return []
        }

        var latestByDay: [Date: PredictionSnapshot] = [:]
        for snapshot in snapshots where snapshot.createdAt >= start && snapshot.createdAt < end {
            let day = calendar.startOfDay(for: snapshot.createdAt)
            // Full history remains intact; only the chart chooses the latest real
            // snapshot per local day. Days without a snapshot never gain a value.
            if latestByDay[day].map({ $0.createdAt < snapshot.createdAt }) ?? true {
                latestByDay[day] = snapshot
            }
        }

        return latestByDay
            .map { PredictionTrendPoint(day: $0.key, snapshot: $0.value) }
            .sorted { $0.day < $1.day }
    }

    static func days(now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
}
