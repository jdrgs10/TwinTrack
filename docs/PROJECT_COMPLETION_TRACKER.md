# Project Completion Tracker

## Progress summary

| Area | Completion | Basis |
| --- | ---: | --- |
| Overall project | 88% | Weighted planning estimate: native app 60%, research 20%, deliverable readiness 20%. |
| Native app | 90% | The native shell, frozen Ridge engine, shared state, Manual Inputs, persistence, HealthKit timing/refresh behavior, polished Home, deterministic What-If, prediction history, and 7-day trends are verified. Apple Foundation Models and final polish remain. |
| Research | 100% | Requirements, UI handoff, model choice, frozen export, and ML audit are complete. |
| Deliverable readiness | 70% | Source-of-truth documents and evidence records cover the verified native milestones through History and the HealthKit refresh physical retest. Final report, presentation, demo, release evidence, and final polish remain. |

## Native iOS milestones

| Milestone | Status | Verification |
| --- | --- | --- |
| Exact three-tab SwiftUI shell | Verified | Xcode 26.6 UI test passed in the iPhone 17 Pro Simulator on 2026-09-07. The app exposed exactly Home, TwinTrack AI, and Profile, and completed three repeated switching cycles with the correct navigation title and selected tab each time. Xcode reported no build/test warnings or errors. |
| Frozen Swift Ridge implementation | Verified | The native `TwinTrackModel` reproduces the frozen StandardScaler + Ridge pipeline using `Double`, preserves the immutable seven-feature order, and clamps output to 0–100. |
| 21/21 golden parity | Verified | `testFrozenRidgeMatchesAll21GoldenProfiles` passed all 21 frozen Python profiles at `1e-6` tolerance. Maximum absolute error was `2.8421709430404007e-14`; warnings and errors were zero. The three-tab regression test also passed after integration. |
| Shared TwinTrack state | Verified | The app creates one `TwinTrackState` above the root tab shell and shares it through the SwiftUI environment. It owns all seven optional current inputs and exposes a complete Ridge profile only when every real value exists. No duplicate screen-specific stores or fabricated health values were introduced. |
| Manual Inputs | Verified | Study Time and Screen Time use native Hours/Minutes wheels and store total minutes. Previous Score accepts only numeric values from 0 through 100. Seven focused state tests passed, and A's simulator evidence shows Study Time `2h 48m`, Screen Time `4h 15m`, and Previous Score `82`. |
| Manual-input persistence | Verified | Only the three optional manual values are stored in local `UserDefaults`. Missing values remain absent rather than becoming zero. The recreation test passed, and A captured the same three values after stopping and relaunching TwinTrack. |
| Read-only HealthKit integration | Verified | A verified the four-type authorization flow and real physical-device queries. The available completed-day Steps result matched Apple Health for the same interval; Sleep, Exercise, and Resting Heart Rate correctly remained unavailable because Apple Health had no data in their stated windows. Refresh, missing-data behavior, manual persistence, and tab regression passed. Automated HealthKit tests passed 22/22, including 7/7 sleep aggregation tests, with zero warnings and errors. Private evidence exists locally and is intentionally excluded from Git. |
| Home real-data wiring and UI polish | Verified | Home presents the shared state's seven real inputs and only exposes the frozen Ridge prediction when the profile is complete. A approved the physical-device visual review, including the shared tab headers, approved logo integration, subtitles, prediction hierarchy, card layout, native pull-to-refresh, scrolling, and bottom-tab clearance. Automated verification passed: Home 5/5, HealthKit 22/22, Ridge 21/21, Manual/State 7/7, and repeated three-tab switching; warnings and errors were zero. |
| Deterministic What-If simulation | Verified | A temporary value-type scenario copies a complete seven-input baseline, applies one or several validated changes, and sends the resulting profile through the same frozen `TwinTrackModel`. The displayed delta uses the two clamped production predictions. Missing baselines remain unavailable; cancel and tab exit discard the scenario without modifying shared state, persistence, or HealthKit. What-If tests passed 17/17 and A approved the native UI. |
| Main-tab header/logo correction | Verified | The shared `PageHeader` keeps the approved mark on Home and omits it from TwinTrack AI and Profile while preserving each title and locked subtitle. A approved the resulting spacing on all three tabs. |
| Prediction History and 7-day trends | Verified | Real baseline snapshots are immutable and locally persisted after eligible Health or Manual Inputs commits. Duplicate prevention uses the seven inputs and Health source metadata. The chart shows at most the latest real snapshot per local day over seven calendar days, never fabricates missing points, uses a fixed 0–100 scale, and opens an exact read-only snapshot detail. History tests passed 28/28 and the implementation is committed in `2a0d640` and `ebb1c9c`. |
| HealthKit timing semantics | Verified | Sleep uses yesterday local noon through the earlier of now and today noon; Steps and Exercise use the previous completed local day; Resting Heart Rate uses the latest finite positive sample within 72 elapsed hours with its timestamp retained. Backward-compatible history metadata preserves existing snapshots. |
| HealthKit refresh-state and tab-transition fix | Verified | A's physical retest confirmed stable Health values, no repeated access request, preserved manual inputs, working pull-to-refresh, and clean Home/TwinTrack AI/Profile switching without overlap or ghosting. Automated verification passed 97/97 with HealthKit 35/35, UI 4/4, Ridge 21/21, and zero warnings/errors. |
| Native refresh-spinner visibility | Deferred polish | Refresh works and is non-blocking, but A does not yet clearly see the native indicator during the gesture. Do not pursue this until the final UI/polish milestone. |

Evidence is recorded in `docs/EVIDENCE_LOG.md`. Non-sensitive repository evidence is stored under `evidence/ridge_parity/` and `evidence/manual_inputs/`; HealthKit evidence remains private and outside Git.

The next milestone is Apple Foundation Models. It requires A's approval before implementation begins.
