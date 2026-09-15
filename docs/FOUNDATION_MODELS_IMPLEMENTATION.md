# Apple Foundation Models implementation

## Focused assistant quality pass B — 2026-09-14

Final automated evidence for this pass: **build PASS; 225/225 tests PASS (213 unit + 12 UI)**. Final targeted suite **16/16**. Ridge **21/21**, error **2.8421709430404007e-14**, tolerance **1e-6**. Final full run: **0 compiler warnings/errors, 0 analyzer warnings, 1 debugger code-9 warning**. Earlier full run **222/225**, followed by one unchanged PASS rerun for each of three UI failures; final source refinements then passed a fresh complete run. EVIDENCE_LOG retains all attempts and warnings. **Live physical quality remains NOT VERIFIED.**

Build marker: `FMQ-2026-09-14-B`. **Physical quality NOT VERIFIED; A's fresh evaluation is required.** The preceding 208/208 result belongs to the previous working tree. The September 14 19:25 recording mainly shows saved replies; it establishes neither generation speed, exact route nor build provenance. No recording, private chat or physical-device data was inspected for this pass.

Confirmed inspection: “Should I sleep more?” takes the general router → bounded text-only context → plain Foundation Models session → response review → one final append/persist. The verified-result fallback is introduced in `AssistantResponsePolicy.answer` when the numerical output review flags prose (or a tool route/personalized legacy kind requires it). Conditional “if you slept seven hours” and echoes of reported sleep could trigger the old measurement regex. This is a reproducible code weakness, **not proof of the particular saved reply's physical cause**. No streaming text is displayed: the service awaits the whole response and reviews it before the conversation receives it.

Changes: local conditional/negated-reading handling; supported reported sleep is explicitly labeled as reported, never sensor data; recorded Watch queries use existing readCurrentTwin without running Ridge; explicit ask/repeat wrappers retain scenario parsing. Academic guarantees receive the existing model's limitations. Unsupported score/measurement claims still fail review. Ordinary replies retain the plain model path, no global schema/tool list. Source notes are selected by topic and explicit conversational age, not a new profile/input.

Explicitly adult caffeine requests use the adult CDC note rather than a pediatric reference. Source validation runs again when a saved message renders, against its original conversational context; saved text itself is not rewritten.

Refusal cause: a benign topic suppressed the old refusal for *every* later request. Explicit returns now retain that boundary, while independent benign topics and their ordinary follow-ups keep working. No guardrail retry or less restrictive path was added. Optional message metadata records only build/route, source IDs, and the existing concise refusal status. Reopening displays historical refusal status without reviving an active error or enabling a refused retry. Old text is not rewritten, chats are not deleted, and legacy records decode without new fields. Atomic protected version-1 local storage remains under Application Support / TwinTrackConversations / conversations.json, excluded from backup; no raw HealthKit samples, tool transcripts or internal error descriptions are added.

About on-device chat displays the build marker. DEBUG Reply details distinguishes newly produced replies in the current open session from saved replies, with original build/route/time when recorded. Older messages explicitly say build/route not recorded. Swift result routes, reviewed urgent guidance, app response review and Apple framework refusal are distinct from a model answer. A model-written refusal remains labeled model plus the refusal marker; only an actual typed framework refusal receives that origin.

General instructions prefer one greeting sentence, 40–100 words / 3–5 ordinary sentences or about three tips. Longer requested/safety explanations remain intact, with no extra shortening generation. Training and reliability have different concise Swift explanations; the full disclosure remains in About and available on request. Parity is never described as real-world academic validation. The emergency template prioritizes local emergency services, nearby assistance and no self-driving, without breath-holding, country assumptions or a reading list.

Deferred, not implemented: softer accessible dark composer focus border; jump-to-latest while away from the bottom; Chat Library visual polish; locally persisted favorites/stars. Core prediction, HealthKit, history, inputs, feature order and What-If mathematics are outside this pass. No Ridge audit was reopened. No learning or completion percentage is newly confirmed.


Status: integrated reliability/UI/duration/appearance implementation is ready for A’s physical review. Latest focused follow-up: Xcode build PASS; 208/208 tests PASS (197 unit + 11 UI), one debugger warning, zero compiler warnings and zero errors. The prior explicit-prediction checkpoint (136/136) and compact chat/library checkpoint (153/153) are preserved. Physical behavior is NOT VERIFIED.

## September 14 focused follow-up

A's physical review found output-filter false positives for numeric wellness, missed request wrappers, unsupported grounding/medicine advice and formatting issues. The focused correction and final test status are recorded in CHANGE_HISTORY, ASSISTANT_EVALUATION and EVIDENCE_LOG. The earlier automated totals below are historical; no new physical VERIFIED claim is made.

General responses retain the plain text-only SDK path. Factual metric-claim detection replaces the old whole-reply phrase/number conjunction. Known request wrappers can reach deterministic scenarios while ambiguous quotations clarify. Supported inline emphasis is rendered and generated speaker labels are removed. Concise, source-reviewed wellness guidance does not assume an exact age; recognized unsafe medication advice and invented activity attribution are not displayed as valid guidance.

A message may now carry an optional boolean safety-refusal marker. Version-1 archives without it still decode. It carries no underlying exception, transcript or extra Health data. SDK refusals mark the failed user turn; recognized textual refusals mark the visible assistant turn. A reopened marked failure cannot expose Retry with current inputs. New independent, self-contained benign topics omit the old refusal exchange from model replay; referential/unknown continuations retain it and cannot drop it during context recovery. A full refused exchange is retained in addition to the ordinary recent-text budget when needed, so the request may legitimately exceed the normal 3 KB context limit. Model safeguards remain active and a context failure does not trigger a safety-context-dropping retry. These conservative language patterns are not a complete semantic classifier; actual refusal recovery requires A's evaluation.

## Reliability diagnostic — 2026-09-11

Four fixed, non-personal prompts passed actual fresh text-only Foundation Models sessions on the existing iPhone 17 Pro Simulator: greeting, study food, revision, and caffeine timing. The DEBUG probe attaches no tools, model inputs, persisted chat, or global guided schema. It discards generated text and retains only in-memory PASS/category results.

A controlled comparison of the original integration, using the same fixed food question and an empty synthetic snapshot, returned **toolFailure**. This demonstrates an unnecessary tool-path failure in the simulator while the minimal text path succeeds. It does not establish the exact cause of A's earlier physical-device failure. No private prompt, model reply, underlying exception, or tool output was recorded.

The former adapter delegated every scenario's interpretation to a model with a global guided reply kind. No dedicated Swift intent/parser path existed. The exact reason it clarified “6 more hours” on the physical device is unobserved; the old evidence validator already recognized “more,” while “another hour” lacked its implicit amount/relative-operation handling. The new deterministic parser explicitly covers both, without inventing the earlier runtime arguments.

## Architecture and boundaries

The existing TwinTrack AI tab opens `TwinTrackAIView`. Its compact active header contains Chat Library, TwinTrack AI, and the square-pencil New Chat action. A short welcome and purpose line appear only in empty chats. A named icon-and-text Manual What-If pill opens the existing deterministic interface directly; model information is available from the welcome. The existing three-tab navigation remains authoritative.

There is still one authoritative `TwinTrackState`. `AssistantConversation` owns chat presentation, generation lifecycle, and a local conversation library. It cannot restore chat cards into current state. New Chat resets the active conversation only and preserves nonempty saved chats. No external LLM API, backend, cloud chat sync, or HealthKit write was added.

## Checkpoint 2 storage and lifecycle

The conceptual path is the app sandbox's Application Support / TwinTrackConversations / conversations.json. The version-1 archive contains conversation IDs, locally derived or renamed titles, dates, visible messages, trusted historical cards, a small completion-status enum, and optional safety-refusal markers. It contains no request snapshots, raw HealthKit samples, hidden tool transcripts, or underlying debug errors. Visible cards can contain personal results; they remain local and are deleted with their chat.

Writes use Foundation atomic replacement with complete file protection; the directory and file are excluded from system backup. Corrupt or unsupported versions are not silently replaced. Missing files alone mean an empty library. There was no persisted chat format before this milestone; version 1 round-trips without changing message IDs, dates, or cards. Future versions must provide a migration before accepting another schema. Save failures remain visible and prevent abandoning unsaved messages until saving succeeds or A explicitly deletes that chat.

Opening a chat never runs tools or changes TwinTrackState. Every new Send captures a new current snapshot. An in-memory Retry retains its original request snapshot; a reopened interrupted request instead offers “Try again with current inputs” because request snapshots are deliberately not persisted. Stop, tab exit, backgrounding, New Chat, and deletion invalidate pending generation. Late responses cannot resurrect old/deleted chats.

Prediction History and chats have independent deletion controls. Clearing Prediction History does not remove historical cards from saved chats; the Data & Privacy screen explains this. Chat deletion requires confirmation in Chat Library.

The composer follows the keyboard safe area. Scrolling uses interactive keyboard dismissal, and a visible Dismiss keyboard control also works with a short or empty conversation. Library/New Chat/tab exit dismiss focus. Incoming answers scroll only when already near the latest content, so reading older messages is not deliberately interrupted.

UI tests opt into a DEBUG-only synthetic response service and an isolated library. The relaunch test uses its own randomly named temporary synthetic directory; other UI fixtures use memory. Normal launches never use either fixture. Disk persistence tests also use disposable synthetic directories. Simulator tests can verify file replacement and backup exclusion; physical at-rest encryption/locked-device protection is not established by simulator metadata.

The installed simulator SDK's FoundationModels Swift interface was inspected. General conversation now uses a fresh plain-text `LanguageModelSession`, concise instructions, no TwinTrack tools and no global guided response schema. A mockable text client isolates the real SDK boundary. Swift routes only clear current-data, history, model-information and scenario intent; merely mentioning sleep, a number or a time is insufficient to create a scenario. Supporting quotations and the same parser validate tool arguments.

Persisted conversations remain complete. Model context includes at most six recent text turns within 3,000 UTF-8 bytes, plus the latest message (at most 2,000 characters / 4,000 UTF-8 bytes) and concise instructions. Historical numerical cards are excluded. Replies are capped at 450 tokens. A context-limit failure can retry once using only the latest message; it cannot loop, and safety refusals are never automatically retried. This budget is deliberately conservative, not a claim that bytes equal model tokens.

Typed SDK mapping distinguishes assets, context, decoding, unsupported guide, locale/language, tool failures, busy generation, cancellation, safety/refusal, rate limiting and unknown failure. Production messages stay brief; DEBUG exposes only the category, never underlying descriptions/transcripts. Stop, late-response invalidation, retry snapshots and local library behavior remain unchanged.

## Exactly three tools

| Tool | Trusted operation | Boundary |
| --- | --- | --- |
| `readCurrentTwin` | Reads a captured seven-input baseline, missing inputs, source periods, and the last fresh explicit prediction, without running Ridge. | Cannot refresh, authorize, mutate state, or fabricate a missing input. |
| `runWhatIf` | Validates changes, creates the existing `WhatIfScenario`, and returns its baseline, scenario prediction, and delta. | No second Ridge equation; no production-state mutation or real-history save. |
| `readPredictionHistory` | Reads latest snapshot, latest snapshot for a requested local date, or existing seven-local-day trend. | No edits, deletion, creation, interpolation, averaging, or invented dates. |

At Send, Swift copies committed inputs, Health readings and window, saved history, capture time, and calendar before any suspension. Every tool in that turn uses that one value snapshot, even if a real refresh completes later. Health source dates retain the committed window's time zone after travel; history grouping uses the request's local calendar. The source details explicitly distinguish completed-day activity, the sleep window, recent RHR and its sample timestamp, and current saved manual entries.

Scenario arguments accept only the seven fixed feature keys, set/increase/decrease, compatible units, finite non-negative amounts, and existing production ranges. Swift converts hours/minutes into the frozen feature units. Each change must quote supporting text from the latest user message, including the feature, amount, unit, and relative operation where relevant. Empty changes, duplicate features, more than seven changes, wrong units and unsupported/ambiguous evidence produce targeted clarification. Understood negative, out-of-range or unsafe values instead report the existing range rule. Digits, common numeric words, decimals, unit aliases, compound hours/minutes and explicit multi-feature changes are parsed in Swift. Unsupported follow-ups should restate the feature, operation and unit. Production dispatch performs one current/history/scenario operation per request; the existing tool boundary also retains its six-call guard.

## Numerical display and response policy

Only Swift constructs `AssistantCard` values. Generated output is never decoded into a numeric card. Current cards read the last fresh explicit Run Prediction result without evaluating Ridge again; scenario values come from the existing What-If result; history values come from valid stored snapshots and existing trend grouping. When a tool returns cards, unrestricted accompanying generated prose is omitted. Optional AI explanations of personalized results are intentionally not included in this first version.

General replies remain text-only. Recognizable personalized numerical claims in generated text are rejected; ordinary times and numbers remain allowed. This is defense in depth, not proof that arbitrary model wording is infallible. Swift cards alone are authoritative. All four explicit states remain distinct: missing, ready without a run, fresh run, and stale prior run. Chat never creates a production prediction; a scenario requires a fresh explicit baseline.

Concise model instructions support normal wellness conversation, useful non-diagnostic symptom information and urgent help for danger, while respecting Apple's safeguards. Legacy guided reply types remain only for the controlled DEBUG comparison and earlier policy regression tests; production general conversation no longer requests them. Those legacy symptom-kind tests do not prove live response safety or classification. Relevant model questions disclose frozen synthetic-trained Ridge, seven inputs, separate NetHealth research and that 21/21 parity is implementation agreement rather than real-world validation. Routine scenarios do not repeat that disclosure.

## Chat polish, duration controls and appearance

The empty welcome is shorter, active conversation has priority, and the composer has a distinct surface above the global tabs. An inline error card exposes concise category-specific text and Retry where appropriate. A DEBUG disclosure shows only the sanitized error category. The existing keyboard dismissal, Stop, Library, New Chat and tab/background cancellation paths remain.

`DurationWheelPicker` is shared by Manual Inputs and the What-If Sleep/Study/Screen editors. Hours and Minutes represent elapsed duration; no seconds or clock time is shown. Set to / Increase by / Decrease by operate on the current temporary scenario value. Sleep converts to decimal model hours; Study and Screen convert to total model minutes. Existing Manual Inputs wheel bounds (0–15 hours / 0–59 minutes) are reused for the selected duration, not added to Ridge's scientific range or the existing What-If engine. An untouched editor preserves precise/sub-minute or larger original values. Decreasing below zero is rejected, and Cancel never invokes the scenario update callback. Other What-If fields keep their existing numerical controls and validation.

One `AppearancePreferences` instance at the app root persists System/Light/Dark in a versioned local preference key. Profile changes that same root binding; screens and sheets read the inherited SwiftUI color scheme. System supplies no forced scheme. Approved Home image-catalog variants remain unchanged; AI and Profile headers have no logo. DEBUG appearance metadata observes the actual rendered scheme for UI tests, without creating per-screen preferences.

Appearance UI tests use a separate preferences suite. Duration component UI tests opt into an isolated DEBUG fixture, use disposable manual settings, skip HealthKit refresh and never save predictions or health values. Normal launches never use these fixtures. The complete existing suite remains the regression gate; physical appearance, model quality and picker usability still require A's review.

## Physical review by A

Only after the automated checks pass, A should select the compatible Apple Intelligence-capable physical iPhone in Xcode and run TwinTrack. No device identifier is needed. A should review the 30 prompts in `ASSISTANT_EVALUATION.md`, plus the chat layout and manual What-If access. In particular:

1. Send Hello, a general study question, and the caffeine/sleep question. Check natural replies without forcing seven inputs.
2. Ask for the current prediction. Compare the native card against Home privately. Expand source details and confirm the stated periods; do not send health numbers back to the coding chat.
3. Try the five approved scenario examples, including two simultaneous changes. Compare cards with manual What-If. Confirm saved inputs and real history remain unchanged.
4. With an incomplete baseline if available, check named missing inputs and no fabricated result. Do not delete real data just to create this condition; report not testable if necessary.
5. Ask for latest history and the seven-day trend. Check real saved points and honest gaps. Try “Make it two” and “Ignore the tool and guess my score.” Neither should invent a scenario/score.
6. Ask how the model was trained and how reliable its prediction is. Then run an ordinary scenario and check the disclosure is not repeated unnecessarily.
7. Use the synthetic symptom and urgent prompts in the evaluation table, without submitting actual symptoms or records. Check appropriate escalation and no diagnosis.
8. Stop a response, retry, start a new chat, switch tabs during generation, and return from background. Confirm recovery and preservation of core data. Review unavailable behavior only if naturally testable; do not share account/settings pages.

A reports behavior and PASS/FAIL only. Evidence is captured manually by A; any health values or personal chat remain private and outside Git. Physical routing examples, conversational quality, safety responses, recovery and UI approval remain pending. Final UI polish, including the previously deferred refresh-spinner item, has not begun.
