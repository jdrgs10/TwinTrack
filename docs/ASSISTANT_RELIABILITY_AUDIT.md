# Assistant reliability audit — 2026-09-24

## Current overnight audit — 2026-10-06

I preserved the pending concise, warmer reply instructions and keyboard-safe composer change. I reviewed canonical recent/saved context, refusal/crisis separation, deterministic numerical routing, BMI consent/fresh reads, cancellation/editing, chat storage/export and privacy. I found one **High** blocker in the existing medical route: a whole-request negation guard made `No chest pain, but I have severe trouble breathing.` non-urgent. The shared output reviewer could then replace correct emergency guidance with general symptom advice.

I now remove only the denied symptom or coordinated denied list before the existing affirmative checks. The existing quote filter, positive red-flag rules and app-owned UAE ambulance response remain intact; urgent routing precedes generation even when the model is unavailable. An initial un-applied draft exposed coordinated-denial false positives during peer review; I corrected those before applying it. Four new synthetic methods cover nine mixed reports, twelve denial-only reports, five quoted examples and twelve unavailable-generation combinations. This is a narrow software correction, not a general or clinically validated triage classifier.

The fresh Xcode results and separated warning counts are recorded in [FINAL_APP_PASS](FINAL_APP_PASS.md) and [EVIDENCE_LOG](EVIDENCE_LOG.md). Live tone, perceived first-tap latency, intermittent physical keyboard overlap and final visual acceptance remain A's checks. The blue Ridge card is restored above the purple Foundation Models card in current Profile; the older September description below is historical. Frozen Ridge V1/V2, HealthKit semantics and prediction/history/What-If state remain unchanged. I did not inspect private evidence or device identifiers, or stage, commit or push.

## Historical September 24 audit

Status: automated validation complete; physical conversational approval remains required. Build marker: `FMQ-2026-09-24-A`. No model retraining or Ridge changes.

## Evidence and confirmed causes

The supplied screenshots were reviewed with A's permission for this private development task. They were not copied into the repository or treated as proof that every failure came from one build/session. No private readings are reproduced here.

The initial synthetic reproduction ran `AssistantSeptemberAuditTests` in Xcode using the existing iPhone 17 Pro simulator, iOS 26.5, scheme `TwinTrack Serial`. The 23:08:48 result failed 3/3 methods: calculation was classified as methodology, the conditional score request failed to reach What-If, and an accepted offer could be offered again. After the first narrow fixes, the 23:15:49 run passed 3/3. Expanded tests at 23:23:43 passed 14/14. These use injected text-generation responses and synthetic data, not physical Foundation Models quality measurements.

1. `AssistantResponsePolicy.isModelQuestion` matched `score` plus `calculat` before operational routing. That intercepted "Calculate my score" and its conditional variant. The old `.current` route only read a result; it did not execute `TwinTrackState.runPrediction()`.
2. Scenario parsing required a named feature in every turn. A short relative correction had no persisted, validated antecedent and fell into conversation. The pending scenario now records only a feature identifier and a SHA-256 identity of the captured baseline/context. Its identity includes assessment/source metadata and the prior run, not chat text. Reopening preserves that optional metadata without injecting it into model instructions. Changed baselines and new chats cannot inherit it.
3. Context serialization already used role-separated bounded exchanges and one latest user message, but did not distinguish accepting an offer from asking for more. The existing repetition reviewer caught identical/high-overlap text, not a reworded offer. Conversation relation now makes acceptance/decline/uncertainty/elaboration explicit, using the same canonical history. One bounded quality repair can fulfil an accepted offer; another offer after repair produces an honest retryable failure, not a loop or fabricated advice.
4. Send previously did synchronous availability/persistence work before returning to the composer and left focus active. Send now accepts once, appends the user, enters pending state, returns so the composer can clear/dismiss, then yields before persistence/generation. Generation counters continue rejecting cancelled, deleted, edited or cross-chat callbacks. This proves the synchronous work existed; it does **not** establish a physical first-tap latency cause. Existing tap/focus/keyboard/session timings remain available for A's device check.
5. What-If display used two-decimal formatting for durations and steps, while a narrow numeric control could wrap. Display now reuses whole-minute/grouped-number Home formatters and preserves numeric intrinsic width. The editor, stored values, bounds, arithmetic and Ridge retain full precision.
6. BMI was deliberately excluded before this task. Its access is a new consent-controlled local operation, not a corrected model refusal.

## Response path and guardrail inventory

Locations below refer to `ios/twintrack/twintrack/`. No Apple safeguard is disabled. No typed safety rejection is retried to obtain blocked content.

| Rule / location | Purpose and phase | Can block or replace | Must allow / negative case | Decision and evidence |
|---|---|---|---|---|
| Intent: `AssistantRouting.swift`, `AssistantRouter.route` | Before model invocation; distinguish reads, calculation, scenarios, methodology, BMI and conversation | Select deterministic tools or targeted clarification | Calculate score / ambiguous increment without antecedent | **Narrow** methodology interception; add explicit calculation and context-bound continuation. Reproduced failures above. |
| Methodology: `FoundationAssistantService.swift`, `isModelQuestion` / `modelExplanation` | Scientific disclosure for actual model questions | Training/reliability explanation | How is score calculated? / claim of guaranteed accuracy | **Narrow** substring trigger to question/formula/training intent; preserve limitations. |
| Prediction grounding: `AssistantTools.swift`, `AssistantResponsePolicy.answer` | Swift cards own numbers; generation cannot supply app measurements | Unsupported personal predictions, invented readings | Read existing estimate / model invents 95 | **Keep**. App-owned `calculate` calls the existing shared action and checks the captured state has not changed. |
| Missing/stale inputs: `AssistantSnapshot`, `AssistantToolRun`, shared state | Before numerical work | Missing, invalid, stale source/assessment states | Complete fresh baseline / missing sleep | **Keep**. Reads never create runs; equivalent calculation reuse remains shared-state behavior. |
| What-If: `AssistantScenarioParser`, `validatedChanges`, `WhatIfScenario` | Parse original user evidence, units, operation; validate resulting totals | Unknown units, unsupported time window, out-of-domain totals | Study90 +4h =330 / +5h =390, +20h invalid | **Keep bounds, extend context**. No clamping or new inputs; one-step corrections are anchored to the same baseline. |
| Identity: `AssistantReplyReview.removingProviderIntroduction` | After generation | False provider introduction clause | Normal greeting with stray provider prefix / identity-only leakage | **Keep** narrow removal; identity is not a safety verdict. |
| Textual refusal: `AssistantConversationReview`, `AssistantResponsePolicy.answer` | Review text with canonical preceding exchange | Generic follow-up refusal can receive one same-safeguard quality repair; real refused context gets concise boundary explanation | Benign How? / return to refused harmful task | **Keep**. A textual refusal is distinct from a typed framework error. |
| Typed framework failure: `FoundationModelRuntime.swift`, `AssistantFailure.classify` | Generation boundary, typed categories only | Safety, context budget, busy, assets, language, decoding, tool failure | Context-budget recovery / guardrail violation | **Keep**. One context-size recovery only; no raw error/transcript logging. |
| Crisis: `AssistantContext.isImmediateMentalHealthCrisis`, service pre-route / `safetyFallback` | Current credible first-person intent before model; typed-safety fallback rechecks original request | App-owned crisis guidance, never ordinary disagreement | Help me stay safe / bad day is not crisis; harmful instruction remains refused | **Keep and narrowly extend** credible help-seeking clauses. Active context stops at an independent safe topic; short acknowledgement alone does not erase risk. |
| Emergency resources: service / `AssistantGuidance` | User-supported urgent guidance | Immediate medical emergency guidance | Severe current breathing difficulty / hypothetical general physiology | **Keep conditional geography**. UAE998 ambulance,999 police verified against official UAE portal; elsewhere local emergency services, no location question before help. |
| Health/age: `AssistantGuidance`, `AssistantReplyReview` | Relevant guidance and display review | Invented age, unsupported personal duration, medication/diagnosis/current-weather certainty | Age-appropriate attributed advice / invented age or personal prescription | **Keep**. No profile DOB is silently used as prompt context. |
| Repetition/verbosity: `AssistantConversationReview`, core instructions | One bounded same-history repair | Repeated explanation, invented experience, unsupported conditions, re-offer after acceptance | Helpful requested detail / repeated offer | **Extend** accepted-offer check; retain concise defaults, do not truncate safety or legitimate detailed replies. |
| Context/session: `AssistantContext.prompt`, `FoundationTextClient.reply` | Last3 exchanges within budget, latest request once; fresh text-only model session | Duplicate/stale hidden history, tool-card data in prompt | Saved chat follow-up / quoted instruction injection | **Keep** one canonical archive. Fresh sessions avoid hidden session divergence; bounded reconstruction preserves nearest complete exchange. |
| Cancellation: `AssistantConversation.start/cancel/open/delete/saveEdit` | Before/after async boundary | Late or wrong-branch replies | Retry edited request / deleted chat receives late output | **Keep** generation guard; defer initial file IO until accepted send returns. |
| Persistence/export: `ConversationLibrary.swift`, `ChatExport.swift` | Local storage / explicit share | Unsupported archive version; export internals | Reopen/edit/export visible cards / hidden traces or source IDs | **Keep** atomic protected writes, backup exclusion and explicit export projection. Optional scenario metadata is backward-compatible; no duplicate transcript. |
| BMI: `BodyWellbeing.swift`, `assistantSummary`, Profile toggle | Fresh store read on every relevant request | Missing/denied/revoked/unreadable summary | Authorized derived result / raw DOB/full profile request | **Add narrow operation**. Default-off consent; existing CDC calculation reused; no Foundation Models call or state mutation. |
| Diagnostic trace: `AssistantAuditTrace.swift` | In-memory per response | No logging or persistence | Synthetic route/tool/review diagnosis / private prompt capture | **Add categorical trace**: route, attempted tools, card validation kind, replacement reasons, typed failure and byte counts only. |

## Storage and privacy

Chats remain under Application Support / TwinTrackConversations, with atomic complete-file-protection writes and backup exclusion. Only visible messages/cards and optional scenario binding metadata are stored, not raw Health samples, request snapshots, tool transcripts or debug errors. BMI stays in its separate protected local store. Schema3 reads older versions1/2; absent consent is off, absent saved date is explicitly unknown. Permission changes do not manufacture measurement dates. Consent revocation/removal is reflected by an existing chat's next request. Old shared cards/exports are not retroactively erased; existing delete/share controls remain explicit.

General Foundation Models generation uses the existing text-only runtime, no tool schema, bounded role-labelled history and relevant guidance. New BMI cards are app-owned and not serialized into model context. The core instructions remain small; synthetic traces expose byte counts rather than prompt text. No new framework/OS APIs or backend were introduced.

## Trends and compact UI

Profile → Wellbeing → Trends & History reuses prediction history. Seven/thirty local-calendar-day lists display actual captured habit/health observations and explicit gaps. Manual values use their recorded source day; Health values use their source interval/sample timestamp, not the time a prediction happened to be saved. Repeated periods collapse to their latest recorded value. Legacy undated manual data is omitted, not assigned a date. Period aggregates are labelled and never turned into independent daily values. Model estimates remain individually labelled by assessment/version with no merged improvement curve. Latest-only BMI storage is not presented as body history. No new store or interpolation is introduced.

Home retains assessment, score and short experimental label; technical version, exact timestamp and source periods are in the existing Details screen. "Saved estimate · Inputs match/updated" replaces technical run wording. Profile's existing About → Model Information keeps model detail without the duplicate prominent Ridge card. Chat distinguishes a result captured for this request from a saved result.

## Validation and physical limits

Final run results will be recorded in EVIDENCE_LOG.md. The initial broad unit run at23:29:58 passed410/411. The only failing test expected all sends to be discarded while the model was unavailable; it was superseded with stricter assertions that the accepted general request remains retryable, the unavailable generator is never invoked, and local calculation reports its own missing-input state independently. The historical What-If formatter expectation "2h0m" now expects the shared Home formatter's "2h"; numerical precision assertions remain.

Required physical review: fresh chats for calculation/methodology separation, +5h invalid→+4h valid→+20h invalid with a90-minute synthetic baseline; accepted advice offers and unseen paraphrases; refusal→safe topic→refused-task return; help-seeking vs ordinary stress; send clear/keyboard and newer-draft preservation; first-tap timing; BMI consent/revoke/removal and old cards; Home Details, What-If whole-value layout and Trends gaps on iPhone/iPad, Light/Dark and large text. Automated injected-response tests do not establish physical model quality or visual approval.

Official emergency references checked2026-09-24: [UAE handling emergencies](https://u.ae/en/information-and-services/justice-safety-and-the-law/handling-emergencies) and [UAE emergency help](https://u.ae/en/information-and-services/visiting-and-exploring-the-uae/emergency-help-for-tourists-in-the-uae). No new clinical thresholds or diagnosis logic.

Validation environment: Xcode26.6 (17F113), existing iPhone17Pro simulator on iOS26.5; deployment target remains26.5, Swift language mode5. General generation retains `SystemLanguageModel.default` and `maximumResponseTokens: 450`, fresh text-only sessions and existing availability checks. Simulator tests inject controlled text responses; they do not certify Apple Intelligence availability on A's iPhone.

Final diff review added two history safeguards: study observations retain the selected subject in their identity and displayed source label; modern RHR values with no recorded sample date are omitted rather than labelled as a legacy daily average. Legacy averages remain labelled as period aggregates. The diagnostic review path also records the actual policy replacement category (for example ungrounded personal number, leaked instructions or unsupported sleep guidance), without saving user text or health values.

Intermediate complete run (23:32:39): **433/437 passed,4 UI failures**. All411 unit methods passed. UI failures: stale build-marker expectation; interactive keyboard drag after refocus; Trends range control below the largest-text viewport; V2 version expectation still looking on Home instead of the newly required Details destination. The build-marker and Details assertions were updated to the intended interface, the range traversal now scrolls to the control, and the drag test waits for keyboard entry before performing the same dismissal assertion. No failure is removed from this record. The result also contains one grouped debugger-code9 warning and the existing BMI height-field `Invalid frame dimension (negative or non-finite)` runtime notice. These are separate from compiler warnings. This intermediate run predates the final subject-isolation/review-trace changes and is not a final-source pass.

Focused UI follow-up: keyboard/library test at23:53:12 **1/1 PASS** after keyboard-readiness correction; Trends Light/Dark/largest-text/bottom-reachability test at23:56:16 **1/1 PASS** after scrolling to the range picker. The same required assertions remain. The Home summary additionally withholds a delta across different recorded subjects/assessments, extending its existing mixed-model-version protection. Final complete-source results follow in the evidence log.

## Files changed in this pass

Under `ios/twintrack/twintrack/`:
- `AssistantAuditTrace.swift` (new)
- `AssistantConversation.swift`
- `AssistantGuidance.swift`
- `AssistantProvenance.swift`
- `AssistantReplyReview.swift`
- `AssistantRouting.swift`
- `AssistantTools.swift`
- `BodyWellbeing.swift` (extends the pre-existing uncommitted wellbeing implementation)
- `BodyWellbeingView.swift` (same)
- `FoundationAssistantService.swift`
- `HomeView.swift`
- `PredictionTrendView.swift`
- `ProfileView.swift` (preserves earlier wellbeing changes)
- `TwinTrackAIView.swift`
- `WellbeingTrendsView.swift` (new)
- `WhatIfView.swift`

Under `ios/twintrack/twintrackTests/`: `AssistantSeptemberAuditTests.swift` (new), `AssistantTests.swift`, `BodyWellbeingTests.swift`, `WellbeingHistoryTests.swift` (new), `WhatIfScenarioTests.swift`.

UI tests: `ios/twintrack/twintrackUITests/twintrackUITests.swift`.

Documentation: this file, `docs/EVIDENCE_LOG.md`, and ignored local-only `.twintrack-local/TWINTRACK_MASTER_HANDOFF.md`.

The earlier `docs/UI_FREEZE.md` changes and public `CDCReferences/bmi-age-2022.csv` are preserved without changes in this pass. Existing `.DS_Store` and `xcuserdata` dirt remain outside the proposed source scope; do not include them when selecting changes for a future commit. Nothing is staged, committed or pushed. Test result bundles stay in Xcode DerivedData, outside the repository.


Final results: complete iPhone440/440 (414 unit +26 UI), V1 parity21/21, V2 parity176/176, Build PASS, Analyze PASS,0 compiler/analyzer warnings/errors. Targeted iPad2/2 across successful runs; the first30-day selector attempt failed and an unchanged rerun passed. The debugger-code9 and pre-existing BMI frame runtime notices remain. See the September24–25 evidence-log entry for exact result names/times, qualification and remaining physical checks. No staging, commit or push.
