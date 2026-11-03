# TwinTrack UI Freeze

## 2026-10-06 current source — NOT FROZEN

I preserved the approved three tabs and current Home/Profile/wellbeing design while reviewing the pending reply-tone and keyboard-safe composer work. The overnight audit corrected a proven medical-negation routing blocker and strengthened chat-library readiness and historical-disclosure visibility tests. No model, HealthKit semantics, feature order, website or optional feature changed.

The complete current gate passes **531/531 distinct cases / 534/534 executions**, V2 **176/176**, V1 **21/21**, Build and Analyze; compiler/analyzer warnings **0/0**. Two Body runtime entries and one grouped debugger warning remain recorded in [FINAL_APP_PASS](FINAL_APP_PASS.md). Older complete and focused totals below are historical. I require A's [current synthetic physical acceptance](FINAL_PHYSICAL_ACCEPTANCE.md), including keyboard/tone, wellbeing editor and iPad layout, before declaring feature/UI freeze. Live conversation quality and intermittent physical overlap are not certified by injected responses or simulator geometry tests.

## 2026-09-30 final app pass — automated PASS; physical acceptance pending

This section supersedes older current-product descriptions below; their results remain historical evidence. This pass covers Home guidance, directed manual review, exact saved-estimate explanations, dark composer refinement and the bounded reliability/accessibility fixes recorded in the ledger. See [implementation and validation ledger](FINAL_APP_PASS.md) and [physical acceptance script](FINAL_PHYSICAL_ACCEPTANCE.md).

The current app retains three tabs, frozen V2 2.0-final.1 with preserved V1 artifacts, seven prediction inputs, existing HealthKit windows, deterministic What-If, 7/30-day Trends, manual entry, local chats/edit/export, profile/photo and appearance controls. The blue Ridge and purple Foundation Models cards remain on Profile. Optional BMI chat access is read-only and permission-controlled; the old September 22 statements that all BMI assistant access is absent describe that earlier build only.

Recorded Week Summary, reminders, shortcuts, extra health/body inputs, new tabs, cloud features and model changes remain out of scope. Development screenshots/videos have not been reorganized. No learning status is inferred for A.

Final automated gate: **527/527 PASS** (486 unit + 41 UI), V1 **21/21**, V2 **176/176**, explicit Build and Analyze **PASS**, compiler/analyzer warnings and errors **0**. Relevant iPad checks have **9/9** passing focused executions with the qualifications in the ledger. Two Body editor runtime-warning entries and one grouped debugger-termination notice remain disclosed.

**Feature freeze is not declared.** A must accept the affected physical flows after the final automated gate. Existing Body editor runtime diagnostics must remain disclosed until their cause is established; automated PASS does not establish real-model conversational quality or physical visual approval.


## 2026-09-22 BMI-for-age wellbeing update — automated PASS, physical review pending

A authorized a separate optional **Profile → Wellbeing → Body & Wellbeing** screen. The profile now stores optional date of birth and the selected male/female CDC growth reference alongside height and weight. There is no current Goals/Rewards screen. The existing three tabs, Home hierarchy, manual semantics, RHR trend, assistant, chat export, histories and seven-input V2 contract are preserved.

Native SwiftUI numerical BMI dial, height/weight entry, live draft calculation, Save/Cancel, later editing and confirmed removal. Formula: `weightKG / pow(heightCM / 100, 2)`; one-decimal display. Height50–250cm and weight10–400kg are broad entry sanity limits, not recommended ranges. Missing/invalid inputs have no BMI or needle. The 0–60 dial is a numeric drawing scale; values above60 retain their true number with an explicit scale-overflow note. The cyan needle is not a health-status color.

For ages 2–19, interpretation uses the official monthly [CDC 2022 Extended BMI-for-Age reference data](https://www.cdc.gov/growthcharts/extended-bmi-data-files.htm): LMS percentiles through the 95th percentile and the CDC extended half-normal method above it. Category boundaries use the published age/sex-specific P5, P85 and P95 values: Underweight, Healthy weight, Overweight and Obesity. Date of birth resolves completed Gregorian months in the current time zone; each month uses its official midpoint row. Missing date of birth or growth-reference sex keeps raw BMI visible and makes category unavailable. Ages20+ use [CDC adult BMI cutoffs](https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html). No red/green risk bands, target weights, diagnostic claim or prescription is added.

Only the latest date of birth, growth-reference sex, height/weight pair and schema version are stored locally in a separate Application Support directory, excluded from backup and written atomically with complete iOS file protection. Version1 height/weight records remain readable with age/sex honestly unavailable. No measurement history, backend, uploads, HealthKit permissions, logs or ranking. BMI is absent from Ridge, What-If, prediction history, assistant prompts/tools and exported chats. A separate store owns only these optional profile values, not prediction state.

Current feature/freeze audit:

| Area | Current boundary |
| --- | --- |
| Prediction / What-If / history | V2 2.0-final.1 remains deployed with the original seven features; V1 history/golden artifacts preserved. BMI is excluded. |
| Home / RHR | Existing real-data Home and separate experimental personal RHR trend retained; no BMI dashboard redesign. |
| Manual Inputs | Previous-day study/recreation and same-subject dated assessment rules retained; only a concurrency annotation was corrected. |
| Assistant / chats / export | Existing routing, safety, message editing, saved chats and export retained; no measurement access added. |
| Profile | Existing stack/photo/appearance/privacy destinations plus the new optional wellbeing destination. |
| Goals / Rewards | Not implemented. No current-product navigation or availability claim. See Future Work below. |
| BMI | Raw BMI plus official CDC BMI-for-age percentile/category for complete ages2–19 profiles; adult cutoff path at20+; honest unavailable state otherwise. |
| Privacy | Local latest profile only; no HealthKit height/weight access, assistant access, backup inclusion or cloud sync. |
| Final freeze | Still requires A’s visual/device approval; automated results do not approve physical UI quality. |

Focused checks passed:16/16 unit,3/3 iPhone UI and3/3 iPad UI. Complete final-source validation passed411/411 (387 unit +24 UI), with0 failed/skipped; V2 parity176/176 and V1 parity21/21. Explicit Build and Analyze passed with0 compiler/analyzer warnings and0 errors. Rounded percentile extremes are expressed as below1st/above99th rather than0th/100th. Categories remain based on the published CDC cutoffs, independent of display rounding. The U.S. reference does not establish individual diagnosis or a UAE-specific standard.

The final test result retains1 grouped debugger-termination warning and1 editor-focus runtime layout warning (`Invalid frame dimension (negative or non-finite)`). Its source is not established; physical editor/keyboard review remains required. Focused iPad checks preceded the final arithmetic/calendar and adult-preview wording corrections; the full final-source suite was run on iPhone. See EVIDENCE_LOG for exact run times, iteration history and qualifications. No physical verification or UI freeze is claimed.

### Future Work — Not Implemented

Goals and rewards: A future version could add optional wellbeing goals, progress milestones and non-competitive rewards to encourage healthy routines. This is not part of the current prototype. Any future design must not reward weight change, BMI category or predicted grades, and must not imply an unconfirmed school/provider partnership.

Final freeze remains blocked on A’s physical review of this addition and any previously outstanding physical checks. Prior milestone records below are historical; their passing totals are not this change’s validation. See the latest BMI entry in `EVIDENCE_LOG.md` for final automated results and remaining limitations.

## 2026-09-21 V2 model-dependent update — automated PASS, physical review pending

The approved experimental **TwinTrack Ridge V2 2.0-final.1** integration adds only model-dependent UI: Home/history version labels, legacy V1 identification, a mixed-version trend warning without a comparison delta, concise manual source-period help and local subject/assessment dates/confirmation, V2 What-If labels/ranges, and updated Model Information/Methodology. Existing wheels, three tabs, logo rule, chat layout, navigation and HealthKit windows are unchanged.

Target is the next same-subject individual assessment 1–7 local days ahead; the latest comparable prior result is 1–90 local days old and entered as a percentage. Study is yesterday's outside-class selected-subject total; screen time is yesterday's recreational use excluding study. Legacy or stale manual values require reconfirmation. No default date creates eligibility. Old history retains its originating V1 score; new runs store V2 and target metadata.

**Real-student predictive accuracy remains unverified.** Fresh Xcode validation passed: focused V2 12/12, complete configured suite 354/354 (336 unit + 18 UI), V2 parity 176/176, V1 parity 21/21, explicit Build and Analyze with 0 compiler/analyzer warnings/errors. The test action separately records 25 debugger termination warnings, grouped as one summary warning. Initial CLI environment blocks and three corrected fixture expectations are recorded in the integration evidence. This establishes automated readiness, not physical UI freeze. A must complete the [V2 physical checklist](../ml/v2/2026-09-21-ios-parity/README.md) before sign-off. The approved separate RHR personal-baseline wellbeing design is deferred; no alert or weight change is included.

The older freeze/verification entries below remain historical evidence rather than results for this integration.

**Date:** 2026-09-15  
**Current branch:** `ios-development`  
**Current commit:** `11da98dca5cc585065465fceb3e14e21960a69bc`  
**Current build marker:** `FMQ-2026-09-15-E`

This document defines the UI freeze candidate. The freeze becomes final only after the automated checks below pass and A completes the physical-device checklist. The commit and build marker identify the source baseline; they do not claim that this uncommitted UI work is already part of that commit or marker.

## Frozen structure

**Home | TwinTrack AI | Profile**

The app retains one root SwiftUI `TabView`, exactly three tabs and one shared `TwinTrackState`.

## Frozen visual direction

- Approved TwinTrack dark/light visual system.
- Existing approved light/dark logo assets, shown selectively on Home.
- Current native tab and stack navigation.
- Current Home, compact chat and Profile component hierarchy.
- Inline `System | Light | Dark` appearance control in Profile.
- Current Profile structure, including optional local profile image, data sources, prediction/AI information, privacy controls and About destinations.

## Frozen behavior

- Home displays real available values and honest unavailable, loading and error states.
- Manual Inputs uses hours/minutes wheels, previous-score validation, Cancel/Save and local persistence.
- Explicit prediction runs, deterministic What-If scenarios, seven-day history and read-only stored prediction data retain their established behavior.
- TwinTrack AI retains New Chat, Chat Library, locally saved conversations, composer/keyboard behavior and result cards.
- Edit Profile supports local name, grade and optional profile image with Cancel/Save, change and remove behavior. Invalid local image data falls back to the default avatar.
- Profile image data is resized, stored with file protection in local Application Support and excluded from backup. TwinTrack does not upload it.
- Appearance updates the whole app immediately, persists after relaunch and leaves `System` unforced so it follows iOS.
- Health Permissions, Data & Privacy, Methodology, About, Model Information, Privacy Policy, Terms of Use and Prediction Disclaimer use the existing Profile navigation stack.
- Clear Prediction History remains destructive, requires confirmation and clears prediction history only.
- Stored Prediction Data remains read-only.

## Allowed post-freeze UI changes

Only:

1. Reproducible bugs.
2. Required V2 model-dependent labels or schema changes.
3. Critical accessibility or correctness fixes.
4. Final evidence screenshots.

## Deferred features

- Additional onboarding demographics.
- Message editing.
- Login or backend.
- Cloud profile syncing.
- Major iPad redesign.
- New tabs.
- Visual redesign.
- Unrelated feature additions.

## Pending model-dependent changes

If the selected V2 model changes the deployed schema or description, make the smallest factual update to:

- Model Information.
- Prediction Methodology.
- Home input cards and completeness wording.
- What-If controls and ranges.
- Assistant model/tool descriptions.
- Presentation and final evidence screenshots.

V1 Ridge and its seven-input behavior remain deployed until a V2 comparison, decision, export and separate validation are completed.

## Verification

Automated verification was completed in Xcode on the iPhone 17 Pro iOS 26.5 Simulator:

- Unit tests: **235 passed, 0 failed, 0 skipped (235 total)**.
- UI tests: **13 passed, 0 failed, 1 intentionally excluded (14 discovered)**.
- Combined executed tests: **248 passed, 0 failed**.
- Frozen Ridge golden parity: **21/21 passed**; maximum absolute error `2.8421709430404007e-14` with tolerance approximately `1e-6`.
- Full app build: **passed**.
- Xcode Analyze: **passed**.
- Compiler warnings: **0**.
- Analyzer warnings/errors: **0/0**.
- Build errors: **0**.

One CoreSimulator accessibility-loader warning category appeared during UI automation. It is a simulator runtime warning, not a TwinTrack compiler/analyzer issue, and no test failure was associated with it.

The first focused Profile UI run failed because the expanded privacy copy placed Stored Data below the initial automation viewport. The test was corrected to scroll to the existing control; the unchanged product flow then passed both the focused rerun and the complete suite.

The reported first-open or navigation lag was **not reproduced** in simulator automation. Profile, Edit Profile, Manual Inputs, chat library, What-If, tab navigation and appearance switching all responded during the successful UI suite. Native photo selection and perceived responsiveness still require A's physical-device review.

Physical-device verification is **not yet performed** for the freeze candidate. A must complete the final checklist before recording `UI STATUS: FROZEN`.
