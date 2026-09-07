# Examiner Question Bank

## Native navigation

**Question:** How did you implement and verify TwinTrack's main navigation?

**Answer outline:** TwinTrack uses one native SwiftUI `TabView` with exactly Home, TwinTrack AI, and Profile. Each tab has its own basic navigation container. A UI test verifies there are exactly three tab buttons, checks the title and selected state for every tab, and repeats the complete switching sequence three times in the iPhone Simulator.

**Evidence:** `testThreeTabShell` passed in Xcode 26.6 using the iPhone 17 Pro Simulator on 2026-09-07 with no reported warnings or errors.

**A learning status:** Not confirmed by A.

## Frozen prediction engine

**Question:** How does TwinTrack calculate its numerical prediction on the iPhone?

**Answer outline:** The app accepts exactly seven values in a fixed order. It standardizes each value using the frozen training mean and scale, multiplies the standardized values by the frozen Ridge coefficients, adds the intercept, and clamps the result to 0–100. The complete calculation uses Swift `Double` and lives in one reusable `TwinTrackModel`.

**Question:** How do you know the Swift model matches the Python model?

**Answer outline:** The Swift unit test loads 21 frozen profiles containing Python `expected_raw` and `expected_clamped` outputs. It checks the feature order and compares every Swift result at `1e-6` tolerance. All 21 passed, with maximum absolute error `2.8421709430404007e-14`.

**Question:** Why must Foundation Models not calculate the prediction?

**Answer outline:** A language model is not the numerical source of truth and may produce nondeterministic results. TwinTrack uses the single deterministic Ridge engine for scores and future What-If deltas; Foundation Models may only explain those computed results.

**Evidence:** `ridge_21_of_21_parity_pass.png` records the readable parity result, and `ridge_parity_xcode_context.png` records the wider TwinTrack/Xcode test context.

**A learning status:** Not confirmed by A.
