# Evidence Log

## 2026-09-07 — Frozen Swift Ridge parity

| Evidence file | What it proves |
| --- | --- |
| `evidence/ridge_parity/ridge_21_of_21_parity_pass.png` | Readable result showing that the Swift Ridge parity test passed all 21 frozen profiles, with zero failures and the recorded numerical tolerance/error. |
| `evidence/ridge_parity/ridge_parity_xcode_context.png` | Wider Xcode context showing that the result belongs to the native TwinTrack test environment. |

Captured manually by A. File existence, PNG type, and file integrity were verified without visually inspecting or modifying either screenshot.

Recorded result:

- Xcode build/test: pass
- Golden parity: 21/21 pass
- Maximum absolute error: `2.8421709430404007e-14`
- Tolerance: `1e-6`
- `testFrozenRidgeMatchesAll21GoldenProfiles`: pass
- Three-tab regression test: pass
- Warnings: 0
- Errors: 0

Integrity hashes:

- `ridge_21_of_21_parity_pass.png`: SHA-256 `b9e2ad01cc10b70b06c13e3d7e288574431c6422c8ae01e9d56a10e56dde79ab`
- `ridge_parity_xcode_context.png`: SHA-256 `922e5eb9756cef25d90870251d95b537295fc4623b227c901d219130e418b57e`

## 2026-09-07 — Shared state, Manual Inputs, and persistence

| Evidence file | What it proves |
| --- | --- |
| `evidence/manual_inputs/manual_inputs_verified.png` | Shows the native TwinTrack Manual Inputs sheet, the Study Time Hours/Minutes wheel, and valid saved values: Study Time `2h 48m`, Screen Time `4h 15m`, and Previous Score `82`. |
| `evidence/manual_inputs/manual_inputs_persistence_verified.png` | Shows the same three saved values after A stopped TwinTrack in Xcode and relaunched it, confirming app-relaunch persistence. |

Captured manually by A and visually inspected with A's explicit authorization. Both images contain enough TwinTrack context to identify the app. No Apple Account details, serial numbers, device identifiers, certificates, private health data, messages, or unrelated personal information are visible. The screenshots were not modified.

Recorded result:

- Shared `TwinTrackState`: verified; one store
- Manual Inputs: verified
- Local persistence: verified
- New shared-state/manual-input tests: 7/7 pass
- Golden Ridge parity: 21/21 pass
- Three-tab regression: pass
- Missing values remain optional; zero is not used as a missing-data substitute
- Fake HealthKit values introduced: no

Integrity hashes:

- `manual_inputs_verified.png`: SHA-256 `a34b72e96d56ceea47a7c06f3a4ffd91ec19bb3459acfd49c3c6972e8c8f5901`
- `manual_inputs_persistence_verified.png`: SHA-256 `1f15375e113cd6b54e28af68994b15dc371d4e06175bf2913acfebe827d177d9`

## 2026-09-08 — Read-only HealthKit integration

Physical-device verification was completed manually by A. Private HealthKit evidence exists locally but is intentionally not inspected, copied into project records, uploaded to this conversation, or committed to Git because it contains personal health information.

Recorded result:

- HealthKit authorization flow: pass
- Previous completed-day Steps comparison with Apple Health: pass
- Sleep query: pass; no accessible value was expected for the selected sleep window
- Exercise query: pass; no accessible value was expected for the selected completed day
- Resting Heart Rate query: pass; no accessible value was expected for the selected completed day
- Missing-data behavior: pass; unavailable metrics remained missing rather than becoming zero
- Manual refresh for the completed-day design: pass
- Manual-input persistence: pass
- HealthKit synthetic tests: 22/22 pass
- Sleep aggregation tests: 7/7 pass
- Golden Ridge parity: 21/21 pass
- Three-tab regression: pass
- Warnings: 0
- Errors: 0

No evidence filename, path, hash, screenshot content, or personal health value is recorded for this private evidence.

## 2026-09-08 — Home real-data wiring and UI polish

A completed the Home visual review manually on a physical iPhone. No device screenshot was requested, inspected, copied into project records, or committed.

Recorded result:

- Home visual approval: pass
- Header and approved-logo integration: pass
- Locked subtitles: pass
- Prediction-card hierarchy: pass
- Native pull-to-refresh: pass
- Card spacing and layout: pass
- Scrolling and bottom-tab clearance: pass
- Three-tab header consistency: pass
- Home tests: 5/5 pass
- HealthKit tests: 22/22 pass
- Golden Ridge parity: 21/21 pass
- Manual/State tests: 7/7 pass
- Repeated three-tab regression: pass
- Shared state stores: 1
- Warnings: 0
- Errors: 0

This evidence records A's approval statement only. It contains no private HealthKit values, device identifiers, screenshot metadata, certificates, provisioning data, or credentials.

## 2026-09-08 — Deterministic What-If and header/logo correction

A completed the current visual review and approved the deterministic What-If interface. A also approved the final shared-header rule: the approved mark remains on Home and is omitted from TwinTrack AI and Profile, with correct spacing and subtitles. No screenshot was requested or inspected for this record.

Recorded result:

- What-If UI: pass
- Home logo remains shown: pass
- TwinTrack AI logo removed with natural spacing: pass
- Profile logo removed with natural spacing: pass
- Locked subtitles: pass
- Complete baseline required; missing data is not fabricated
- Temporary scenario does not modify shared state, persisted manual inputs, or HealthKit
- Baseline and combined scenario reuse the frozen production Ridge predictor
- Delta uses clamped scenario minus clamped baseline
- Predictive, non-causal wording is visible
- What-If tests: 17/17 pass
- Golden Ridge parity: 21/21 pass
- HealthKit tests: 22/22 pass
- Manual/State tests: 7/7 pass
- Home tests: 5/5 pass
- UI tests, including repeated tab regression: 3/3 pass
- Shared state stores: 1
- Duplicate Ridge logic: no
- HealthKit writes: no
- Fake production values: no
- Warnings: 0
- Errors: 0

This record contains A's approval statement and automated test results only. It contains no private evidence, personal HealthKit values, device identifiers, credentials, certificates, or provisioning data.
