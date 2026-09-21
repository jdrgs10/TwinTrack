import Foundation
import XCTest
@testable import twintrack

final class TwinTrackModelTests: XCTestCase {
    func testFrozenRidgeMatchesAll21GoldenProfiles() throws {
        let resourceURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "golden_profiles",
                withExtension: "json"
            )
        )
        let goldenData = try Data(contentsOf: resourceURL)
        let golden = try JSONDecoder().decode(GoldenFile.self, from: goldenData)

        XCTAssertEqual(
            golden.featureOrder,
            TwinTrackFeature.allCases.map(\.key),
            "The frozen seven-feature order must never change."
        )
        XCTAssertEqual(golden.profiles.count, 21)
        XCTAssertEqual(golden.tolerance, 1e-6, accuracy: 0.0)

        var passed = 0
        var maximumAbsoluteError = 0.0
        var failures: [String] = []

        // Expected values are frozen Python outputs. Never edit them to make this test pass:
        // 21/21 parity proves Swift implements the same numerical pipeline as Python.
        for profile in golden.profiles {
            let input = try profile.makeInput()
            let rawError = abs(TwinTrackModelV1.predictRaw(input) - profile.expectedRaw)
            let clampedError = abs(TwinTrackModelV1.predict(input) - profile.expectedClamped)
            let profileError = max(rawError, clampedError)

            maximumAbsoluteError = max(maximumAbsoluteError, profileError)

            if profileError <= golden.tolerance {
                passed += 1
            } else {
                failures.append(
                    "\(profile.name): raw error \(rawError), clamped error \(clampedError)"
                )
            }
        }

        print("RIDGE GOLDEN PARITY: \(passed)/\(golden.profiles.count) PASS")
        print(String(format: "MAX ABSOLUTE ERROR: %.17g", maximumAbsoluteError))
        print(String(format: "TOLERANCE: %.17g", golden.tolerance))

        XCTAssertEqual(passed, 21, failures.joined(separator: "\n"))
        XCTAssertTrue(failures.isEmpty)
    }
}

private struct GoldenFile: Decodable {
    let tolerance: Double
    let featureOrder: [String]
    let profiles: [GoldenProfile]

    enum CodingKeys: String, CodingKey {
        case tolerance, profiles
        case featureOrder = "feature_order"
    }
}

private struct GoldenProfile: Decodable {
    let name: String
    let inputs: [String: Double]
    let expectedRaw: Double
    let expectedClamped: Double

    enum CodingKeys: String, CodingKey {
        case name, inputs
        case expectedRaw = "expected_raw"
        case expectedClamped = "expected_clamped"
    }

    func makeInput() throws -> TwinTrackProfile {
        TwinTrackProfile(
            sleepHours: try value(for: .sleepHours),
            steps: try value(for: .steps),
            exerciseMinutes: try value(for: .exerciseMinutes),
            restingHeartRate: try value(for: .restingHeartRate),
            studyMinutes: try value(for: .studyMinutes),
            screenTimeMinutes: try value(for: .screenTimeMinutes),
            previousScore: try value(for: .previousScore)
        )
    }

    private func value(for feature: TwinTrackFeature) throws -> Double {
        guard let value = inputs[feature.key] else {
            throw GoldenProfileError.missingFeature(profile: name, feature: feature.key)
        }
        return value
    }
}

private enum GoldenProfileError: Error {
    case missingFeature(profile: String, feature: String)
}
