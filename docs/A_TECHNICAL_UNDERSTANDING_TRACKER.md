# A Technical Understanding Tracker

## Three-tab SwiftUI shell

- Implementation state: verified in the iPhone 17 Pro Simulator.
- Architecture to explain later: one root SwiftUI `TabView` owns exactly three tabs. Each tab currently contains a simple `NavigationStack` and title.
- Verification to explain later: `testThreeTabShell` asserts the tab count, initial Home state, correct title and selection for every tab, and three repeated switching cycles.
- Useful code comment: the root navigation comment records that the locked navigation has exactly three tabs and that iOS owns tab selection and safe-area behavior.
- A learning status: not confirmed by A.

## Frozen Swift Ridge model

- Implementation state: verified with 21/21 golden profiles in the iPhone 17 Pro Simulator.
- Architecture to explain later: `TwinTrackProfile` accepts exactly seven typed `Double` values, and one `TwinTrackModel` owns all scaling, Ridge calculation, and 0–100 clamping.
- Locked order: sleep hours, steps, exercise minutes, resting heart rate, study minutes, screen time minutes, previous score.
- StandardScaler rule: each value becomes `z = (x - mean) / scale` before applying its frozen Ridge coefficient.
- Precision rule: the complete numerical path uses `Double`; the required tolerance is `1e-6`.
- Safety boundary: Foundation Models may explain a prediction later but must never reproduce or calculate the Ridge numbers.
- Golden-test rule: expected Python values are frozen and must never be edited to make a test pass.
- Verification result: 21/21 passed, maximum absolute error `2.8421709430404007e-14`, zero warnings, zero errors.
- A learning status: not confirmed by A.
