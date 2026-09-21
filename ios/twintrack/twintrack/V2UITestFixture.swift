#if DEBUG
import Foundation

/// Opt-in, isolated synthetic data for the V2 UI regression; never uses HealthKit.
@MainActor
enum V2UITestFixture {
    static func state(id: UUID) -> TwinTrackState {
        let defaults = UserDefaults(suiteName: "TwinTrack.V2UITests.\(id.uuidString)")!
        let calendar = Calendar.current
        let now = Date(), today = calendar.startOfDay(for: Date())
        let firstLaunch = !defaults.bool(forKey: "fixtureSeeded")
        if firstLaunch {
            let input = TwinTrackProfile(sleepHours: 7, steps: 5000, exerciseMinutes: 30,
                restingHeartRate: 60, studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75)
            let legacy = PredictionSnapshot(createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                prediction: TwinTrackModelV1.predict(input), inputs: PredictionInputs(profile: input), healthWindow: nil,
                provenance: "explicitRun.v1")
            try? UserDefaultsPredictionHistoryStore(defaults: defaults).save([legacy])
            defaults.set(true, forKey: "twintrack.health.fourTypeRequestCompleted")
        }
        let state = TwinTrackState(defaults: defaults, healthService: Readings())
        if firstLaunch {
            let context = V2PredictionContext(subject: "Synthetic maths", assessmentName: "Synthetic quiz",
                assessmentDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                previousDate: calendar.date(byAdding: .day, value: -14, to: today)!,
                manualDay: calendar.date(byAdding: .day, value: -1, to: today)!, timeZoneIdentifier: calendar.timeZone.identifier,
                sameSubjectConfirmed: true, nextIndividualAssessmentConfirmed: true, latestComparablePriorConfirmed: true)
            state.saveManualInputs(studyMinutes: 120, screenTimeMinutes: 240, previousScore: 75, now: now, context: context)
            defaults.set(true, forKey: "fixtureSeeded")
        }
        return state
    }

    private struct Readings: HealthDataProviding {
        let isAvailable = true
        func requestAccess() async throws {}
        func read(window: HealthDataWindow) async -> HealthReadings {
            HealthReadings(sleep: .available(7), steps: .available(5000), exercise: .available(30),
                restingHeartRate: .available(60), restingHeartRateSampleDate: window.day.start)
        }
    }
}
#endif
