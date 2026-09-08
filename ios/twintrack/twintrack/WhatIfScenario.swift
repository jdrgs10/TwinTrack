import Foundation

enum WhatIfError: Error, Equatable, LocalizedError {
    case missingBaseline
    case invalidValue(TwinTrackFeature)

    var errorDescription: String? {
        switch self {
        case .missingBaseline:
            "All seven current inputs are required before a scenario can be calculated."
        case .invalidValue(let feature):
            "Enter a valid \(HomeDisplay.featureName(feature)) value. \(WhatIfScenario.validationHint(for: feature))"
        }
    }
}

/// A value-type snapshot with temporary overrides. It has no access to the real
/// store, UserDefaults, or HealthKit, so a simulation cannot save over current data.
struct WhatIfScenario {
    let baseline: TwinTrackProfile
    let baselinePrediction: Double
    private(set) var changes: [TwinTrackFeature: Double] = [:]

    init(baseline: TwinTrackProfile?) throws {
        guard let baseline else { throw WhatIfError.missingBaseline }
        for feature in TwinTrackFeature.allCases {
            guard Self.isValid(Self.value(feature, in: baseline), for: feature) else {
                throw WhatIfError.invalidValue(feature)
            }
        }
        self.baseline = baseline
        baselinePrediction = TwinTrackModel.predict(baseline)
    }

    func currentValue(for feature: TwinTrackFeature) -> Double {
        Self.value(feature, in: baseline)
    }

    func scenarioValue(for feature: TwinTrackFeature) -> Double {
        changes[feature] ?? currentValue(for: feature)
    }

    mutating func set(_ value: Double, for feature: TwinTrackFeature) throws {
        guard Self.isValid(value, for: feature) else { throw WhatIfError.invalidValue(feature) }
        changes[feature] = value == currentValue(for: feature) ? nil : value
    }

    mutating func reset() {
        changes.removeAll()
    }

    var scenarioProfile: TwinTrackProfile {
        TwinTrackProfile(
            sleepHours: scenarioValue(for: .sleepHours),
            steps: scenarioValue(for: .steps),
            exerciseMinutes: scenarioValue(for: .exerciseMinutes),
            restingHeartRate: scenarioValue(for: .restingHeartRate),
            studyMinutes: scenarioValue(for: .studyMinutes),
            screenTimeMinutes: scenarioValue(for: .screenTimeMinutes),
            previousScore: scenarioValue(for: .previousScore)
        )
    }

    func evaluate() -> WhatIfResult {
        // Apply every override before evaluating the scenario against the captured
        // baseline prediction. Production-clamped outputs handle 0/100 boundaries;
        // adding isolated deltas would not.
        let scenario = scenarioProfile
        let simulated = TwinTrackModel.predict(scenario)
        return WhatIfResult(baseline: baseline, scenario: scenario,
                            baselinePrediction: baselinePrediction, scenarioPrediction: simulated,
                            delta: simulated - baselinePrediction,
                            changedFeatures: TwinTrackFeature.allCases.filter { changes[$0] != nil })
    }

    static func isValid(_ value: Double, for feature: TwinTrackFeature) -> Bool {
        // This is a floating-point safety guard, not a scientific/training range.
        // It leaves ample headroom for unit conversion and the frozen calculation.
        guard value.isFinite, value >= 0,
              value <= Double.greatestFiniteMagnitude.squareRoot() else { return false }
        switch feature {
        case .previousScore: return value <= 100
        case .restingHeartRate: return value > 0
        default: return true
        }
    }

    static func validationHint(for feature: TwinTrackFeature) -> String {
        switch feature {
        case .previousScore: "Use a finite number from 0 through 100."
        case .restingHeartRate: "Use a positive finite number in bpm; values too large to calculate safely are rejected."
        default: "Use a non-negative finite number; values too large to calculate safely are rejected."
        }
    }

    static func value(_ feature: TwinTrackFeature, in profile: TwinTrackProfile) -> Double {
        switch feature {
        case .sleepHours: profile.sleepHours
        case .steps: profile.steps
        case .exerciseMinutes: profile.exerciseMinutes
        case .restingHeartRate: profile.restingHeartRate
        case .studyMinutes: profile.studyMinutes
        case .screenTimeMinutes: profile.screenTimeMinutes
        case .previousScore: profile.previousScore
        }
    }
}

struct WhatIfResult {
    let baseline: TwinTrackProfile
    let scenario: TwinTrackProfile
    let baselinePrediction: Double
    let scenarioPrediction: Double
    let delta: Double
    let changedFeatures: [TwinTrackFeature]
}
