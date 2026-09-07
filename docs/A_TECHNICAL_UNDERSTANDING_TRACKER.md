# A Technical Understanding Tracker

## Three-tab SwiftUI shell

- Implementation state: verified in the iPhone 17 Pro Simulator.
- Architecture to explain later: one root SwiftUI `TabView` owns exactly three tabs. Each tab currently contains a simple `NavigationStack` and title.
- Verification to explain later: `testThreeTabShell` asserts the tab count, initial Home state, correct title and selection for every tab, and three repeated switching cycles.
- Useful code comment: the root navigation comment records that the locked navigation has exactly three tabs and that iOS owns tab selection and safe-area behavior.
- A learning status: not confirmed by A.
