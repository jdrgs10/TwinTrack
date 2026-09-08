# HealthKit implementation and verification contract

Status: verified on September 8, 2026. No real health values belong in this document, tests, Git, logs, or AI prompts.

## Ownership and permissions

Apple Watch → Apple Health → iPhone HealthKit → `HealthKitService` → existing `TwinTrackState`. No watchOS app or direct Watch connection is used. The service has one lazy `HKHealthStore` and returns transient results, not a second observable store. `TwinTrackState` publishes one four-metric snapshot and exposes the original seven-value `TwinTrackProfile` boundary. Ridge is not called by this milestone.

Exactly these read types are requested:

| Ridge feature | HealthKit type | Unit | Processing |
| --- | --- | --- | --- |
| `sleep_hours` | `HKCategoryType(.sleepAnalysis)` | elapsed seconds / 3600 | Clip and merge asleep intervals from all accessible sources. |
| `steps` | `HKQuantityType(.stepCount)` | count | HealthKit `.cumulativeSum`; no raw-sample or separate-source summation. |
| `exercise_minutes` | `HKQuantityType(.appleExerciseTime)` | minutes | HealthKit `.cumulativeSum`. |
| `resting_heart_rate` | `HKQuantityType(.restingHeartRate)` | count/minute (bpm) | HealthKit `.discreteAverage` of actual resting estimates. |

`toShare` is empty. Debug and Release reference `twintrack.entitlements`, containing only `com.apple.developer.healthkit = true`. Generated Info.plist includes `NSHealthShareUsageDescription`. No write usage key or write request, clinical-record entitlement, background-delivery entitlement, or HealthKit-required-device restriction is added; the app can still show unavailable states when HealthKit is unsupported.

Availability is checked before HealthKit queries. A completed authorization request is not a statement that read access was granted. Its local completion flag records only that the request finished; there is no per-type read-permission inference. Reopening the request does not guarantee the system will prompt again; A can review permissions in Apple Health.

## Exact windows

Let D be the previous completed calendar day in the time zone captured at refresh. `HealthDataWindow` computes all boundaries using `Calendar`, not fixed 24-hour subtraction.

| Metric | Window | Reason |
| --- | --- | --- |
| Steps | D 00:00 inclusive → next day 00:00 exclusive | A full activity day avoids interpreting today's partial steps as a full-day input. |
| Exercise | Same as steps | Keeps daily activity inputs aligned. |
| Resting heart rate | Same as steps | Uses completed-day resting estimates, with no substitution from regular heart rate or an arbitrary older sample. |
| Sleep | Noon on D−1 → noon on D | Keeps the sleep episode ending on D together across midnight. Includes any accessible asleep intervals within this explicitly stated window. |

Example: a September 8 refresh uses September 7 activity/RHR, and September 6 noon → September 7 noon sleep. It intentionally does not include the night ending September 8. The app displays the exact dates, times, and time zone, so A must compare those intervals rather than Apple Health's default Today screen.

Quantity queries use `.strictStartDate`: samples belong to the half-open day containing their start timestamp. A sample spanning midnight is not manually prorated. This follows Apple's daily statistics pattern, but can differ from another presentation that clips crossing samples. Sleep queries include overlapping samples and explicitly clip them to both window boundaries.

DST produces 23/25-hour windows where appropriate. Sleep uses actual elapsed duration, not subtraction of wall-clock labels. After travel, the next refresh uses the current time zone; the baseline may change. A foreground/manual refresh is needed after midnight or a time-zone change while the app remains open. There is no timer or excessive polling.

These are explicit project choices, not clinically validated feature definitions or guarantees of numerical agreement with Health's private display/priority rules. Health data can sync late; resting estimates for the current/previous day can also be revised. Refresh can therefore legitimately change yesterday's results.

## Sleep overlap rule

`SleepAggregation.hours` accepts only Core, Deep, REM, and Unspecified asleep. Awake, In Bed, unknown categories, and zero/negative-length intervals contribute nothing. Clip valid asleep intervals to the window, sort by start then end, merge overlapping/touching intervals, and sum the disjoint durations in hours. Empty/no asleep coverage returns nil, never zero.

The union is deterministic, order-independent, and counts each instant at most once even with duplicate sources or general asleep samples overlapping staged samples. No legitimate source is excluded merely because it is not Apple Watch. A source reporting Awake cannot erase a conflicting source reporting Asleep under this policy. This limitation must be considered when comparing with Health; TwinTrack does not recreate Health's private source-priority rules or claim which conflicting source is correct.

## Missing values, errors, and lifecycle

Each metric is available, missing, or query failed. Missing includes a successful query with no quantity/asleep interval and HealthKit's no-data error. Other query failures remain distinct, without retaining their potentially private descriptions. An actual reported zero step/exercise quantity is retained. Missing RHR remains nil; zero/invalid RHR is not accepted as a real resting measurement.

On initial load or foreground return, refresh accessible data after the request-completed flag exists. An explicit Apple Health action initiates the system authorization request. A callable/manual Refresh performs the same queries. No observer/background delivery is installed.

The shared state is `@MainActor`. One active refresh is coalesced, all four results are applied together, and a generation check rejects obsolete results after scene deactivation/new refresh. Scene deactivation clears in-memory health values; inactive scenes do not initiate reads. Cancellation never applies partial results. A failure/missing refresh clears old values rather than presenting stale data as current. Manual inputs remain untouched.

## Verification

Synthetic tests cover asleep categories, ignored categories, overlap/duplicates, clipping, gaps, cross-midnight and DST windows, time zones, units, missing vs zero, exact type set, request completion vs read access, shared-state integration, refresh coalescing, background invalidation, and stale result rejection. Run `HealthKitTests`, existing `TwinTrackStateTests`, `TwinTrackModelTests`, and `testThreeTabShell` on the simulator. Do not run the template launch screenshot test for evidence; A captures evidence manually.

Automated results, September 8, 2026, Xcode / iPhone 17 Pro Simulator (iOS 26.5):

- App and unit-test build: PASS.
- `HealthKitTests`: 22/22 PASS, including all seven sleep aggregation tests.
- `TwinTrackStateTests`: 7/7 PASS. Existing assertions are unchanged; tests now run asynchronously on the main actor to match the shared state's isolation.
- `testFrozenRidgeMatchesAll21GoldenProfiles`: PASS; 21/21 parity, maximum absolute error `2.8421709430404007e-14`, tolerance `1e-6`.
- Three-tab regression: PASS, confirmed by A.
- Xcode Issue navigator with warnings included: 0 warnings, 0 errors after the actor-isolation test compilation fix.

Only the named unit target and tab regression were run for this milestone. The existing template launch/screenshot test had a prior timeout and is not part of these results. A then verified physical authorization and all four query paths against Apple Health over TwinTrack's displayed windows. The available Steps result matched; Sleep, Exercise, and Resting Heart Rate correctly remained missing where Apple Health had no value. Refresh, missing-data behavior, and manual persistence passed.

Physical checks are required: A selects the connected iPhone in Xcode, builds/runs, opens Profile → Apple Health, requests the four read types, and compares available values with Apple Health over the displayed intervals. Repeat Refresh and foreground return; verify manual inputs remain saved and missing health remains unavailable. An empty result alone cannot establish a permission failure.

If signing requires an updated profile after adding the capability, A handles Xcode's normal signing action. No account, certificate, private key, serial number, or UDID is needed in this task. Report only the exact redacted error/status if blocked.

Real-data screenshots are private evidence: keep them outside the repository and do not upload them into this conversation. A confirmed that private evidence was captured. The evidence log records only that confirmation and non-sensitive pass/fail results, without a filename, path, hash, screenshot content, or personal health value.

## Apple references

- [Setting up HealthKit](https://developer.apple.com/documentation/healthkit/setting-up-healthkit)
- [Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy)
- [Authorizing access](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [Sleep analysis categories](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)
- [Step source duplication: Apple DTS guidance](https://developer.apple.com/forums/thread/759709)
- [Statistical queries](https://developer.apple.com/documentation/healthkit/executing-statistical-queries)
- [Resting heart rate estimates](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/restingheartrate)
