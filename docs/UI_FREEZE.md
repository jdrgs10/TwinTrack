# TwinTrack UI Freeze

**Date:** 2026-09-15  
**Current branch:** `ios-development`  
**Current commit:** `11da98dca5cc585065465fceb3e14e21960a69bc`  
**Current build marker:** `FMQ-2026-09-15-E`

This document defines the UI freeze candidate. The freeze becomes final only after the automated checks below pass and A completes the physical-device checklist. The commit and build marker identify the source baseline; they do not claim that this uncommitted UI work is already part of that commit or marker.

## Frozen structure

**Home | TwinTrack AI | Profile**

The app retains one root SwiftUI `TabView`, exactly three tabs and one shared `TwinTrackState`.

## Frozen visual direction

- Approved TwinTrack dark/light visual system.
- Existing approved light/dark logo assets, shown selectively on Home.
- Current native tab and stack navigation.
- Current Home, compact chat and Profile component hierarchy.
- Inline `System | Light | Dark` appearance control in Profile.
- Current Profile structure, including optional local profile image, data sources, prediction/AI information, privacy controls and About destinations.

## Frozen behavior

- Home displays real available values and honest unavailable, loading and error states.
- Manual Inputs uses hours/minutes wheels, previous-score validation, Cancel/Save and local persistence.
- Explicit prediction runs, deterministic What-If scenarios, seven-day history and read-only stored prediction data retain their established behavior.
- TwinTrack AI retains New Chat, Chat Library, locally saved conversations, composer/keyboard behavior and result cards.
- Edit Profile supports local name, grade and optional profile image with Cancel/Save, change and remove behavior. Invalid local image data falls back to the default avatar.
- Profile image data is resized, stored with file protection in local Application Support and excluded from backup. TwinTrack does not upload it.
- Appearance updates the whole app immediately, persists after relaunch and leaves `System` unforced so it follows iOS.
- Health Permissions, Data & Privacy, Methodology, About, Model Information, Privacy Policy, Terms of Use and Prediction Disclaimer use the existing Profile navigation stack.
- Clear Prediction History remains destructive, requires confirmation and clears prediction history only.
- Stored Prediction Data remains read-only.

## Allowed post-freeze UI changes

Only:

1. Reproducible bugs.
2. Required V2 model-dependent labels or schema changes.
3. Critical accessibility or correctness fixes.
4. Final evidence screenshots.

## Deferred features

- Additional onboarding demographics.
- Message editing.
- Login or backend.
- Cloud profile syncing.
- Major iPad redesign.
- New tabs.
- Visual redesign.
- Unrelated feature additions.

## Pending model-dependent changes

If the selected V2 model changes the deployed schema or description, make the smallest factual update to:

- Model Information.
- Prediction Methodology.
- Home input cards and completeness wording.
- What-If controls and ranges.
- Assistant model/tool descriptions.
- Presentation and final evidence screenshots.

V1 Ridge and its seven-input behavior remain deployed until a V2 comparison, decision, export and separate validation are completed.

## Verification

Automated verification was completed in Xcode on the iPhone 17 Pro iOS 26.5 Simulator:

- Unit tests: **235 passed, 0 failed, 0 skipped (235 total)**.
- UI tests: **13 passed, 0 failed, 1 intentionally excluded (14 discovered)**.
- Combined executed tests: **248 passed, 0 failed**.
- Frozen Ridge golden parity: **21/21 passed**; maximum absolute error `2.8421709430404007e-14` with tolerance approximately `1e-6`.
- Full app build: **passed**.
- Xcode Analyze: **passed**.
- Compiler warnings: **0**.
- Analyzer warnings/errors: **0/0**.
- Build errors: **0**.

One CoreSimulator accessibility-loader warning category appeared during UI automation. It is a simulator runtime warning, not a TwinTrack compiler/analyzer issue, and no test failure was associated with it.

The first focused Profile UI run failed because the expanded privacy copy placed Stored Data below the initial automation viewport. The test was corrected to scroll to the existing control; the unchanged product flow then passed both the focused rerun and the complete suite.

The reported first-open or navigation lag was **not reproduced** in simulator automation. Profile, Edit Profile, Manual Inputs, chat library, What-If, tab navigation and appearance switching all responded during the successful UI suite. Native photo selection and perceived responsiveness still require A's physical-device review.

Physical-device verification is **not yet performed** for the freeze candidate. A must complete the final checklist before recording `UI STATUS: FROZEN`.
