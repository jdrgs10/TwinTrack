# Examiner Question Bank

## Assistant quality pass B — 2026-09-14

Focused Foundation Models guidance/output/source/refusal fixes passed the final build and **225/225 automated tests (213 unit + 12 UI)**. Final compiler warnings/errors: **0/0**; debugger warnings: **1**. EVIDENCE_LOG preserves the earlier 222/225 run and three unchanged passing UI reruns. Build marker `FMQ-2026-09-14-B`; fresh physical model quality remains NOT VERIFIED. See ASSISTANT_EVALUATION and EVIDENCE_LOG for exact evidence and A's test matrix. Existing completed core milestones are preserved. No new learning confirmation or completion percentage is recorded.

Deferred until a separately approved UI milestone: softer accessible dark composer focus border, jump-to-latest, Chat Library visual polish and local favorites/stars.

Questions for later review (not marked learned): Where can general sleep prose be falsely blocked? How do reported values differ from HealthKit measurements? Why is a verified reference not validation of the generated answer? Why does parity not measure grade accuracy? How can a benign topic recover while a later refused-task continuation keeps safeguards? Why must saved replies retain their original provenance?

Current integrated automated evidence: **190/190 tests**, build PASS, one debugger warning and zero errors. Actual minimal simulator model sessions passed 4/4; updated physical response quality remains pending A. This records implementation evidence, not confirmed learning or real-world Ridge validity.

## Integrated assistant reliability, duration and appearance — 2026-09-11

**Question:** What evidence distinguishes a model problem from an integration problem?

**Answer outline:** Four fixed prompts passed fresh text-only sessions in the simulator. The original food-question integration returned `toolFailure` on a controlled empty-snapshot comparison. That identifies a simulator tool-path failure, not the exact earlier physical exception. No private prompt, response or underlying error was recorded. Final physical quality/safety still needs A's evaluation.

**Question:** How can ordinary conversation remain natural without letting a model invent authoritative scores?

**Answer outline:** Ordinary chat uses plain text with concise instructions and no app tools/global response schema. Only clear app intent routes to captured current state, stored history or the existing What-If engine. Swift parses permitted features/operations/units and renders numerical cards itself. Ordinary numbers/times are allowed; recognizable invented personalized numerical claims are rejected as defense in depth. Arbitrary model wording still needs physical/adversarial review.

**Question:** How are “6 more hours,” old context and errors handled?

**Answer outline:** The parser recognizes a six-hour increase, while range validation remains distinct from ambiguity. Recent text context is bounded and excludes cards; the full archive remains intact. A context-limit error can retry once with the latest message only. Typed SDK categories remain distinct, safety is never automatically retried, and cancellation tokens prevent late output leaking into another chat.

**Question:** How do the new time controls and appearance preserve the architecture?

**Answer outline:** One reusable Hours/Minutes view edits duration drafts. Set/increase/decrease convert into the unchanged seven model units and existing scenario validation; Cancel never calls the update callback. One root appearance preference drives inherited scheme changes; Profile edits that same binding. Approved Home logo variants resolve through the asset catalog. There is no second production input store or per-screen theme preference.

**A learning status:** Not confirmed by A. Automated evidence and physical-review status are maintained separately in EVIDENCE_LOG.


## On-device assistant and deterministic tools

**Question:** What does Foundation Models own, and what does Swift own?

**Answer outline:** Foundation Models interprets conversational intent and produces general responses. Three Swift tools read the committed twin, run the existing deterministic What-If engine, and read immutable history. Only Swift creates the numeric result cards. The model never supplies card values, changes inputs, or calculates Ridge predictions.

**Question:** What happens if HealthKit refreshes while a scenario request is running?

**Answer outline:** Send captures one value snapshot before any suspension. Every tool in that request, including retries, uses the same captured profile and metadata. Baseline, scenario, delta, and source details therefore agree. The tools have no setters or HealthKit query path.

**Question:** How are ambiguous natural-language changes handled?

**Answer outline:** The model requests typed arguments, then Swift checks the seven permitted feature keys, operation, compatible unit, finite amount, existing range, unique features, and exact supporting quotation. Unsupported or unclear evidence produces clarification. Natural-language extraction is still evaluated on the actual model; typed schemas alone do not prove semantic correctness.

**Question:** Why are generated explanations omitted beside numeric cards in this version?

**Answer outline:** Swift renders the trustworthy values directly. Omitting unrestricted accompanying personalized prose prevents a generated score or delta from contradicting the card. Optional personalized explanations can be considered separately; they are not necessary for the approved minimum assistant surface.

**Question:** How do availability, privacy, and recovery work?

**Answer outline:** The app distinguishes unsupported device, disabled Apple Intelligence, model-not-ready, and generic unavailable states. Core screens and manual What-If remain usable. Chat uses the on-device framework and a protected local library, with no external LLM API. Stop/tab exit/background cancels generation and rejects late output. In-memory Retry uses the original snapshot; reopened interrupted requests require an explicit current-input retry. New Chat resets the active conversation only.

**Question:** Does a passing automated symptom test prove that the model recognizes urgent symptoms?

**Answer outline:** No. It proves the Swift policy for a supplied reply kind. A must separately evaluate the physical model's classification and response quality using synthetic prompts. General wellness should remain helpful without a forced disclaimer; symptoms must avoid diagnosis and urgent cases need appropriate professional-help guidance. Apple guardrails are respected.

**Question:** When should the assistant disclose synthetic training?

**Answer outline:** On relevant questions about training, data, methodology, reliability, or scientific limitations. It explains that production Ridge uses synthetic student profiles, real-data studies are separate evidence, and parity does not establish real-world predictive validity. Ordinary scenario cards use concise model wording without a repeated training paragraph.

**Evidence:** 31/31 assistant automated tests and 129/129 complete simulator tests. Thirty prompt evaluation rows distinguish mock/direct-tool checks from physical model results, which remain pending.

**A learning status:** Not confirmed by A.

## Native navigation

**Question:** How did you implement and verify TwinTrack's main navigation?

**Answer outline:** TwinTrack uses one native SwiftUI `TabView` with exactly Home, TwinTrack AI, and Profile. Each tab has its own navigation container. The selection transaction disables content animation so outgoing and incoming pages are not briefly composited. A UI test verifies exactly three buttons, the title and selection, absence of the two inactive page headers, and three repeated switching cycles.

**Evidence:** `testThreeTabShell` passed in Xcode 26.6 using the iPhone 17 Pro Simulator on 2026-09-07 with no reported warnings or errors.

**A learning status:** Not confirmed by A.

## Home real-data wiring and UI polish

**Question:** How does Home use real app data without creating another source of truth?

**Answer outline:** `HomeView` reads the one root `TwinTrackState` from the SwiftUI environment. The screen formats the four transient HealthKit results and three persisted manual inputs for display, while the shared state remains the owner of those values.

**Question:** When does Home show a prediction?

**Answer outline:** Home displays the last explicit prediction run and its freshness status. Run Prediction requires seven real inputs and current eligible source periods. Display reads never evaluate Ridge. Missing inputs remain missing; older results are identified as previous results.

**Question:** How is Home refreshed?

**Answer outline:** Home uses native SwiftUI pull-to-refresh and awaits the one shared HealthKit refresh method. Checkpoint 1 removed the artificial minimum delay. Existing readings remain visible while local queries run and are replaced atomically. Indicator visibility remains deferred final polish.

**Question:** How was the Home design kept consistent and accessible?

**Answer outline:** All three primary tabs reuse a lightweight page header with a title and locked subtitle. Its optional approved mark appears only on Home. Home preserves native safe areas and scrolling, changes metric cards to one column at accessibility text sizes, and keeps the final TwinTrack AI action reachable above the tab bar.

**Evidence:** Home tests passed 5/5, HealthKit tests 22/22, Ridge parity 21/21, Manual/State tests 7/7, and the repeated three-tab UI regression passed. A completed the physical-device review and approved the header/logo integration, subtitles, prediction hierarchy, pull-to-refresh, card layout, scrolling, bottom-tab clearance, and header consistency. No private screenshot was inspected or committed.

**A learning status:** Not confirmed by A.

## Deterministic What-If simulation

**Question:** How does TwinTrack calculate a What-If result without changing current data?

**Answer outline:** `WhatIfScenario` receives a value-type copy of the complete `TwinTrackProfile`. Validated scenario edits change only that copy. It cannot call shared-state setters, persistence, or HealthKit, and it is discarded on cancel or tab exit.

**Question:** Does What-If contain another Ridge equation?

**Answer outline:** No. The scenario applies all overrides to one copied profile and calls the same frozen `TwinTrackModel.predict` used by Home. No coefficients or StandardScaler logic are duplicated in What-If.

**Question:** How is the What-If delta calculated at the model boundaries?

**Answer outline:** Both baseline and scenario predictions use the production predictor's 0–100 clamping. The displayed delta is clamped scenario minus clamped baseline, so it remains correct even when either score reaches a boundary.

**Question:** What happens if one current input is missing?

**Answer outline:** A complete seven-input baseline is required. The UI identifies missing values and disables simulation; it never substitutes zero, estimates a value, or runs Ridge with a fabricated profile.

**Question:** How does What-If support several simultaneous changes?

**Answer outline:** All selected values are written to a single temporary scenario copy before one Ridge evaluation. TwinTrack does not compute separate one-variable deltas and sum them, which would be incorrect after clamping.

**Question:** Why is What-If described as predictive rather than causal?

**Answer outline:** The frozen model estimates statistical relationships in its training data. The UI therefore reports that the model prediction changed and explicitly says this does not prove causation or guarantee an academic outcome.

**Evidence:** Seventeen deterministic What-If tests cover baseline immutability, one and multiple changes, all seven missing-baseline cases, validation, clamping, cancellation, persistence protection, unit conversion, and scenario-copy isolation. Ridge remained 21/21, HealthKit 22/22, Manual/State 7/7, Home 5/5, and UI tests 3/3. A approved the What-If UI and the final rule that only Home shows the logo.

**A learning status:** Not confirmed by A.

## Read-only HealthKit integration

**Question:** How does TwinTrack obtain Apple Watch health inputs?

**Answer outline:** Apple Watch synchronizes its data into Apple Health. On the iPhone, `HealthKitService` requests read access to Sleep Analysis, Step Count, Apple Exercise Time, and Resting Heart Rate, then passes transient results into the existing shared `TwinTrackState`. TwinTrack does not connect directly to the Watch and does not create a watchOS app.

**Question:** What time period does TwinTrack use for current health inputs?

**Answer outline:** Steps and Exercise use the previous completed local calendar day. Sleep uses yesterday local noon through the earlier of now and today local noon, so the latest overnight sleep can appear during the morning. Resting Heart Rate uses the latest finite positive sample within 72 elapsed hours and retains its timestamp. Local calendar arithmetic preserves time-zone and daylight-saving behavior for sleep and activity.

**Question:** How does TwinTrack prevent duplicate sleep or step totals?

**Answer outline:** Steps use HealthKit cumulative statistics so HealthKit handles contributions from multiple sources. Sleep samples require app-side processing: TwinTrack accepts actual asleep stages, excludes Awake and In Bed, clips samples to the selected window, and calculates the union of overlapping intervals so each instant contributes once.

**Question:** Why can TwinTrack say “No accessible recent value” without saying access was denied?

**Answer outline:** HealthKit intentionally does not reveal read authorization decisions reliably. An empty query can mean there is no data in the selected window or that the app cannot access it. TwinTrack therefore preserves a missing value and avoids claiming a specific denial state.

**Question:** How was HealthKit verified without committing private health records?

**Answer outline:** Synthetic tests verify date windows, units, sleep overlap, missing values, and shared-state concurrency. A separately verified the authorization and query behavior on a physical iPhone by comparing TwinTrack with Apple Health over the displayed intervals. Private evidence exists locally but is not committed, inspected, or copied into development records.

**Evidence:** HealthKit tests passed 22/22, including 7/7 sleep aggregation tests. Manual-input tests passed 7/7, frozen Ridge parity remained 21/21, the tab regression passed, and A confirmed the physical-device results. The private evidence is intentionally excluded from Git.

**A learning status:** Not confirmed by A.

## Prediction History and 7-day trends

**Question:** When does TwinTrack save a prediction snapshot?

**Answer outline:** The verified reliability checkpoint 1 supersedes automatic saving: only explicit Run Prediction validates the current complete baseline, evaluates Ridge, and saves an immutable event. Health refresh, Manual Inputs Save, rendering, tab changes, and What-If do not create real prediction history. Legacy events remain readable with their original identity.

**Question:** How does the seven-day chart handle missing days and several predictions on one day?

**Answer outline:** It builds seven local calendar-day positions, leaves days without real snapshots empty, and uses the latest legitimate snapshot from each day for the chart. Full history retains every legitimate same-day snapshot. Values use one fixed 0–100 scale with no interpolation, averaging, or carry-forward.

**Question:** Can reviewing or clearing history alter current inputs?

**Answer outline:** Opening a chart detail reads the exact immutable snapshot represented by that bar and cannot edit current state or create another prediction. Clear Prediction History removes only history after destructive confirmation; manual inputs, HealthKit state, model configuration, and What-If state remain intact.

**Evidence:** History tests passed 28/28. The complete suite passed 97/97 after the Health refresh and tab-transition corrections.

**A learning status:** Not confirmed by A.

## Refresh-state and tab-transition correction

**Question:** How does refresh avoid blanking Health values or repeating authorization?

**Answer outline:** TwinTrack retains the last committed readings and source window while the four queries run into a local result. After cancellation and stale-generation checks, it commits the window and complete readings together. A persisted setup-completed flag records only that the authorization request was presented; normal launch, foreground, and pull refresh never request authorization again or infer denial from missing data.

**Question:** How was tab ghosting removed?

**Answer outline:** The app keeps the same native three-tab architecture but disables animation on the selection transaction, so only the selected page content is visually active. A physically confirmed smooth switching without overlap or ghosting.

**Evidence:** Xcode build passed; 97/97 automated tests passed with 0 warnings and 0 errors. A physically confirmed refresh function, stable Health values, no repeat access request, persisted manual inputs, and clean transitions. Spinner visibility remains a non-blocking final-polish item.

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

## Checkpoint 2 — local chat library and compact shell

**Question:** Can opening a saved chat restore old health inputs or predictions into the app?

**Answer outline:** No. Saved messages and cards are historical values with no state mutation interface. Opening does not call the model or tools. A new personalized request captures a new snapshot from the one authoritative TwinTrackState.

**Question:** What is stored, and how are failures handled?

**Answer outline:** A versioned local Application Support archive stores visible messages/cards, IDs, titles, dates, and a completion enum. Atomic protected writes and backup exclusion are configured. Raw HealthKit samples, request snapshots, hidden tool transcripts, and debug errors are not archived. Invalid or future-version files are preserved, and failed writes prevent silently abandoning unsaved messages.

**Question:** What happens when a response arrives after New Chat or deletion?

**Answer outline:** A generation token and task cancellation invalidate that response. It cannot appear in the new chat or recreate a deleted record. Interrupted requests reopened after relaunch require an explicit retry with current inputs because their old request snapshot was not persisted.

**Question:** How do chat deletion and Clear Prediction History interact?

**Answer outline:** They are independent. Deleting a chat removes its messages and historical cards only. Clearing Prediction History leaves chats intact. Both destructive actions require their own confirmation.

**Question:** How can the user leave chat while the keyboard is open?

**Answer outline:** The conversation scroll view dismisses the keyboard interactively. A visible Dismiss keyboard action also works with very short content. The composer respects keyboard safe areas; the existing three global tabs remain the only main navigation.

**A learning status:** Not confirmed by A. These are reference answers for later explanation.

**Checkpoint 2 automated evidence:** Final complete Xcode suite 153/153 (15 new library unit tests and two new UI tests), warnings/errors 0. Actual synthetic app relaunch and both New Chat entry points pass. This does not mark A as having learned the code or establish live model response quality.
