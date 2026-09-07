# Examiner Question Bank

## Native navigation

**Question:** How did you implement and verify TwinTrack's main navigation?

**Answer outline:** TwinTrack uses one native SwiftUI `TabView` with exactly Home, TwinTrack AI, and Profile. Each tab has its own basic navigation container. A UI test verifies there are exactly three tab buttons, checks the title and selected state for every tab, and repeats the complete switching sequence three times in the iPhone Simulator.

**Evidence:** `testThreeTabShell` passed in Xcode 26.6 using the iPhone 17 Pro Simulator on 2026-09-07 with no reported warnings or errors.

**A learning status:** Not confirmed by A.
