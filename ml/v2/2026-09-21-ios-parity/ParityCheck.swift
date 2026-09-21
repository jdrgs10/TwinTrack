import Foundation

// Runs the exact production Swift engines without requiring a Simulator runtime.
// This supplements, rather than replaces, the iOS XCTest suite.
@main
struct ParityCheck {
    struct Golden: Decodable {
        let feature_order: [String]
        let tolerance: Double
        let profiles: [Entry]
        struct Entry: Decodable {
            let name: String
            let inputs: [String: Double]
            let expected_raw: Double
            let expected_clamped: Double
        }
    }

    static func main() throws {
        precondition(CommandLine.arguments.count == 3)
        for (index, path) in CommandLine.arguments.dropFirst().enumerated() {
            let golden = try JSONDecoder().decode(Golden.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
            precondition(golden.feature_order == TwinTrackFeature.allCases.map(\.key))
            precondition(golden.profiles.count == (index == 0 ? 176 : 21))
            var maximum = 0.0
            for entry in golden.profiles {
                let v = golden.feature_order.map { entry.inputs[$0]! }
                let input = TwinTrackProfile(sleepHours: v[0], steps: v[1], exerciseMinutes: v[2], restingHeartRate: v[3], studyMinutes: v[4], screenTimeMinutes: v[5], previousScore: v[6])
                let raw = index == 0 ? TwinTrackModel.predictRaw(input) : TwinTrackModelV1.predictRaw(input)
                let clipped = index == 0 ? TwinTrackModel.predict(input) : TwinTrackModelV1.predict(input)
                let error = max(abs(raw - entry.expected_raw), abs(clipped - entry.expected_clamped))
                precondition(raw.isFinite && clipped.isFinite && error <= golden.tolerance, entry.name)
                maximum = max(maximum, error)
            }
            print("\(index == 0 ? "V2 2.0-final.1" : "V1 preserved") Swift parity: \(golden.profiles.count)/\(golden.profiles.count); max absolute error: \(maximum); tolerance: \(golden.tolerance)")
        }
    }
}
