# Project Completion Tracker

## Progress summary

| Area | Completion | Basis |
| --- | ---: | --- |
| Overall project | 80% | Weighted planning estimate: native app 60%, research 20%, deliverable readiness 20%. |
| Native app | 80% | The native shell, frozen Ridge engine, shared state, Manual Inputs, persistence, HealthKit, polished Home, and deterministic What-If simulation are verified. Remaining product features are pending. |
| Research | 100% | Requirements, UI handoff, model choice, frozen export, and ML audit are complete. |
| Deliverable readiness | 60% | Source-of-truth documents and evidence records now also cover deterministic What-If behavior and A's visual approval; final report, presentation, demo, and release evidence remain. |

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

Evidence is recorded in `docs/EVIDENCE_LOG.md`. Non-sensitive repository evidence is stored under `evidence/ridge_parity/` and `evidence/manual_inputs/`; HealthKit evidence remains private and outside Git.

The next milestone is Prediction History and 7-day trends. It has not started and requires A's approval.
