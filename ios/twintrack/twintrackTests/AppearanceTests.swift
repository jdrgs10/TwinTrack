import XCTest
import SwiftUI
import UIKit
import ImageIO
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

    func testProfileEditableSourceIsBoundedOrientedAndMetadataFree() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2_000, height: 1_000))
        let large = renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2_000, height: 1_000))
        }
        let tagged = try jpegWithSyntheticGPS(from: large, orientation: 6)
        let prepared = try XCTUnwrap(ProfilePhotoCropper.sanitizedSourceJPEG(from: tagged))
        let decoded = try XCTUnwrap(UIImage(data: prepared))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(prepared as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])

        XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height),
                                 CGFloat(ProfilePhotoCropper.sourceMaximumDimension))
        XCTAssertEqual(decoded.imageOrientation, .up)
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        // JPEG encoders may generate technical pixel dimensions, but no source
        // metadata or comments from the selected photo may survive re-encoding.
        XCTAssertNil(exif?[kCGImagePropertyExifDateTimeOriginal])
        XCTAssertNil(exif?[kCGImagePropertyExifUserComment])
    }

    func testProfileAvatarAndEditableSourcePersistAndRemoveIndependently() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProfileImagePairTests.\(UUID().uuidString)", isDirectory: true)
        let avatarURL = directory.appendingPathComponent("profile-image.jpg")
        let sourceURL = directory.appendingPathComponent("profile-source.jpg")
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = try XCTUnwrap(ProfilePhotoCropper.sanitizedSourceJPEG(
            from: syntheticWideImage().jpegData(compressionQuality: 1)!
        ))
        let avatar = try XCTUnwrap(ProfilePhotoCropper.croppedJPEG(
            from: try XCTUnwrap(UIImage(data: source)), cropSize: 240, zoom: 1.5,
            offset: CGSize(width: 20, height: 0)
        ))

        try ProfileImageStorage.save(source, to: sourceURL)
        try ProfileImageStorage.save(avatar, to: avatarURL)
        XCTAssertEqual(ProfileImageStorage.load(from: sourceURL), source)
        XCTAssertEqual(ProfileImageStorage.load(from: avatarURL), avatar)

        try ProfileImageStorage.save(nil, to: sourceURL)
        try ProfileImageStorage.save(nil, to: avatarURL)
        XCTAssertNil(ProfileImageStorage.load(from: sourceURL))
        XCTAssertNil(ProfileImageStorage.load(from: avatarURL))
    }

    func testProfileCropAlwaysProducesSquareResizedJPEGWithoutGPSMetadata() throws {
        let source = syntheticWideImage()
        let sourceWithGPS = try jpegWithSyntheticGPS(from: source)
        let decoded = try XCTUnwrap(UIImage(data: sourceWithGPS))
        let cropped = try XCTUnwrap(ProfilePhotoCropper.croppedJPEG(
            from: decoded,
            cropSize: 280,
            zoom: 1.4,
            offset: CGSize(width: 45, height: -20)
        ))
        let image = try XCTUnwrap(UIImage(data: cropped))

        XCTAssertEqual(image.size.width, ProfilePhotoCropper.outputDimension)
        XCTAssertEqual(image.size.height, ProfilePhotoCropper.outputDimension)
        let sourceRef = try XCTUnwrap(CGImageSourceCreateWithData(cropped as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any])
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
    }

    func testProfileCropClampsPanSoImageAlwaysCoversCircle() {
        let imageSize = CGSize(width: 400, height: 200)
        let clamped = ProfilePhotoCropper.clampedOffset(
            CGSize(width: 10_000, height: -10_000),
            imageSize: imageSize,
            cropSize: 200,
            zoom: 1
        )

        XCTAssertEqual(clamped.width, 100)
        XCTAssertEqual(clamped.height, 0)
    }

    func testProfileCropPanAndZoomChangeTheProcessedAvatar() throws {
        let image = syntheticWideImage()
        let centered = try XCTUnwrap(ProfilePhotoCropper.croppedJPEG(
            from: image, cropSize: 240, zoom: 1, offset: .zero
        ))
        let moved = try XCTUnwrap(ProfilePhotoCropper.croppedJPEG(
            from: image, cropSize: 240, zoom: 2, offset: CGSize(width: 100, height: 0)
        ))

        XCTAssertNotEqual(centered, moved)
    }

    func testProfileCropNormalizesSourceOrientation() throws {
        let source = syntheticWideImage()
        let rotated = UIImage(
            cgImage: try XCTUnwrap(source.cgImage),
            scale: 1,
            orientation: .right
        )
        let cropped = try XCTUnwrap(ProfilePhotoCropper.croppedJPEG(
            from: rotated, cropSize: 240, zoom: 1, offset: .zero
        ))
        let image = try XCTUnwrap(UIImage(data: cropped))

        XCTAssertEqual(image.imageOrientation, .up)
        XCTAssertEqual(image.size, CGSize(
            width: ProfilePhotoCropper.outputDimension,
            height: ProfilePhotoCropper.outputDimension
        ))
    }

    private func syntheticImageData(color: UIColor) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        return renderer.image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }.pngData()!
    }

    private func syntheticWideImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 200, y: 0, width: 200, height: 200))
        }
    }

    private func jpegWithSyntheticGPS(from image: UIImage, orientation: Int? = nil) throws -> Data {
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(
            data as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ))
        let gps: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 0.0,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 0.0,
            kCGImagePropertyGPSLongitudeRef: "E"
        ]
        let exif: [CFString: Any] = [
            kCGImagePropertyExifDateTimeOriginal: "2001:02:03 04:05:06",
            kCGImagePropertyExifUserComment: "synthetic private metadata"
        ]
        var properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: gps,
            kCGImagePropertyExifDictionary: exif
        ]
        if let orientation { properties[kCGImagePropertyOrientation] = orientation }
        CGImageDestinationAddImage(
            destination,
            try XCTUnwrap(image.cgImage),
            properties as CFDictionary
        )
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let name = "AppearanceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }
}
