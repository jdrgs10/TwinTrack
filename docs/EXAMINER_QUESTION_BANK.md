# Examiner Question Bank

## Native navigation

**Question:** How did you implement and verify TwinTrack's main navigation?

**Answer outline:** TwinTrack uses one native SwiftUI `TabView` with exactly Home, TwinTrack AI, and Profile. Each tab has its own basic navigation container. A UI test verifies there are exactly three tab buttons, checks the title and selected state for every tab, and repeats the complete switching sequence three times in the iPhone Simulator.

**Evidence:** `testThreeTabShell` passed in Xcode 26.6 using the iPhone 17 Pro Simulator on 2026-09-07 with no reported warnings or errors.

**A learning status:** Not confirmed by A.

## Read-only HealthKit integration

**Question:** How does TwinTrack obtain Apple Watch health inputs?

**Answer outline:** Apple Watch synchronizes its data into Apple Health. On the iPhone, `HealthKitService` requests read access to Sleep Analysis, Step Count, Apple Exercise Time, and Resting Heart Rate, then passes transient results into the existing shared `TwinTrackState`. TwinTrack does not connect directly to the Watch and does not create a watchOS app.

**Question:** What time period does TwinTrack use for current health inputs?

**Answer outline:** Steps, Exercise, and Resting Heart Rate use the previous completed local calendar day from midnight to midnight. Sleep uses noon on the day before that through noon on the completed day, so an overnight episode belongs to its waking day. The implementation uses calendar boundaries rather than fixed 24-hour subtraction, preserving time-zone and daylight-saving behavior.

**Question:** How does TwinTrack prevent duplicate sleep or step totals?

**Answer outline:** Steps use HealthKit cumulative statistics so HealthKit handles contributions from multiple sources. Sleep samples require app-side processing: TwinTrack accepts actual asleep stages, excludes Awake and In Bed, clips samples to the selected window, and calculates the union of overlapping intervals so each instant contributes once.

**Question:** Why can TwinTrack say “No accessible recent value” without saying access was denied?

**Answer outline:** HealthKit intentionally does not reveal read authorization decisions reliably. An empty query can mean there is no data in the selected window or that the app cannot access it. TwinTrack therefore preserves a missing value and avoids claiming a specific denial state.

**Question:** How was HealthKit verified without committing private health records?

**Answer outline:** Synthetic tests verify date windows, units, sleep overlap, missing values, and shared-state concurrency. A separately verified the authorization and query behavior on a physical iPhone by comparing TwinTrack with Apple Health over the displayed intervals. Private evidence exists locally but is not committed, inspected, or copied into development records.

**Evidence:** HealthKit tests passed 22/22, including 7/7 sleep aggregation tests. Manual-input tests passed 7/7, frozen Ridge parity remained 21/21, the tab regression passed, and A confirmed the physical-device results. The private evidence is intentionally excluded from Git.

**A learning status:** Not confirmed by A.

## Shared state and Manual Inputs

**Question:** How does TwinTrack keep one source of truth across its three tabs?

**Answer outline:** The app creates one `TwinTrackState` at the application root and injects that same object above the root `TabView`. Manual Inputs writes to it, and Home, TwinTrack AI, and Profile can read the same current values. The implementation does not create separate stores for individual screens.

**Question:** How are Study Time and Screen Time represented?

**Answer outline:** The user selects Hours and Minutes with native wheel pickers. TwinTrack converts the selections into one total-minute value for each model input. This keeps the user interface readable while matching the Ridge model's `study_minutes` and `screen_time_minutes` features.

**Question:** How does TwinTrack distinguish missing data from a real zero?

**Answer outline:** All seven current inputs are optional. An unavailable value is represented as `nil` and displayed as Not entered or unavailable. If the user explicitly enters zero, zero is stored as a real value instead of being used as a missing-data placeholder.

**Question:** How are the manual values validated and persisted?

**Answer outline:** Previous Score is restricted to finite numeric values from 0 through 100. The three manual values are saved locally in `UserDefaults`, and the presence or absence of each key preserves the difference between an entered zero and a missing value. Automated recreation testing and a simulator relaunch confirmed persistence.

**Question:** Why does adding Manual Inputs not make a prediction available yet?

**Answer outline:** The frozen Ridge model requires all seven real inputs. The four HealthKit-owned values remain unavailable, so the shared state does not create a complete `TwinTrackProfile` and does not call Ridge with fake replacements.

**Evidence:** `manual_inputs_verified.png` shows the Manual Inputs sheet with Study Time `2h 48m`, Screen Time `4h 15m`, and Previous Score `82`. `manual_inputs_persistence_verified.png` shows the same saved values after stopping and relaunching the app.

**A learning status:** Not confirmed by A.

## Frozen prediction engine

**Question:** How does TwinTrack calculate its numerical prediction on the iPhone?

**Answer outline:** The app accepts exactly seven values in a fixed order. It standardizes each value using the frozen training mean and scale, multiplies the standardized values by the frozen Ridge coefficients, adds the intercept, and clamps the result to 0–100. The complete calculation uses Swift `Double` and lives in one reusable `TwinTrackModel`.

**Question:** How do you know the Swift model matches the Python model?

**Answer outline:** The Swift unit test loads 21 frozen profiles containing Python `expected_raw` and `expected_clamped` outputs. It checks the feature order and compares every Swift result at `1e-6` tolerance. All 21 passed, with maximum absolute error `2.8421709430404007e-14`.

**Question:** Why must Foundation Models not calculate the prediction?

**Answer outline:** A language model is not the numerical source of truth and may produce nondeterministic results. TwinTrack uses the single deterministic Ridge engine for scores and future What-If deltas; Foundation Models may only explain those computed results.

**Evidence:** `ridge_21_of_21_parity_pass.png` records the readable parity result, and `ridge_parity_xcode_context.png` records the wider TwinTrack/Xcode test context.

**A learning status:** Not confirmed by A.
