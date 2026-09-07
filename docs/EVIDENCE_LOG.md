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
