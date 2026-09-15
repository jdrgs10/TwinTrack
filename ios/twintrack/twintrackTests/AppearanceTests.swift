import XCTest
import SwiftUI
import UIKit
@testable import twintrack

@MainActor
final class AppearanceTests: XCTestCase {
    func testDefaultSystemDoesNotForceScheme() {
        withDefaults { defaults in
            let preference = AppearancePreferences(defaults: defaults)
            XCTAssertEqual(preference.selection, .system)
            XCTAssertNil(preference.selection.colorScheme)
            XCTAssertNil(defaults.object(forKey: AppearancePreferences.key))
        }
    }

    func testLightPersistsAcrossRecreation() {
        withDefaults { defaults in
            AppearancePreferences(defaults: defaults).selection = .light
            let restored = AppearancePreferences(defaults: defaults)
            XCTAssertEqual(restored.selection, .light)
            XCTAssertEqual(restored.selection.colorScheme, .light)
        }
    }

    func testDarkPersistsAcrossRecreation() {
        withDefaults { defaults in
            AppearancePreferences(defaults: defaults).selection = .dark
            let restored = AppearancePreferences(defaults: defaults)
            XCTAssertEqual(restored.selection, .dark)
            XCTAssertEqual(restored.selection.colorScheme, .dark)
        }
    }

    func testReturnToSystemRemovesForcedAppearanceAndPreservesOtherPreferences() {
        withDefaults { defaults in
            defaults.set("synthetic unrelated preference", forKey: "fixture")
            let preference = AppearancePreferences(defaults: defaults)
            preference.selection = .dark
            preference.selection = .system
            XCTAssertNil(preference.selection.colorScheme)
            XCTAssertEqual(AppearancePreferences(defaults: defaults).selection, .system)
            XCTAssertEqual(defaults.string(forKey: "fixture"), "synthetic unrelated preference")
        }
    }

    func testUnknownPreferenceFallsBackToSystem() {
        withDefaults { defaults in
            defaults.set("future-unknown", forKey: AppearancePreferences.key)
            XCTAssertEqual(AppearancePreferences(defaults: defaults).selection, .system)
        }
    }

    func testApprovedHomeMarkResolvesDistinctExistingLightAndDarkVariants() throws {
        let light = try XCTUnwrap(UIImage(named: "TwinTrackHeaderMark", in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .light)))
        let dark = try XCTUnwrap(UIImage(named: "TwinTrackHeaderMark", in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .dark)))
        XCTAssertNotEqual(light.pngData(), dark.pngData())
        // A confirmed the approved blue artwork, not a monochrome treatment.
        // Resolve both luminosity variants without rewriting or recoloring assets.
        XCTAssertGreaterThan(dark.size.width, 0)
        XCTAssertGreaterThan(dark.size.height, 0)
        XCTAssertGreaterThan(light.size.width, 0)
        XCTAssertGreaterThan(light.size.height, 0)
    }

    func testProfileImagePersistsChangesAndCanBeRemoved() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProfileImageTests.\(UUID().uuidString)", isDirectory: true)
        let file = directory.appendingPathComponent("profile-image.jpg")
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = try XCTUnwrap(ProfileImageStorage.normalizedJPEG(from: syntheticImageData(color: .red)))
        let second = try XCTUnwrap(ProfileImageStorage.normalizedJPEG(from: syntheticImageData(color: .blue)))
        XCTAssertNotEqual(first, second)

        try ProfileImageStorage.save(first, to: file)
        XCTAssertEqual(ProfileImageStorage.load(from: file), first)
        try ProfileImageStorage.save(second, to: file)
        XCTAssertEqual(ProfileImageStorage.load(from: file), second)
        try ProfileImageStorage.save(nil, to: file)
        XCTAssertNil(ProfileImageStorage.load(from: file))
    }

    func testInvalidOrCorruptedProfileImageFallsBackSafely() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProfileImageTests.\(UUID().uuidString)", isDirectory: true)
        let file = directory.appendingPathComponent("profile-image.jpg")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not an image".utf8).write(to: file)

        XCTAssertNil(ProfileImageStorage.load(from: file))
        XCTAssertThrowsError(try ProfileImageStorage.save(Data("invalid".utf8), to: file))
    }

    private func syntheticImageData(color: UIColor) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        return renderer.image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }.pngData()!
    }

    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let name = "AppearanceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }
}
