import HealthKit

@MainActor
final class HealthKitService: HealthDataProviding {
    // Apple Watch syncs into Apple Health. This iPhone service reads that store;
    // it never connects directly to a watch or keeps a second copy of app state.
    private lazy var store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static var readTypes: Set<HKObjectType> {
        [HKCategoryType(.sleepAnalysis), HKQuantityType(.stepCount),
         HKQuantityType(.appleExerciseTime), HKQuantityType(.restingHeartRate)]
    }

    func requestAccess() async throws {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        // Empty toShare means read-only. Completion means the request finished,
        // NOT that read access was granted. HealthKit intentionally hides read denial.
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    func read(window: HealthDataWindow) async -> HealthReadings {
        guard isAvailable else { return HealthReadings() }
        // Each query returns its own missing/failure state so a missing RHR does
        // not discard accessible sleep/activity. No raw samples or values are logged.
        let sleep = await readSleep(window.sleep)
        let steps = await readQuantity(.stepCount, window: window.day, options: .cumulativeSum)
        let exercise = await readQuantity(.appleExerciseTime, window: window.day, options: .cumulativeSum)
        let resting = await readRestingHeartRate(window.restingHeartRate)
        return HealthReadings(
            sleep: sleep, steps: steps, exercise: exercise,
            restingHeartRate: resting.result, restingHeartRateSampleDate: resting.date
        )
    }

    func readRestingHeartRateTrend(now: Date, calendar: Calendar) async -> RestingHeartRateTrend? {
        guard isAvailable else { return nil }
        let window = RestingHeartRateTrend.window(now: now, calendar: calendar)
        let predicate = NSPredicate(
            format: "%K >= %@ AND %K < %@",
            HKPredicateKeyPathStartDate, window.start as NSDate,
            HKPredicateKeyPathStartDate, window.end as NSDate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.restingHeartRate), predicate: predicate)],
            sortDescriptors: []
        )
        do {
            let samples = try await descriptor.result(for: store)
            // Only the assessment survives this query; raw samples never enter app state or storage.
            return RestingHeartRateTrend.assess(samples: samples.compactMap {
                guard let bpm = HealthUnits.restingBPM($0.quantity) else { return nil }
                return RestingHeartRateReading(bpm: bpm, date: $0.startDate)
            }, now: now, calendar: calendar)
        } catch {
            return nil
        }
    }

    private func readQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        window: DateInterval,
        options: HKStatisticsOptions
    ) async -> HealthMetricResult {
        // Start-date membership is [previous midnight, current midnight), matching
        // Apple's daily statistics example. Boundary-spanning quantity samples belong
        // to their start day; we never invent a prorated count from individual samples.
        let predicate = HKQuery.predicateForSamples(
            withStart: window.start, end: window.end, options: .strictStartDate
        )
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(identifier), predicate: predicate),
            options: options
        )
        do {
            let statistics = try await descriptor.result(for: store)
            let value: Double?
            switch identifier {
            case .stepCount:
                // HealthKit merges sources. Never request separateBySource and sum
                // Watch/iPhone totals ourselves: that could duplicate the same steps.
                value = HealthUnits.steps(statistics?.sumQuantity())
            case .appleExerciseTime:
                value = HealthUnits.exerciseMinutes(statistics?.sumQuantity())
            default:
                return .failed
            }
            guard let value else { return .missing }
            guard value.isFinite, value >= 0 else { return .failed }
            return .available(value)
        } catch {
            return Self.queryFailure(error)
        }
    }

    private func readRestingHeartRate(
        _ window: DateInterval
    ) async -> (result: HealthMetricResult, date: Date?) {
        // Use explicit inclusive start-date membership, also checked by the selector.
        // Do not limit to one result: an invalid newest sample must not hide a valid older one.
        let predicate = NSPredicate(
            format: "%K >= %@ AND %K <= %@",
            HKPredicateKeyPathStartDate, window.start as NSDate,
            HKPredicateKeyPathStartDate, window.end as NSDate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.restingHeartRate), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
        do {
            let samples = try await descriptor.result(for: store)
            let latest = RestingHeartRateSelection.latest(in: window, samples: samples.compactMap {
                guard let bpm = HealthUnits.restingBPM($0.quantity) else { return nil }
                return RestingHeartRateReading(bpm: bpm, date: $0.startDate)
            })
            guard let latest else { return (.missing, nil) }
            return (.available(latest.bpm), latest.date)
        } catch {
            return (Self.queryFailure(error), nil)
        }
    }

    private func readSleep(_ window: DateInterval) async -> HealthMetricResult {
        // Non-strict predicate includes samples crossing either noon boundary.
        // SleepAggregation clips them before merging, rather than losing entire nights.
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
            sortDescriptors: []
        )
        do {
            let samples = try await descriptor.result(for: store)
            let hours = SleepAggregation.hours(in: window, samples: samples.map {
                SleepInterval(start: $0.startDate, end: $0.endDate, category: $0.value)
            })
            return hours.map(HealthMetricResult.available) ?? .missing
        } catch {
            return Self.queryFailure(error)
        }
    }

    static func queryFailure(_ error: Error) -> HealthMetricResult {
        // No data is an ordinary availability state. Other failures stay distinct;
        // never persist error descriptions that might contain private sample metadata.
        let error = error as NSError
        return error.domain == HKErrorDomain && error.code == HKError.Code.errorNoData.rawValue
            ? .missing : .failed
    }
}
