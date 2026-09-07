/// The raw values lock every parameter to the frozen seven-feature export order.
/// Reordering or inserting a feature would silently change the model's meaning.
enum TwinTrackFeature: Int, CaseIterable {
    case sleepHours = 0
    case steps = 1
    case exerciseMinutes = 2
    case restingHeartRate = 3
    case studyMinutes = 4
    case screenTimeMinutes = 5
    case previousScore = 6

    var key: String {
        switch self {
        case .sleepHours: "sleep_hours"
        case .steps: "steps"
        case .exerciseMinutes: "exercise_minutes"
        case .restingHeartRate: "resting_heart_rate"
        case .studyMinutes: "study_minutes"
        case .screenTimeMinutes: "screen_time_minutes"
        case .previousScore: "previous_score"
        }
    }
}

struct TwinTrackProfile {
    let sleepHours: Double
    let steps: Double
    let exerciseMinutes: Double
    let restingHeartRate: Double
    let studyMinutes: Double
    let screenTimeMinutes: Double
    let previousScore: Double

    fileprivate var orderedValues: [Double] {
        [
            sleepHours,
            steps,
            exerciseMinutes,
            restingHeartRate,
            studyMinutes,
            screenTimeMinutes,
            previousScore,
        ]
    }
}

enum TwinTrackModel {
    // These Double values are copied exactly from the frozen
    // ml/frozen_export/twintrack_model_params.json artifact.
    private static let mean: [Double] = [
        6.9750875,
        6835.025,
        31.021375,
        68.09925000000001,
        90.76825000000001,
        245.52300000000002,
        74.94800000000001,
    ]

    private static let scale: [Double] = [
        1.165721232689767,
        2478.3349716846187,
        18.76555103399245,
        8.758956812172327,
        48.136470237622326,
        91.09202926710987,
        12.11120951845851,
    ]

    private static let coefficient: [Double] = [
        1.0313609218864506,
        0.8551817402946157,
        0.5057650814894945,
        0.24125669488872578,
        1.5671184670863296,
        -0.9375490969179391,
        6.4394301275765775,
    ]

    private static let intercept: Double = 67.90012499999999

    /// Reproduces the frozen StandardScaler + Ridge pipeline using Double throughout.
    /// Foundation Models may explain this result later, but must never calculate it.
    static func predictRaw(_ profile: TwinTrackProfile) -> Double {
        let values = profile.orderedValues
        var prediction = intercept

        for feature in TwinTrackFeature.allCases {
            let index = feature.rawValue
            // StandardScaler contract: z = (x - mean) / scale.
            let standardized = (values[index] - mean[index]) / scale[index]
            prediction += coefficient[index] * standardized
        }

        return prediction
    }

    /// The product contract clamps the deterministic Ridge output to a 0...100 score.
    static func predict(_ profile: TwinTrackProfile) -> Double {
        min(100.0, max(0.0, predictRaw(profile)))
    }
}
