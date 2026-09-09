# HealthKit implementation and verification contract

Status: original HealthKit milestone verified on September 8, 2026. The timing update and subsequent refresh-state/tab-transition corrections were verified on September 9, 2026 with 97/97 automated tests and A's physical retest. Native spinner visibility remains a non-blocking final-polish item. No real health values belong in this document, tests, Git, logs, or AI prompts.

## Ownership and permissions

Apple Watch → Apple Health → iPhone HealthKit → `HealthKitService` → existing `TwinTrackState`. No watchOS app or direct Watch connection is used. The service has one lazy `HKHealthStore` and returns transient results, not a second observable store. `TwinTrackState` publishes one four-metric snapshot and exposes the original seven-value `TwinTrackProfile` boundary. The existing frozen Ridge engine remains unchanged; completed real-data commits can create predictions through the existing history path.

Exactly these read types are requested:

| Ridge feature | HealthKit type | Unit | Processing |
| --- | --- | --- | --- |
| `sleep_hours` | `HKCategoryType(.sleepAnalysis)` | elapsed seconds / 3600 | Clip and merge asleep intervals from all accessible sources. |
| `steps` | `HKQuantityType(.stepCount)` | count | HealthKit `.cumulativeSum`; no raw-sample or separate-source summation. |
| `exercise_minutes` | `HKQuantityType(.appleExerciseTime)` | minutes | HealthKit `.cumulativeSum`. |
| `resting_heart_rate` | `HKQuantityType(.restingHeartRate)` | count/minute (bpm) | Newest finite positive resting sample in the last 72 elapsed hours; retain its start timestamp. |

`toShare` is empty. Debug and Release reference `twintrack.entitlements`, containing only `com.apple.developer.healthkit = true`. Generated Info.plist includes `NSHealthShareUsageDescription`. No write usage key or write request, clinical-record entitlement, background-delivery entitlement, or HealthKit-required-device restriction is added; the app can still show unavailable states when HealthKit is unsupported.

Availability is checked before HealthKit queries. A completed authorization request is not a statement that read access was granted. Its local completion flag records only that the request finished; there is no per-type read-permission inference. Once setup is completed, the Apple Health screen shows Refresh without the request-access action. A repeated call to the setup method also reuses refresh without reauthorization. A can review permissions in Apple Health.

## Exact windows

Let D be yesterday in the calendar/time zone captured at refresh. Activity and sleep use local calendar boundaries. RHR uses an elapsed-time recency interval.

| Metric | Window | Processing |
| --- | --- | --- |
| Steps | D 00:00 inclusive → today 00:00 exclusive | HealthKit cumulative statistics; no partial current-day total. |
| Exercise | Same as Steps | `appleExerciseTime` cumulative statistics. |
| Sleep, before local noon | D noon → now | Includes accessible overnight sleep ending this morning immediately after it syncs. |
| Sleep, at/after local noon | D noon → today noon | Stable overnight window for the rest of the day. |
| Resting heart rate | now − 72 elapsed hours → now, both inclusive | Latest finite, positive `restingHeartRate` sample by start timestamp. |

A Tuesday morning refresh includes Monday-night/Tuesday-morning sleep and Monday activity. An afternoon refresh caps sleep at Tuesday noon. RHR can come from the current day. These intentionally different source periods must not be described as one shared measurement interval.

Steps/Exercise queries retain `.strictStartDate` and cumulative statistics. A sample spanning midnight is not manually prorated. Sleep queries include overlapping samples and clip them before union/deduplication. Before noon the endpoint is now; this makes already-synced asleep intervals available without claiming that HealthKit can identify whether the user has finished sleeping.

RHR queries fetch only `HKQuantityType.restingHeartRate` samples whose start timestamp is in the inclusive recency interval. No single-result limit is used: an invalid latest sample must not hide an older valid one. The selector rejects zero, negative, nonfinite, old, and future values. Equal timestamps use the greater valid value as a deterministic tie-break. No source/device identifiers are retained. No sample means unavailable; ordinary, live, workout heart rate and HRV are never substitutes.

DST produces 23/25-hour local windows where appropriate. RHR remains exactly 72 elapsed hours even across DST. After travel, the next refresh captures the current time zone. There is no timer or repeated polling.

## Immutable history compatibility

Existing snapshots retain their values and activity/sleep boundaries. The persisted JSON key stays unchanged. New Health-window metadata has optional `semanticsVersion` (2) and `restingHeartRateSampleDate` fields; legacy JSON decodes these as nil and retains its completed-day RHR meaning. No stored snapshot is rewritten by loading it.

New snapshots retain the actual sleep query cutoff. Duplicate identity still compares the seven input values and source metadata: completed activity day, overnight start, time zone, timing semantics, and selected RHR sample timestamp. An advancing morning cutoff alone does not create new history. Changed input values, a new overnight/activity period, or a different RHR sample can create a legitimate snapshot after a real-data commit. Legacy metadata retains exact equality comparison. No prediction is saved by rendering, selecting history, or running What-If.

## Sleep overlap rule

`SleepAggregation.hours` accepts only Core, Deep, REM, and Unspecified asleep. Awake, In Bed, unknown categories, and zero/negative-length intervals contribute nothing. Clip valid asleep intervals to the window, sort by start then end, merge overlapping/touching intervals, and sum the disjoint durations in hours. Empty/no asleep coverage returns nil, never zero.

The union is deterministic, order-independent, and counts each instant at most once even with duplicate sources or general asleep samples overlapping staged samples. No legitimate source is excluded merely because it is not Apple Watch. A source reporting Awake cannot erase a conflicting source reporting Asleep under this policy. This limitation must be considered when comparing with Health; TwinTrack does not recreate Health's private source-priority rules or claim which conflicting source is correct.

## Missing values, errors, and lifecycle

Each metric is available, missing, or query failed. Missing includes a successful query with no quantity/asleep interval and HealthKit's no-data error. Other query failures remain distinct, without retaining their potentially private descriptions. An actual reported zero step/exercise quantity is retained. Missing RHR remains nil; zero/invalid RHR is not accepted as a real resting measurement.

On initial load or foreground return, refresh accessible data after the request-completed flag exists. An explicit Apple Health action initiates the system authorization request. Home pull-to-refresh awaits the same `TwinTrackState.refreshHealth` path and keeps the native iOS spinner. The existing Health details action also uses that path. `HKObserverQuery` and background delivery are optional future polish only; neither is implemented here.

The shared state is `@MainActor`. One active refresh is coalesced. Previously committed readings and their source window remain visible while queries run into local results. Only after the queries finish does the state replace the source window and publish all four results together, without intervening suspension; history saving follows that commit. A missing/failed metric replaces only its own previous result, leaving other returned metrics available. Setup completion remains independent of missing data and query failure. Both Home and Apple Health retain available values during refresh; Home keeps the native spinner.

A generation check rejects obsolete results after scene deactivation/new refresh. Scene deactivation still clears in-memory health values for privacy; inactive scenes do not initiate reads. Cancellation commits neither partial results nor a new window/history snapshot, preserves the last committed active-scene readings, and releases the refreshing flag. Manual inputs remain untouched. Launch, foreground, Home pull-to-refresh, and the Health details Refresh action all use the same implementation.

## Verification

Synthetic tests cover asleep categories, ignored categories, overlap/duplicates, clipping, gaps, cross-midnight and DST windows, time zones, units, missing vs zero, exact type set, request completion vs read access, shared-state integration, refresh coalescing, background invalidation, and stale result rejection. Run `HealthKitTests`, existing `TwinTrackStateTests`, `TwinTrackModelTests`, and `testThreeTabShell` on the simulator. Do not run the template launch screenshot test for evidence; A captures evidence manually.

Historical automated results for the original completed-day implementation, September 8, 2026, Xcode / iPhone 17 Pro Simulator (iOS 26.5):

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

## Timing update automated verification — September 9, 2026

Xcode `TwinTrack Serial`, one existing iPhone 17 Pro Simulator (iOS 26.5): build PASS, 93/93 tests passed across two test targets, 0 compiler warnings and 0 errors in the final Issue navigator (warnings included, no filters).

- HealthKit: 31/31, including fresh morning/noon sleep, overnight/DST boundaries, latest valid RHR, 72-hour cutoff, invalid/missing samples, timestamp propagation, and the existing regressions.
- History: 28/28, including legacy metadata decoding, morning-cutoff duplicate prevention, timestamp persistence, and immutable snapshots after new sleep/RHR data.
- Manual/state: 7/7; Home: 5/5; What-If: 17/17.
- Ridge: the parity test passed all 21 golden profiles; frozen engine, parameters, expected outputs, and feature order are unchanged.
- UI: 4/4, covering repeated three-tab switching, Home pull-to-refresh, history empty state, and What-If navigation.
- Source inspection confirmed launch, foreground, and native Home pull-to-refresh all call `TwinTrackState.refreshHealth`.

The first run had one tab-header lookup timeout. The full unchanged rerun passed; no assertions were weakened and no navigation change was made. The simulator also logged Apple's accessibility duplicate-class diagnostic. This is separate from compiler warnings and did not fail the final tests. No physical device or real health values were accessed, and no screenshots were requested or captured by the assistant.

## Timing update physical review

A completed the physical-device retest without sharing private values or screenshots. HealthKit values, pull-to-refresh function, no repeated access request, and manual-input persistence passed. The refresh indicator was not clearly visible and is deferred as a non-blocking aesthetic item for final UI polish.

## Refresh-state and tab-transition fixes — verified

September 9, 2026. A reported values disappearing on pull-to-refresh and an apparent need to repeat Health setup. No personal values or device screenshots were inspected for this fix.

**Before:** `refreshHealth` cleared the four readings and replaced their window before awaiting queries. Both Health views also hid available readings while refreshing. Cancellation could therefore leave the cleared state until another refresh. The request-access button remained visible after completed setup; routine refresh itself did not reset the persisted completion flag or call authorization.

**Change:** Keep committed readings/window until the local query result is ready; publish the four-result snapshot after a cancellation/generation check, then save history. Release the refreshing flag after that work. Preserve visible available values during refresh. Hide the setup action once completed and guard repeated setup calls by routing them to the existing refresh path. Retain lifecycle privacy invalidation and all approved timing rules.

**Why:** Refresh should re-read accessible HealthKit data without restarting setup or temporarily destroying committed input state. Request completion must never imply that read permission was granted.

**Improvement:** Stable values during native refresh, no false setup prompt, and consistent shared refresh state.

**Automated evidence:** Xcode `TwinTrack Serial`, existing iPhone 17 Pro Simulator (iOS 26.5): final build PASS; 0 compiler warnings and 0 errors in the unfiltered Xcode Issue navigator; final full rerun 97/97 passed. HealthKit 35/35; manual/state 7/7; Home 5/5; What-If 17/17; history 28/28; Ridge parity test 21/21 golden profiles; UI 4/4. The four new tests cover pending/cancelled refresh preservation, one atomic four-metric publication, unchanged manual values and setup, independent missing/failure results, and no repeated authorization across setup/launch/foreground refresh and recreation. Existing tests retain timing, coalescing, stale-result rejection, missing-vs-zero, and snapshot regressions.

The first fix run passed all 93 unit tests but timed out checking the Profile subtitle in `testHomePullToRefreshAndBottomAction`. The unchanged full rerun passed 97/97. No test assertion or navigation code was changed to obtain that result.

**Physical evidence:** A confirmed pull-to-refresh function, stable HealthKit values, no repeated access request, manual-input persistence, and smooth switching among Home, TwinTrack AI, and Profile without overlap or ghosting. Native spinner visibility remains deferred final polish and does not block this verified milestone. No private screenshot or personal value was requested or inspected.
