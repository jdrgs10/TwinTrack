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
