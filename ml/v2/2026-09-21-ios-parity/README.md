# V2 2.0-final.1 native integration — automated validation PASS

Date: 2026-09-21. No retraining/refitting. Real-student predictive accuracy remains unverified.

## Exact source

`../2026-09-21-final/results/new_ridge_seven_parameters.json`

SHA-256: `62cb14d443221f9f2e426280ebdf52d7ef8614812a89ef5031329642ff040024`.

All 27 entries in the approved final artifact hash manifest were verified before export and again after integration. `source_hashes.json` records the parameter, Python pipeline and manifest hashes. `export_ios.py` loads the frozen Python pipeline; it never fits it. Swift receives the full-precision scaler means/scales, standardized coefficients and intercept, in the unchanged seven-feature order; alpha 0.1 and output clamp 0–100. V1 remains a separate Swift engine with identical parameters/arithmetic and its unchanged 21-profile JSON.

## Fresh results from this pass

Validation used Xcode **TwinTrack Serial** on the existing **iPhone 17 Pro Simulator**, after A granted scoped access. Final run: **2026-09-21 21:33:00–21:43:50 Asia/Dubai**, **649.719 seconds**.

| Check | Result |
| --- | --- |
| Focused V2 iOS XCTest group | **12/12 PASS**, no failures/skips |
| New V2 Python ↔ Swift iOS golden test | **176/176 PASS**, tolerance **1e-6** |
| Preserved V1 iOS golden test | **21/21 PASS**, tolerance **1e-6** |
| Complete configured unit suite | **336/336 PASS** |
| Complete configured UI suite | **18/18 PASS**, including V2 manual-meaning/history/relaunch test |
| Complete configured suite | **354/354 PASS**, 0 failed, 0 skipped |
| Explicit Xcode Build after the final suite | **PASS**, 21:45; compiler warnings/errors **0/0** |
| Xcode Analyze after the final suite | **PASS**, 21:45; analyzer warnings/errors **0/0**, Issue Navigator empty with filters off |
| Production Swift V2 standalone parity | **176/176 PASS**, max absolute error **2.842170943040401e-14**, tolerance **1e-6** |
| Preserved production Swift V1 standalone parity | **21/21 PASS**, max absolute error **2.842170943040401e-14**, tolerance **1e-6** |
| Production V2 date-contract portable checks | **12/12 PASS**; boundaries, DST, expiry, confirmation, time-zone change, Codable round trip |
| Syntax parse / diff formatting / intended-file privacy scan | **PASS**; 55 Swift files parsed; no prohibited artifact/key/identifier pattern introduced |

**Separate test-runtime diagnostics:** the final test action contains **25 debugger termination warnings**, all `Debug session ended with code 9: killed`, represented as **one Uncategorized warning** in the result summary. These accompany test-app termination/relaunch; there were no test failures. They are recorded separately from the clean explicit Build/Analyze and are not described as zero total runtime warnings.

Twelve new V2 XCTest methods and one new UI method are included in these fresh results. The existing launch-only screenshot-test exclusion is unchanged and is not counted as a pass. No safety assertion was removed. Existing fixtures now supply explicit synthetic dates/confirmation and RHR timestamps; What-If tests enforce V2 support.

### Development results retained

- Initial command-line focused/full tests were blocked before execution (exit 70), and command-line Build/Analyze were blocked at runtime asset compilation (exit 65). Direct preflight could not execute the Foundation Models macro service. A then granted Xcode access; the successful Xcode results above supersede those environment blocks.
- First full Xcode run: **351/354 passed, 3 failed**, 0 skipped; **665.831 seconds**. All **18 UI tests passed**. Two assistant test fixtures still expected a 13-hour sleep scenario to succeed despite the approved V2 maximum of 12. Fixtures now test the allowed 12-hour case and retain 13 hours as a rejected/no-prediction scenario. The history-clear test compared committed Health readings with an undated fixture; it now compares the exact pre-clear committed snapshot, including the synthetic RHR sample timestamp. These were test expectations, not production defects; no model, routing or HealthKit code was changed to resolve them.
- The subsequent complete **354/354** run includes all three corrections and is the final result. The Profile subtitle assertion passed; no flake retry or weakened assertion was needed.

The 176 fixtures include 25 ordinary profiles, 14 individual endpoints, 128 corners, seven What-If increments and two deliberately ineligible input probes solely for raw output-clamp mechanics. The 174 supported profiles are not claims of real-world accuracy or healthy values. The new XCTest resource matches this exported JSON byte-for-byte.

## Reproducing portable checks

Compile `ParityCheck.swift` alongside `ios/twintrack/twintrack/TwinTrackModel.swift` and `TwinTrackModelV2.swift` using the macOS SDK. Run the resulting executable with `golden_v2_final_1.json` followed by the unchanged `ios/twintrack/twintrackTests/golden_profiles.json` paths. Compile `ContractCheck.swift` alongside `V2PredictionContext.swift` for the separate contract checks. Executables/module caches belong outside Git. These commands do not use a simulator or HealthKit.

For reproduction, use Xcode's existing **TwinTrack Serial** scheme on the existing iPhone simulator. Run the V2 group, complete configured unit/UI suite, explicit Build and Analyze. Preserve the existing launch-only screenshot-test exclusion. Use synthetic data only; no physical device, account/signing screen or private Health records are needed.

## Integration behavior

- Current engine: **TwinTrack Ridge V2 / 2.0-final.1**; explicit Run Prediction only. No automatic predictions on refresh, save, render or chat.
- Metadata gates: selected subject/next individual assessment 1–7 local days ahead, latest comparable same-subject prior 1–90 local days old, an explicitly percentage score, and confirmed yesterday source day. No metadata becomes an eighth Ridge input.
- Legacy manual values remain visible but cannot produce V2 until reconfirmed. Values/context are one versioned local defaults payload; malformed V2 data cannot silently revive legacy values. A new day/time zone requires reconfirmation. A subject/assessment change clears the manual-sheet confirmation.
- Existing sleep/activity/RHR queries and timing semantics remain unchanged. RHR needs its real sample timestamp. Missing and unsupported values never become zero or silently clamp inputs; the user sees an unavailable reason.
- Undated/versionless stored predictions decode as **V1 · Legacy**, retain their exact score/input/time and are never recalculated. New snapshots carry V2 plus target/source context. Reuse includes model and target identity. A mixed-version trend shows saved points/version labels without implying cross-model improvement. Stored chat records are not rewritten.
- Manual and assistant What-If require a current eligible V2 explicit run, use approved numeric bounds and temporary copies, and cannot mutate current inputs/history. Output language describes model-estimate changes, not causal grade gains.
- Profile methodology/model information, Home version labels and assistant model explanations reflect the experimental contract. Existing wheels, three tabs, navigation and assistant safety/conversation logic are preserved.
- Separate RHR wellbeing design remains **future work**: 33 local days, 28-day baseline excluding five recent days, coverage requirements, median/MAD rule and persistence/clear rules per the approved design. No alert, new query or Ridge adjustment was implemented.

## Physical checklist for A — now ready

1. Enter yesterday's selected-subject outside-class study and recreational screens excluding all study; enter prior percentage score and date 1–90 days old, and the next same-subject individual assessment/date 1–7 days ahead. Confirm and save.
2. With all four accessible Health inputs present, tap Run Prediction; confirm the V2 label and correct input meanings. Missing/out-of-range values must remain honestly unavailable.
3. Run separate What-If scenarios for study, sleep and screen time; verify baseline/changed input/V2 estimate, temporary state and non-causal wording.
4. Ask TwinTrack AI for a prediction, then an explicit What-If; compare its deterministic cards with Home/manual What-If.
5. Open history; distinguish V1 legacy entries from V2, with no overwritten old score. Mixed-version trends must not claim an improvement delta.
6. Relaunch and verify saved manual context/history; next-day or changed-subject values require reconfirmation.

No private screenshots or real Health records are needed for reporting PASS/FAIL. Automated integration is **VERIFIED**; physical-device approval and UI freeze remain **PENDING A**. Nothing staged, committed or pushed.
