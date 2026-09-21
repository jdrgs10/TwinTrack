// Generated from approved 2.0-final.1 JSON; regenerate with ml/v2/2026-09-21-ios-parity/export_ios.py.
// SHA-256 of parameter JSON: 62cb14d443221f9f2e426280ebdf52d7ef8614812a89ef5031329642ff040024
enum TwinTrackModel {
    static let version = "2.0-final.1"
    static let name = "TwinTrack Ridge V2"
    static let provenance = "explicitRun.v2.2.0-final.1"
    static let mean: [Double] = [6.910532056110472, 7579.6176444444445, 35.616004765183405, 70.06224157422614, 81.225, 222.69113333333334, 72.08134473524811]
    static let scale: [Double] = [1.8081970678397858, 3714.3206672528972, 39.43167004155552, 6.954209824355679, 58.99105937437563, 118.71129985175519, 12.395571969521258]
    static let coefficient: [Double] = [0.16083873081088637, -0.06199779395318764, 0.0666486658847992, -0.3210760453847087, 0.6148398214983507, -0.4997276682425781, 9.647971997056539]
    static let intercept: Double = 71.70996613127207
    static let bounds: [ClosedRange<Double>] = [0.0...12.0, 0.0...30000.0, 0.0...180.0, 35.0...120.0, 0.0...360.0, 0.0...720.0, 0.0...100.0]

    static func predictRaw(_ profile: TwinTrackProfile) -> Double {
        var result = intercept
        let values = profile.orderedValues
        for feature in TwinTrackFeature.allCases {
            let i = feature.rawValue
            result += coefficient[i] * ((values[i] - mean[i]) / scale[i])
        }
        return result
    }

    static func predict(_ profile: TwinTrackProfile) -> Double {
        min(100, max(0, predictRaw(profile)))
    }
}
