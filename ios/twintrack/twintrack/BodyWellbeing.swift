import Foundation
import Combine

enum GrowthReferenceSex: Int, Codable, CaseIterable, Identifiable {
    case male = 1
    case female = 2

    var id: Int { rawValue }
    var label: String { self == .male ? "Male growth reference" : "Female growth reference" }
}

struct BodyMeasurements: Codable, Equatable {
    let heightCM: Double
    let weightKG: Double
    let dateOfBirth: Date?
    let growthReferenceSex: GrowthReferenceSex?

    init(
        heightCM: Double,
        weightKG: Double,
        dateOfBirth: Date? = nil,
        growthReferenceSex: GrowthReferenceSex? = nil
    ) {
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.dateOfBirth = dateOfBirth
        self.growthReferenceSex = growthReferenceSex
    }

    // Broad input sanity limits, not healthy ranges or targets.
    var isValid: Bool {
        heightCM.isFinite && weightKG.isFinite
            && (50...250).contains(heightCM) && (10...400).contains(weightKG)
            && dateOfBirth.map { $0 <= Date() } != false
    }

    var bmi: Double? {
        guard isValid else { return nil }
        let meters = heightCM / 100
        return weightKG / (meters * meters)
    }

    static func parse(
        height: String,
        weight: String,
        dateOfBirth: Date? = nil,
        growthReferenceSex: GrowthReferenceSex? = nil
    ) -> BodyMeasurements? {
        func number(_ text: String) -> Double? {
            Double(text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: "."))
        }
        guard let h = number(height), let w = number(weight) else { return nil }
        let value = BodyMeasurements(
            heightCM: h,
            weightKG: w,
            dateOfBirth: dateOfBirth,
            growthReferenceSex: growthReferenceSex
        )
        return value.isValid ? value : nil
    }
}

enum BMICategory: String, Equatable {
    case underweight = "Underweight"
    case healthyWeight = "Healthy weight"
    case overweight = "Overweight"
    case obesity = "Obesity"
}

enum BMIAgePath: Equatable {
    case unavailable
    case childTeen
    case adult
}

struct BMIInterpretation: Equatable {
    let path: BMIAgePath
    let percentile: Double?
    let category: BMICategory?
    let explanation: String

    static func evaluate(
        _ measurements: BodyMeasurements,
        on date: Date = Date(),
        calendar: Calendar = .current,
        reference: CDCBMIReference = .shared
    ) -> BMIInterpretation {
        guard let bmi = measurements.bmi else { return unavailable("BMI category unavailable.") }
        var ageCalendar = Calendar(identifier: .gregorian)
        ageCalendar.timeZone = calendar.timeZone
        guard let birthDate = measurements.dateOfBirth,
              birthDate <= date,
              let ageMonths = ageCalendar.dateComponents(
                [.month],
                from: ageCalendar.startOfDay(for: birthDate),
                to: ageCalendar.startOfDay(for: date)
              ).month else {
            return unavailable("BMI category unavailable. Teen interpretation needs date of birth and sex.")
        }

        if ageMonths >= 240 {
            let category = classify(bmi, cutoffs: (18.5, 25, 30))
            return BMIInterpretation(
                path: .adult,
                percentile: nil,
                category: category,
                explanation: "Adult BMI categories apply from age 20. BMI is still only a screening measure."
            )
        }

        guard ageMonths >= 24 else {
            return unavailable("BMI-for-age is unavailable below age 2 in this CDC reference.")
        }
        guard let sex = measurements.growthReferenceSex else {
            return unavailable("BMI category unavailable. Teen interpretation needs date of birth and sex.")
        }
        guard let row = reference.row(sex: sex, completedAgeMonths: ageMonths),
              let percentile = row.percentile(forBMI: bmi) else {
            return unavailable("BMI-for-age reference unavailable.")
        }

        let category = classify(bmi, cutoffs: (row.p5, row.p85, row.p95))
        return BMIInterpretation(
            path: .childTeen,
            percentile: percentile,
            category: category,
            explanation: "BMI-for-age uses age- and sex-specific CDC growth references."
        )
    }

    private static func unavailable(_ explanation: String) -> BMIInterpretation {
        BMIInterpretation(path: .unavailable, percentile: nil, category: nil, explanation: explanation)
    }

    private static func classify(_ bmi: Double, cutoffs: (Double, Double, Double)) -> BMICategory {
        func below(_ cutoff: Double) -> Bool {
            // Resolve division roundoff at a published cutoff, without rounding the displayed BMI.
            bmi < cutoff && cutoff - bmi > 8 * max(bmi.ulp, cutoff.ulp)
        }
        if below(cutoffs.0) { return .underweight }
        if below(cutoffs.1) { return .healthyWeight }
        if below(cutoffs.2) { return .overweight }
        return .obesity
    }
}

struct CDCBMIReferenceRow: Equatable {
    let sex: GrowthReferenceSex
    let completedAgeMonths: Int
    let l: Double
    let m: Double
    let s: Double
    let sigma: Double
    let p5: Double
    let p85: Double
    let p95: Double

    func percentile(forBMI bmi: Double) -> Double? {
        guard bmi.isFinite, bmi > 0, l.isFinite, m > 0, s > 0, sigma > 0 else { return nil }
        let percentile: Double
        if bmi <= p95 {
            let z = abs(l) < 1e-12 ? log(bmi / m) / s : (pow(bmi / m, l) - 1) / (l * s)
            percentile = 100 * Self.normalCDF(z)
        } else {
            // CDC 2022 extended method: 90 + 10Φ((BMI − P95) / sigma).
            percentile = 90 + 10 * Self.normalCDF((bmi - p95) / sigma)
        }
        return min(max(percentile, 0), 100)
    }

    private static func normalCDF(_ value: Double) -> Double {
        0.5 * (1 + erf(value / sqrt(2)))
    }
}

struct CDCBMIReference {
    private let rows: [String: CDCBMIReferenceRow]

    static let shared: CDCBMIReference = {
        guard let url = Bundle.main.url(forResource: "bmi-age-2022", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return CDCBMIReference(rows: [])
        }
        return CDCBMIReference(csv: text)
    }()

    init(rows: [CDCBMIReferenceRow]) {
        self.rows = Dictionary(uniqueKeysWithValues: rows.map { (Self.key($0.sex, $0.completedAgeMonths), $0) })
    }

    init(csv: String) {
        let lines = csv.split(whereSeparator: \.isNewline).map(String.init)
        guard let headerLine = lines.first else { rows = [:]; return }
        let names = headerLine.split(separator: ",").map(String.init)
        let columns = Dictionary(uniqueKeysWithValues: names.enumerated().map { ($1, $0) })
        let required = ["sex", "agemos", "L", "M", "S", "sigma", "P5", "P85", "P95"]
        guard required.allSatisfy({ columns[$0] != nil }) else { rows = [:]; return }

        var parsed: [String: CDCBMIReferenceRow] = [:]
        for line in lines.dropFirst() {
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            func number(_ name: String) -> Double? {
                guard let index = columns[name], fields.indices.contains(index) else { return nil }
                return Double(fields[index])
            }
            guard let sexValue = number("sex"), let sex = GrowthReferenceSex(rawValue: Int(sexValue)),
                  let age = number("agemos"), age.truncatingRemainder(dividingBy: 1) == 0.5,
                  let l = number("L"), let m = number("M"), let s = number("S"),
                  let sigma = number("sigma"), let p5 = number("P5"),
                  let p85 = number("P85"), let p95 = number("P95") else { continue }
            let completedAgeMonths = Int(floor(age))
            guard (24..<240).contains(completedAgeMonths) else { continue }
            let row = CDCBMIReferenceRow(
                sex: sex, completedAgeMonths: completedAgeMonths,
                l: l, m: m, s: s, sigma: sigma, p5: p5, p85: p85, p95: p95
            )
            parsed[Self.key(sex, completedAgeMonths)] = row
        }
        rows = parsed
    }

    func row(sex: GrowthReferenceSex, completedAgeMonths: Int) -> CDCBMIReferenceRow? {
        rows[Self.key(sex, completedAgeMonths)]
    }

    var rowCount: Int { rows.count }

    private static func key(_ sex: GrowthReferenceSex, _ age: Int) -> String {
        "\(sex.rawValue)-\(age)"
    }
}

enum BMIDisplay {
    static func fraction(_ bmi: Double?) -> Double? {
        guard let bmi, bmi.isFinite, bmi > 0 else { return nil }
        return min(bmi / 60, 1)
    }

    static func scaleNote(_ bmi: Double?) -> String {
        guard let bmi, fraction(bmi) != nil else { return "Add your measurements when you choose." }
        return bmi > 60 ? "Value exceeds the dial’s 0–60 numeric scale."
            : "Numeric scale; category is shown separately."
    }

    static func percentile(_ value: Double) -> String {
        if value >= 99.5 { return "Above the 99th percentile" }
        if value < 1 { return "Below the 1st percentile" }
        let rounded = Int(value.rounded())
        let remainder100 = rounded % 100
        let suffix: String
        if (11...13).contains(remainder100) { suffix = "th" }
        else {
            switch rounded % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(rounded)\(suffix) percentile"
    }
}

@MainActor
final class BodyWellbeingStore: ObservableObject {
    private struct Record: Codable {
        let version: Int
        let measurements: BodyMeasurements
        var savedAt: Date?
        var assistantAccessAllowed: Bool?
    }
    enum StoreError: Error { case invalidMeasurements, unsupportedVersion }

    @Published private(set) var measurements: BodyMeasurements?
    @Published private(set) var loadFailed = false
    @Published private(set) var savedAt: Date?
    @Published private(set) var assistantAccessAllowed = false
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let fileURL = fileURL ?? Self.localURL()
        self.fileURL = fileURL
        do {
            let data = try Data(contentsOf: fileURL)
            let record = try JSONDecoder().decode(Record.self, from: data)
            guard (1...3).contains(record.version) else { throw StoreError.unsupportedVersion }
            guard record.measurements.isValid else { throw StoreError.invalidMeasurements }
            measurements = record.measurements
            savedAt = record.savedAt
            assistantAccessAllowed = record.assistantAccessAllowed ?? false
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            // First use has no measurements, never a fabricated default.
        } catch {
            loadFailed = true
        }
    }

    func save(_ value: BodyMeasurements) throws {
        guard value.isValid else { throw StoreError.invalidMeasurements }
        let date = value == measurements ? savedAt : Date()
        try write(value, savedAt: date, assistantAccessAllowed: assistantAccessAllowed)
    }

    func setAssistantAccess(_ allowed: Bool) throws {
        guard let measurements, !loadFailed else { throw StoreError.invalidMeasurements }
        try write(measurements, savedAt: savedAt, assistantAccessAllowed: allowed)
    }

    private func write(_ value: BodyMeasurements, savedAt: Date?, assistantAccessAllowed: Bool) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        var resources = URLResourceValues()
        resources.isExcludedFromBackup = true
        var localDirectory = directory
        try localDirectory.setResourceValues(resources)
        let data = try JSONEncoder().encode(Record(version: 3, measurements: value,
            savedAt: savedAt, assistantAccessAllowed: assistantAccessAllowed))
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        measurements = value
        self.savedAt = savedAt
        self.assistantAccessAllowed = assistantAccessAllowed
        loadFailed = false
    }

    func clear() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        measurements = nil
        savedAt = nil
        assistantAccessAllowed = false
        loadFailed = false
    }

    static func localURL() -> URL {
#if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "--synthetic-profile-ui-tests"),
           args.indices.contains(index + 1), let id = UUID(uuidString: args[index + 1]) {
            return FileManager.default.temporaryDirectory
                .appendingPathComponent("TwinTrack.BodyUITests.\(id.uuidString)", isDirectory: true)
                .appendingPathComponent("measurements.json")
        }
#endif
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TwinTrackBodyWellbeing", isDirectory: true)
            .appendingPathComponent("measurements.json")
    }

    /// App-owned read-only operation. Reopen the store for each request so consent
    /// revocation, removal and edits are observed even by an existing chat session.
    func assistantSummary(now: Date = Date()) -> AssistantCard {
        guard !loadFailed else {
            return AssistantCard(kind: .unavailable, title: "Wellbeing unavailable", message: "The saved wellbeing profile could not be read.")
        }
        guard let measurements else {
            return AssistantCard(kind: .unavailable, title: "No saved wellbeing profile", message: "No saved BMI is available. You can optionally add measurements in Profile → Body & Wellbeing.")
        }
        guard assistantAccessAllowed else {
            return AssistantCard(kind: .unavailable, title: "BMI access is off", message: "To share your derived BMI summary with chat, enable Allow BMI summary in chat in Profile → Body & Wellbeing. This is optional.")
        }
        guard let bmi = measurements.bmi else {
            return AssistantCard(kind: .unavailable, title: "BMI unavailable", message: "The saved measurements cannot produce a valid BMI.")
        }
        let interpretation = BMIInterpretation.evaluate(measurements, on: now)
        let category = interpretation.category?.rawValue ?? "BMI category unavailable"
        let percentile = interpretation.percentile.map { BMIDisplay.percentile($0) }
        let fields = [
            AssistantField(label: "Reference", value: interpretation.path == .adult ? "Adult BMI reference (20+)" : (interpretation.path == .childTeen ? "CDC 2022 BMI-for-age reference (ages 2–19)" : "Interpretation reference unavailable")),
            AssistantField(label: "Interpretation", value: interpretation.explanation),
            AssistantField(label: "Measurements saved", value: savedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not recorded for this older profile; not inferred"),
            AssistantField(label: "Calculated", value: now.formatted(date: .abbreviated, time: .shortened))
        ]
        return AssistantCard(kind: .wellbeing, title: "Saved BMI summary",
            message: "BMI \(bmi.formatted(.number.precision(.fractionLength(1)))) kg/m² · \(category). "
                + (percentile.map { "\($0). " } ?? "")
                + "BMI is a screening measure, not a health score or diagnosis. If concerned, speak with a parent, guardian or healthcare professional.",
            fields: fields,
            wellbeingSummary: AssistantWellbeingSummary(
                reference: interpretation.path == .childTeen ? .childTeen : (interpretation.path == .adult ? .adult : .unavailable),
                healthyCategory: interpretation.category == .healthyWeight))
    }
}
