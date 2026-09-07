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

## Shared state and Manual Inputs

- Implementation state: verified in the iPhone Simulator with automated tests and A's manual visual evidence.
- Architecture to explain later: the app creates exactly one `TwinTrackState` as a root `@StateObject` and passes that same object through the SwiftUI environment above all three tabs.
- Ownership rule: the shared state owns the four future HealthKit values and the three manual values. Screens do not own competing copies of production data.
- Manual conversion rule: Study Time and Screen Time are selected as Hours and Minutes, then stored as total minutes. For example, `2h 48m` is stored as 168 minutes.
- Validation rule: Previous Score accepts finite numeric values from 0 through 100. Invalid, nonnumeric, and out-of-range drafts cannot be saved.
- Persistence rule: the three manual values use local `UserDefaults` and survive state recreation and app relaunch.
- Missing-data rule: every value is optional. Missing data is `nil`, while an explicitly entered zero remains a valid value.
- Ridge boundary: a complete `TwinTrackProfile` is unavailable until all seven real inputs exist, so the Ridge engine cannot be called with fabricated HealthKit values.
- Verification result: 7/7 new state tests passed; the 21/21 Ridge parity test and three-tab regression test also passed. A's two screenshots show the same saved values before and after relaunch.
- A learning status: not confirmed by A.
