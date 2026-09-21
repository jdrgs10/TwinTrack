# Files changed by the V2 iOS integration pass

These are the intended integration files only. No file is staged. Automated iOS verification passed (354/354, Build and Analyze); physical review remains pending A. Existing untracked prior V2 decision reports/candidate folders are not newly created by this integration pass and require their own artifact review.

- `docs/EVIDENCE_LOG.md`
- `docs/UI_FREEZE.md`
- `ios/twintrack/twintrack/AssistantTools.swift`
- `ios/twintrack/twintrack/FoundationAssistantService.swift`
- `ios/twintrack/twintrack/HomeView.swift`
- `ios/twintrack/twintrack/PredictionHistory.swift`
- `ios/twintrack/twintrack/PredictionTrendView.swift`
- `ios/twintrack/twintrack/ProfileView.swift`
- `ios/twintrack/twintrack/TwinTrackModel.swift`
- `ios/twintrack/twintrack/TwinTrackModelV2.swift`
- `ios/twintrack/twintrack/TwinTrackState.swift`
- `ios/twintrack/twintrack/V2PredictionContext.swift`
- `ios/twintrack/twintrack/V2UITestFixture.swift`
- `ios/twintrack/twintrack/WhatIfScenario.swift`
- `ios/twintrack/twintrack/WhatIfView.swift`
- `ios/twintrack/twintrack/twintrackApp.swift`
- `ios/twintrack/twintrackTests/AssistantFinalFixTests.swift`
- `ios/twintrack/twintrackTests/AssistantPhysicalReviewTests.swift`
- `ios/twintrack/twintrackTests/AssistantQualityTests.swift`
- `ios/twintrack/twintrackTests/AssistantReliabilityTests.swift`
- `ios/twintrack/twintrackTests/AssistantTests.swift`
- `ios/twintrack/twintrackTests/ChatLibraryTests.swift`
- `ios/twintrack/twintrackTests/DurationPickerTests.swift`
- `ios/twintrack/twintrackTests/ExplicitPredictionTests.swift`
- `ios/twintrack/twintrackTests/HomeViewTests.swift`
- `ios/twintrack/twintrackTests/PredictionHistoryTests.swift`
- `ios/twintrack/twintrackTests/V2IntegrationTests.swift`
- `ios/twintrack/twintrackTests/WhatIfScenarioTests.swift`
- `ios/twintrack/twintrackTests/golden_v2_final_1.json`
- `ios/twintrack/twintrackTests/twintrackTests.swift`
- `ios/twintrack/twintrackUITests/twintrackUITests.swift`
- `ml/v2/2026-09-21-ios-parity/ContractCheck.swift`
- `ml/v2/2026-09-21-ios-parity/FILES_CHANGED.md`
- `ml/v2/2026-09-21-ios-parity/ParityCheck.swift`
- `ml/v2/2026-09-21-ios-parity/README.md`
- `ml/v2/2026-09-21-ios-parity/export_ios.py`
- `ml/v2/2026-09-21-ios-parity/golden_v2_final_1.json`
- `ml/v2/2026-09-21-ios-parity/source_hashes.json`

Local-only update (never commit):

- `.twintrack-local/TWINTRACK_MASTER_HANDOFF.md`

Excluded: pre-existing Xcode `xcuserdata` user state; `.DS_Store`, DerivedData, simulator/runtime products, local research, private evidence, credentials, certificates and signing/provisioning material. Build products, filtered diagnostics and portable executable outputs were written only to the temporary validation directory.

Suggested message for A’s eventual approved commit: `Integrate experimental Ridge V2 2.0-final.1 with dated eligibility and versioned history`
