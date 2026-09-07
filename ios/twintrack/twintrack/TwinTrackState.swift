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

final class TwinTrackState: ObservableObject {
    // HealthKit will populate these optional values in a later milestone.
    // Until then, nil prevents the app from constructing a fake complete prediction.
    @Published private(set) var sleepHours: Double?
    @Published private(set) var steps: Double?
    @Published private(set) var exerciseMinutes: Double?
    @Published private(set) var restingHeartRate: Double?

    @Published private(set) var studyMinutes: Int?
    @Published private(set) var screenTimeMinutes: Int?
    @Published private(set) var previousScore: Double?

    private let defaults: UserDefaults

    private enum Key {
        static let studyMinutes = "twintrack.manual.study_minutes"
        static let screenTimeMinutes = "twintrack.manual.screen_time_minutes"
        static let previousScore = "twintrack.manual.previous_score"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

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
