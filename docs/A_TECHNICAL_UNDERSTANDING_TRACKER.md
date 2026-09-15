# A Technical Understanding Tracker

## Assistant quality pass B — 2026-09-14

Focused Foundation Models guidance/output/source/refusal fixes passed the final build and **225/225 automated tests (213 unit + 12 UI)**. Final compiler warnings/errors: **0/0**; debugger warnings: **1**. EVIDENCE_LOG preserves the earlier 222/225 run and three unchanged passing UI reruns. Build marker `FMQ-2026-09-14-B`; fresh physical model quality remains NOT VERIFIED. See ASSISTANT_EVALUATION and EVIDENCE_LOG for exact evidence and A's test matrix. Existing completed core milestones are preserved. No new learning confirmation or completion percentage is recorded.

Deferred until a separately approved UI milestone: softer accessible dark composer focus border, jump-to-latest, Chat Library visual polish and local favorites/stars.

## Integrated reliability / interface update — 2026-09-11

- The original explicit-prediction and local-library checkpoints are preserved. The reliability gate passed 171/171; final integrated build and 190/190 tests passed (180 unit + 10 UI), with one debugger warning and zero errors. EVIDENCE_LOG records the evidence and limits.
- A real simulator diagnostic passed four fixed prompts without tools or a global guided schema. The same food prompt on the original integration returned only the sanitized category `toolFailure`. The earlier physical failure's exact cause is not established.
- General chat now uses plain Foundation Models text with bounded recent context. Clear app operations route through Swift. “6 more hours” is an increase, “another hour” is an increase by one hour, and ordinary sleep/time statements remain conversation. All numbers in personalized cards come from existing Swift state/calculations/history.
- Error categories, one context-only recovery attempt and cancellation are explicit; refusal is never automatically retried. Full saved chats are not truncated to the model's short context budget.
- Compact welcome/composer, a named Manual What-If action and inline errors preserve the existing keyboard/navigation lifecycle.
- One shared duration-wheel UI serves Manual Inputs and temporary What-If editors. Set/Increase/Decrease are explicit; units, Cancel and precise unchanged values remain protected.
- One persisted root Appearance preference supplies System/Light/Dark to all tabs and presentations. It is separate from, and cannot overwrite, the single production input state.
- Physical model quality, safety responses, screen appearance and duration usability remain pending A's review. **Nothing newly marked learned; understanding not confirmed by A.**


## Reliability checkpoints 1–2

- Checkpoint 1 remains VERIFIED at its original 136/136 checkpoint; no reimplementation.
- Checkpoint 2 automated result: build PASS, 153/153 total, including 15 new chat-library unit tests and two new UI tests. Xcode warnings/errors: 0.
- Compact shell: fixed Library/title/New Chat header, empty-only welcome/subtitle, direct composer sliders action, interactive keyboard dismissal and explicit keyboard escape. Both New Chat entry points clear the active draft.
- Storage: versioned local Application Support archive, atomic complete-protection writes and backup exclusion. Unsupported/corrupt archives remain untouched. No raw samples, request snapshots, hidden tool transcripts, or debug errors are stored.
- Isolation: old cards stay historical; reopening cannot mutate TwinTrackState. New requests capture current inputs. Chat deletion and Clear Prediction History are independent. Cancellation/deletion/New Chat reject late responses.
- Relaunch evidence: the UI test stops and launches the app with a separate synthetic library, reopens the renamed chat, then verifies Cancel and confirmed deletion.
- Limits: physical visual approval and actual locked-device encryption behavior are not proven by simulator tests. Foundation Models reliability remains checkpoint 3, awaiting approval.
- A learning status: **not confirmed by A**.

## Apple Foundation Models — initial integration

- Initial integration status: Xcode build and 129/129 automated tests passed, including 31 assistant checks and all core regressions. Actual model runtime/physical UI approval remains pending.
- Conversation boundary: `AssistantConversation` manages visible chat messages and a protected local library. One authoritative `TwinTrackState` remains. New Chat preserves prior nonempty chats; reopening historical cards never restores inputs. New requests capture current inputs. No external LLM or cloud chat sync was added.
- Framework boundary: `FoundationAssistantService` maps the installed SDK's availability and generation APIs through a mockable protocol. Cancellation invalidates late responses; retry retains the original snapshot; context limits offer conversation reset.
- Tool boundary: exactly `readCurrentTwin`, `runWhatIf`, and `readPredictionHistory`. All use one captured committed snapshot. They cannot refresh/authorize HealthKit, mutate manual inputs, save scenarios, edit history, or change Ridge.
- Numerical boundary: Swift alone constructs current/scenario/history cards. What-If delegates to the existing engine. Generated personalized prose is omitted when cards exist; generated text never supplies card numbers.
- Validation boundary: Swift checks exact feature, operation, unit, finite value, range, and supporting quotation. Ambiguity/unsupported evidence asks clarification. Source dates preserve the committed Health time zone after travel.
- Response boundary: ordinary wellness does not require all seven inputs; symptom and urgent response kinds have non-diagnostic help policies. Relevant model questions disclose synthetic production training and research limitations; ordinary scenarios avoid repeated disclosure.
- Verification distinction: mocks prove lifecycle and policy behavior, direct tool tests prove deterministic boundaries, and simulator UI tests prove navigation/fallback. Only A's compatible iPhone can verify actual model interpretation, generated quality, safety routing, and visual acceptance.
- References for later explanation: `FOUNDATION_MODELS_IMPLEMENTATION.md`, `ASSISTANT_EVALUATION.md`.
- A learning status: **not confirmed by A**. No code teaching or learned-status update has occurred.

## Three-tab SwiftUI shell

- Implementation state: verified in the iPhone 17 Pro Simulator.
- Architecture to explain later: one root SwiftUI `TabView` owns exactly three tabs. Each tab currently contains a simple `NavigationStack` and title.
- Verification to explain later: `testThreeTabShell` asserts the tab count, initial Home state, correct title and selection for every tab, and three repeated switching cycles.
- Transition rule: tab selection disables the content animation transaction so only the selected page is visually active; the strengthened UI test asserts that the other page headers are absent after every switch.
- Useful code comment: the root navigation comment records that the locked navigation has exactly three tabs and that iOS owns tab selection and safe-area behavior.
- A learning status: not confirmed by A.

## Frozen Swift Ridge model

- Implementation state: verified with 21/21 golden profiles in the iPhone 17 Pro Simulator.
- Architecture to explain later: `TwinTrackProfile` accepts exactly seven typed `Double` values, and one `TwinTrackModel` owns all scaling, Ridge calculation, and 0–100 clamping.
- Locked order: sleep hours, steps, exercise minutes, resting heart rate, study minutes, screen time minutes, previous score.
- StandardScaler rule: each value becomes `z = (x - mean) / scale` before applying its frozen Ridge coefficient.
- Precision rule: the complete numerical path uses `Double`; the required tolerance is `1e-6`.
- Safety boundary: Foundation Models may explain a prediction later but must never reproduce or calculate the Ridge numbers.
- Golden-test rule: expected Python values are frozen and must never be edited to make a test pass.
- Verification result: 21/21 passed, maximum absolute error `2.8421709430404007e-14`, zero warnings, zero errors.
- A learning status: not confirmed by A.

## Shared state and Manual Inputs

- Implementation state: verified in the iPhone Simulator with automated tests and A's manual visual evidence.
- Architecture to explain later: the app creates exactly one `TwinTrackState` as a root `@StateObject` and passes that same object through the SwiftUI environment above all three tabs.
- Ownership rule: the shared state owns the four future HealthKit values and the three manual values. Screens do not own competing copies of production data.
- Manual conversion rule: Study Time and Screen Time are selected as Hours and Minutes, then stored as total minutes. For example, `2h 48m` is stored as 168 minutes.
- Validation rule: Previous Score accepts finite numeric values from 0 through 100. Invalid, nonnumeric, and out-of-range drafts cannot be saved.
- Persistence rule: the three manual values use local `UserDefaults` and survive state recreation and app relaunch.
- Missing-data rule: every value is optional. Missing data is `nil`, while an explicitly entered zero remains a valid value.
- Ridge boundary: a complete `TwinTrackProfile` is unavailable until all seven real inputs exist, so the Ridge engine cannot be called with fabricated HealthKit values.
- Verification result: 7/7 new state tests passed; the 21/21 Ridge parity test and three-tab regression test also passed. A's two screenshots show the same saved values before and after relaunch.
- A learning status: not confirmed by A.

## Read-only HealthKit integration

- Implementation state: verified with automated tests and A's physical-iPhone check.
- Architecture to explain later: Apple Watch data synchronizes through Apple Health; `HealthKitService` reads the iPhone HealthKit store and supplies transient results to the existing `TwinTrackState`. There is no direct Watch connection, watchOS app, or second observable health store.
- Exact types: `sleepAnalysis`, `stepCount`, `appleExerciseTime`, and `restingHeartRate`, requested for read access only.
- Window rule: Steps and Exercise use the previous completed local calendar day. Sleep uses yesterday local noon through the earlier of now and today local noon. Resting Heart Rate selects the latest finite positive sample within the previous 72 elapsed hours and retains its timestamp. Calendar arithmetic preserves time-zone and daylight-saving boundaries for activity and sleep.
- Aggregation rule: HealthKit cumulative statistics merge Steps and Exercise sources. Resting Heart Rate uses the latest valid recent resting estimate, never an ordinary heart-rate substitute. Sleep counts Core, Deep, REM, and Unspecified asleep, excludes Awake and In Bed, clips to the window, and unions overlaps so each instant is counted once.
- Missing-data rule: every metric is available, missing, or failed. A missing sample remains unavailable and never becomes zero. HealthKit's authorization completion cannot reliably prove whether read access was granted or denied.
- Refresh rule: launch, foreground return, Home pull-to-refresh, and the Health details action use one shared query path. Existing readings/window remain committed while queries run locally; all four results replace them together after cancellation and generation checks. The persisted request-completed flag means only that setup was presented, survives recreation, and prevents routine reauthorization. Missing or failed reads do not imply denial.
- Verification result: HealthKit tests 35/35; manual/state 7/7; Home 5/5; What-If 17/17; History 28/28; Ridge parity 21/21; UI 4/4. A's physical retest confirmed stable values, no repeated Health access request, preserved manual inputs, and working refresh. Private evidence remains outside Git.
- A learning status: not confirmed by A.

## Home real-data wiring and UI polish

- Implementation state: verified with automated simulator tests and A's physical-device visual review.
- Architecture to explain later: `HomeView` reads the single environment-owned `TwinTrackState`. It displays the four transient HealthKit results and three persisted manual inputs without creating another data store.
- Prediction rule (superseded by verified reliability checkpoint 1): only explicit Run Prediction evaluates and saves a complete current baseline. Home display reads the last run/status without calculating. Missing inputs never become fabricated values.
- Refresh rule: Home attaches native SwiftUI pull-to-refresh to its scroll container and directly awaits the existing `refreshHealth()` path. A short minimum presentation interval keeps the native refresh interaction alive without delaying the state commit. A confirmed the refresh function; indicator visibility remains deferred final polish.
- Header rule: Home, TwinTrack AI, and Profile reuse one lightweight `PageHeader` with their own title and locked subtitle. Its optional mark appears only on Home. The header grows for accessibility Dynamic Type sizes.
- Accessibility and layout rule: metric cards move from two columns to one for accessibility text sizes, content scrolls above the native tab bar, and the final TwinTrack AI action remains reachable.
- Verification result: Home tests 5/5, HealthKit tests 22/22, Ridge parity 21/21, Manual/State tests 7/7, and repeated three-tab UI regression passed. A approved the header/logo integration, subtitles, prediction hierarchy, pull-to-refresh, card layout, scrolling, bottom-tab clearance, and three-tab header consistency on a physical iPhone. Warnings and errors were zero.
- A learning status: not confirmed by A.

## Prediction History and 7-day trends

- Implementation state: verified and committed.
- Save rule (superseded by verified reliability checkpoint 1): explicit Run Prediction is required. Health refresh, Manual Inputs Save, rendering, tab changes, display recomputation, and What-If never save real prediction history.
- Identity rule: duplicate comparison uses the seven actual input values and relevant Health source metadata, excluding creation time and treating prediction as derived consistency evidence.
- Immutability rule: every legitimate snapshot remains in full history. Loading or viewing a snapshot never changes current state, stored history, HealthKit, or manual inputs.
- Seven-day rule: the chart uses local calendar days from start of today minus six days through start of tomorrow, shows the latest legitimate snapshot per day, and leaves missing days empty without interpolation or carry-forward.
- Presentation rule: bars use a fixed 0–100 scale. A real bar selects the exact immutable snapshot represented by that day and opens a read-only detail with all seven saved inputs.
- Clear rule: Profile → Data & Privacy → Clear Prediction History uses destructive confirmation and removes history only.
- Verification result: History 28/28, total automated suite 97/97 after the refresh/UI fixes. The committed implementation is in `2a0d640` and `ebb1c9c`.
- A learning status: not confirmed by A.

## HealthKit refresh and tab behavior correction

- Implementation state: verified by automated tests and A's physical retest.
- Refresh-state rule: committed Health readings remain visible while a refresh reads into a temporary result; the state publishes the new four-metric snapshot and its window together.
- Setup rule: completion records only that the authorization request was presented. Routine refresh never calls authorization again, and missing data never resets setup or claims denial.
- Tab rule: one native three-tab shell remains; selection disables content-transition animation so outgoing and incoming pages do not overlap.
- Deferred item: native spinner visibility is a non-blocking aesthetic issue reserved for final UI polish. Refresh correctness is verified.
- A learning status: not confirmed by A.

## Deterministic What-If simulation

- Implementation state: verified with automated simulator tests and A's visual review.
- Architecture to explain later: `WhatIfScenario` is a temporary value type containing a copied `TwinTrackProfile`, a captured baseline prediction, and validated overrides. It has no access to `TwinTrackState` setters, `UserDefaults`, or HealthKit.
- Complete-baseline rule: scenario creation requires the existing complete seven-input profile. If any real value is missing, the UI identifies the missing inputs and disables simulation without inserting zero or another estimate.
- One-engine rule: the baseline and modified scenario use the existing frozen `TwinTrackModel.predict`. What-If contains no coefficients, scaling, or second prediction equation.
- Multiple-change rule: all selected overrides are applied to one profile copy before Ridge evaluates it. Individual deltas are never calculated and added together.
- Clamping rule: displayed delta equals the clamped scenario prediction minus the captured clamped baseline prediction, including at the 0 and 100 boundaries.
- Validation rule: Previous Score accepts 0 through 100; Steps, Exercise, Study, Screen Time, and Sleep accept non-negative finite values; Resting Heart Rate must be positive. Uncomputably large and non-finite values are rejected without inventing restrictive scientific ranges.
- Units rule: Sleep edits display hours/minutes and convert to `sleep_hours`; Study and Screen Time display hours/minutes and remain total model minutes. Steps, Exercise, Resting Heart Rate, and Previous Score retain their frozen model units.
- Lifecycle rule: Cancel, reset, tab exit, view exit, or a change in current data discards the temporary scenario. Tests confirm shared values and persisted manual inputs remain unchanged, and there are no HealthKit writes.
- Wording rule: the UI calls the result a model simulation and states that it does not prove causation or guarantee an outcome. Resting Heart Rate is identified as a weak/noisy prototype input rather than advice.
- Header correction: the shared `PageHeader` exposes an optional mark. Home shows the approved mark; TwinTrack AI and Profile omit it. A approved the title/subtitle spacing after this correction.
- Verification result: What-If tests 17/17, Ridge parity 21/21, HealthKit tests 22/22, Manual/State tests 7/7, Home tests 5/5, and UI tests 3/3 passed. Warnings and errors were zero. A approved the What-If UI and header/logo correction.
- A learning status: not confirmed by A.
