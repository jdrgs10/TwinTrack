import XCTest
@testable import twintrack

@MainActor
final class BodyWellbeingTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private var now: Date { calendar.date(from: .init(year: 2026, month: 9, day: 22, hour: 12))! }

    private func birthDate(monthsAgo: Int) -> Date {
        calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
    }

    private func localFile() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("body/measurements.json")
    }

    private func measurements(
        bmi: Double,
        ageMonths: Int? = 114,
        sex: GrowthReferenceSex? = .female
    ) -> BodyMeasurements {
        BodyMeasurements(
            heightCM: 100,
            weightKG: bmi,
            dateOfBirth: ageMonths.map(birthDate),
            growthReferenceSex: sex
        )
    }

    func testFormulaAndCentimetreConversion() throws {
        XCTAssertEqual(try XCTUnwrap(BodyMeasurements(heightCM: 200, weightKG: 80).bmi), 20, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(BodyMeasurements(heightCM: 160, weightKG: 64).bmi), 25, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(BodyMeasurements(heightCM: 175, weightKG: 70).bmi), 22.857142857, accuracy: 1e-9)
    }

    func testOfficialCDCReferenceIsBundledAndMatchesPublishedExamples() throws {
        XCTAssertEqual(CDCBMIReference.shared.rowCount, 432)
        let girl = try XCTUnwrap(CDCBMIReference.shared.row(sex: .female, completedAgeMonths: 114))
        XCTAssertEqual(girl.l, -2.257782149, accuracy: 1e-12)
        XCTAssertEqual(girl.m, 16.57626713, accuracy: 1e-12)
        XCTAssertEqual(girl.s, 0.132796819, accuracy: 1e-12)
        XCTAssertEqual(girl.p95, 22.3979, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(girl.percentile(forBMI: 21.2)), 92.241444419, accuracy: 1e-8)
        let boy = try XCTUnwrap(CDCBMIReference.shared.row(sex: .male, completedAgeMonths: 50))
        XCTAssertEqual(try XCTUnwrap(boy.percentile(forBMI: 22.6)), 99.768307142, accuracy: 1e-8)
    }

    func testTeenCompleteProfileReturnsRawBMIPercentileAndCategory() throws {
        let profile = measurements(bmi: 21.2)
        XCTAssertEqual(profile.bmi, 21.2)
        let result = BMIInterpretation.evaluate(profile, on: now, calendar: calendar)
        XCTAssertEqual(result.path, .childTeen)
        XCTAssertEqual(try XCTUnwrap(result.percentile), 92.241444419, accuracy: 1e-8)
        XCTAssertEqual(result.category, .overweight)
    }

    func testTeenPublishedCategoryBoundariesAreExact() throws {
        let row = try XCTUnwrap(CDCBMIReference.shared.row(sex: .female, completedAgeMonths: 114))
        XCTAssertEqual(BMIInterpretation.evaluate(measurements(bmi: row.p5 - 0.0001), on: now, calendar: calendar).category, .underweight)
        XCTAssertEqual(BMIInterpretation.evaluate(measurements(bmi: row.p5), on: now, calendar: calendar).category, .healthyWeight)
        XCTAssertEqual(BMIInterpretation.evaluate(measurements(bmi: row.p85), on: now, calendar: calendar).category, .overweight)
        XCTAssertEqual(BMIInterpretation.evaluate(measurements(bmi: row.p95), on: now, calendar: calendar).category, .obesity)
        for (cutoff, category) in [(row.p5, BMICategory.healthyWeight), (row.p85, .overweight), (row.p95, .obesity)] {
            let scaled = BodyMeasurements(heightCM: 160, weightKG: cutoff * 2.56,
                dateOfBirth: birthDate(monthsAgo: 114), growthReferenceSex: .female)
            XCTAssertEqual(BMIInterpretation.evaluate(scaled, on: now, calendar: calendar).category, category)
        }
    }

    func testMissingAgeOrSexKeepsRawBMIButCategoryUnavailable() {
        for profile in [measurements(bmi: 21.2, ageMonths: nil), measurements(bmi: 21.2, sex: nil)] {
            XCTAssertEqual(profile.bmi, 21.2)
            let result = BMIInterpretation.evaluate(profile, on: now, calendar: calendar)
            XCTAssertEqual(result.path, .unavailable)
            XCTAssertNil(result.percentile)
            XCTAssertNil(result.category)
            XCTAssertTrue(result.explanation.contains("unavailable"))
        }
    }

    func testUnderTwoIsUnavailableAndAgeTwentyUsesAdultPathWithoutSex() {
        let infant = BMIInterpretation.evaluate(measurements(bmi: 18, ageMonths: 23), on: now, calendar: calendar)
        XCTAssertEqual(infant.path, .unavailable)
        let adult = BMIInterpretation.evaluate(measurements(bmi: 25, ageMonths: 240, sex: nil), on: now, calendar: calendar)
        XCTAssertEqual(adult.path, .adult)
        XCTAssertNil(adult.percentile)
        XCTAssertEqual(adult.category, .overweight)
        let boundary = BodyMeasurements(heightCM: 160, weightKG: 64, dateOfBirth: birthDate(monthsAgo: 240))
        XCTAssertEqual(BMIInterpretation.evaluate(boundary, on: now, calendar: calendar).category, .overweight)
        var islamicCalendar = Calendar(identifier: .islamicCivil)
        islamicCalendar.timeZone = calendar.timeZone
        let teen = measurements(bmi: 21.2, ageMonths: 237)
        XCTAssertEqual(BMIInterpretation.evaluate(teen, on: now, calendar: islamicCalendar),
                       BMIInterpretation.evaluate(teen, on: now, calendar: calendar))
    }

    func testInvalidZeroMissingAndFutureInputsAreUnavailable() {
        for height in [0, -1, 49, 251, .nan, .infinity] {
            XCTAssertNil(BodyMeasurements(heightCM: height, weightKG: 64).bmi)
        }
        for weight in [0, -1, 9, 401, .nan, .infinity] {
            XCTAssertNil(BodyMeasurements(heightCM: 160, weightKG: weight).bmi)
        }
        let future = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(BodyMeasurements(heightCM: 160, weightKG: 64, dateOfBirth: future).isValid)
        for pair in [("", "64"), ("160", ""), ("height", "64"), ("160cm", "64"), ("160", "nan")] {
            XCTAssertNil(BodyMeasurements.parse(height: pair.0, weight: pair.1))
        }
    }

    func testNumericDialAndPercentilePresentation() {
        XCTAssertNil(BMIDisplay.fraction(nil))
        XCTAssertNil(BMIDisplay.fraction(.nan))
        XCTAssertEqual(BMIDisplay.fraction(30), 0.5)
        XCTAssertEqual(BMIDisplay.fraction(80), 1)
        XCTAssertTrue(BMIDisplay.scaleNote(80).contains("exceeds"))
        XCTAssertEqual(BMIDisplay.percentile(1.2), "1st percentile")
        XCTAssertEqual(BMIDisplay.percentile(2.2), "2nd percentile")
        XCTAssertEqual(BMIDisplay.percentile(3.2), "3rd percentile")
        XCTAssertEqual(BMIDisplay.percentile(11.2), "11th percentile")
        XCTAssertEqual(BMIDisplay.percentile(99.8), "Above the 99th percentile")
    }

    func testNewStoreHasNoFabricatedValues() throws {
        let store = BodyWellbeingStore(fileURL: try localFile())
        XCTAssertNil(store.measurements)
        XCTAssertFalse(store.loadFailed)
    }

    func testCompleteProfilePersistsAcrossRelaunchAndLatestEditWins() throws {
        let url = try localFile(), store = BodyWellbeingStore(fileURL: url)
        let first = BodyMeasurements(heightCM: 160, weightKG: 64, dateOfBirth: birthDate(monthsAgo: 114), growthReferenceSex: .female)
        try store.save(first)
        XCTAssertEqual(BodyWellbeingStore(fileURL: url).measurements, first)
        let edited = BodyMeasurements(heightCM: 200, weightKG: 80, dateOfBirth: birthDate(monthsAgo: 240), growthReferenceSex: .male)
        try BodyWellbeingStore(fileURL: url).save(edited)
        XCTAssertEqual(BodyWellbeingStore(fileURL: url).measurements, edited)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        XCTAssertEqual(json["version"] as? Int, 3)
        let values = try XCTUnwrap(json["measurements"] as? [String: Any])
        XCTAssertEqual(Set(values.keys), ["heightCM", "weightKG", "dateOfBirth", "growthReferenceSex"])
    }

    func testVersionOneHeightWeightRecordMigratesWithoutInventingAgeOrSex() throws {
        let url = try localFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"version":1,"measurements":{"heightCM":160,"weightKG":64}}"#.utf8).write(to: url)
        let restored = BodyWellbeingStore(fileURL: url)
        XCTAssertEqual(try XCTUnwrap(restored.measurements?.bmi), 25, accuracy: 1e-12)
        XCTAssertNil(restored.measurements?.dateOfBirth)
        XCTAssertNil(restored.measurements?.growthReferenceSex)
        XCTAssertNil(BMIInterpretation.evaluate(try XCTUnwrap(restored.measurements), on: now, calendar: calendar).category)
    }

    func testInvalidSavePreservesPreviousRecordAndCorruptDataIsNotOverwritten() throws {
        let url = try localFile(), store = BodyWellbeingStore(fileURL: url)
        let previous = BodyMeasurements(heightCM: 160, weightKG: 64)
        try store.save(previous)
        let bytes = try Data(contentsOf: url)
        XCTAssertThrowsError(try store.save(BodyMeasurements(heightCM: 0, weightKG: 64)))
        XCTAssertEqual(store.measurements, previous)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        try Data(#"{"version":4,"measurements":{"heightCM":160,"weightKG":64}}"#.utf8).write(to: url)
        let unsupported = BodyWellbeingStore(fileURL: url)
        XCTAssertNil(unsupported.measurements)
        XCTAssertTrue(unsupported.loadFailed)
    }

    func testClearRemovesOnlyWellbeingProfile() throws {
        let url = try localFile(), store = BodyWellbeingStore(fileURL: url)
        try store.save(BodyMeasurements(heightCM: 160, weightKG: 64, dateOfBirth: birthDate(monthsAgo: 114), growthReferenceSex: .female))
        let unrelated = url.deletingLastPathComponent().appendingPathComponent("unrelated.txt")
        try Data("synthetic unrelated content".utf8).write(to: unrelated)
        try store.clear()
        XCTAssertNil(BodyWellbeingStore(fileURL: url).measurements)
        XCTAssertTrue(FileManager.default.fileExists(atPath: unrelated.path))
    }

    func testFailedWriteDoesNotPublishUnsavedProfile() throws {
        let url = try localFile()
        try Data("block directory".utf8).write(to: url.deletingLastPathComponent())
        let store = BodyWellbeingStore(fileURL: url)
        XCTAssertThrowsError(try store.save(BodyMeasurements(heightCM: 160, weightKG: 64)))
        XCTAssertNil(store.measurements)
    }

    func testAllWellbeingValuesLeaveV1V2AndWhatIfUntouched() throws {
        let profile = TwinTrackProfile(sleepHours: 7.5, steps: 7000, exerciseMinutes: 30,
            restingHeartRate: 65, studyMinutes: 90, screenTimeMinutes: 120, previousScore: 80)
        let v1 = TwinTrackModelV1.predict(profile), v2 = TwinTrackModel.predict(profile)
        var scenario = try WhatIfScenario(baseline: profile)
        try scenario.set(120, for: .studyMinutes)
        let before = scenario.evaluate()
        let store = BodyWellbeingStore(fileURL: try localFile())
        try store.save(BodyMeasurements(heightCM: 160, weightKG: 64, dateOfBirth: birthDate(monthsAgo: 114), growthReferenceSex: .female))
        try store.save(BodyMeasurements(heightCM: 200, weightKG: 100, dateOfBirth: birthDate(monthsAgo: 300), growthReferenceSex: .male))
        try store.clear()
        XCTAssertEqual(TwinTrackFeature.allCases.count, 7)
        XCTAssertEqual(TwinTrackModelV1.predict(profile), v1)
        XCTAssertEqual(TwinTrackModel.predict(profile), v2)
        XCTAssertEqual(scenario.evaluate().scenarioPrediction, before.scenarioPrediction)
        XCTAssertEqual(scenario.evaluate().delta, before.delta)
    }

    func testProtectedStorageIsExcludedFromBackup() throws {
        let url = try localFile(), store = BodyWellbeingStore(fileURL: url)
        try store.save(BodyMeasurements(heightCM: 160, weightKG: 64))
        let resources = try url.deletingLastPathComponent().resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(resources.isExcludedFromBackup, true)
#if !targetEnvironment(simulator)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
#endif
    }
}
