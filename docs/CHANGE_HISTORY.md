# Change History

## 2026-09-09 — HealthKit timing, refresh state, and tab switching

### HealthKit timing update

**Before:** Current Health inputs all used completed-day semantics, which delayed recent overnight sleep and treated Resting Heart Rate as a completed-day average.

**Change:** Sleep now uses yesterday local noon through the earlier of now and today local noon. Steps and Exercise retain the previous completed local day. Resting Heart Rate now selects the latest finite positive sample within the previous 72 elapsed hours and retains its timestamp. New optional history metadata preserves backward decoding and distinguishes the timing semantics without rewriting existing snapshots.

**Why:** Current prediction inputs should include the latest appropriate sleep and resting measurement while keeping activity totals stable and complete.

**Improvement:** Current Health inputs have explicit, metric-specific source periods with local-calendar and daylight-saving behavior covered by synthetic tests.

### Refresh-state correction

**Before:** Pull-to-refresh cleared the published Health readings and source window before queries finished. Available values disappeared, and the Apple Health screen continued to expose the request action after setup, making refresh look like authorization had reset.

**Change:** Existing readings and their window remain committed while queries produce a local four-metric result. After cancellation and stale-generation checks, the new window and readings are committed together. Available values stay visible during refresh. Completed setup persists across state recreation, hides the request action, and repeated setup calls route to refresh without presenting authorization again.

**Why:** Refresh should re-read accessible HealthKit data without destroying the current display or restarting the permission workflow. A missing query result cannot reliably establish denied read access.

**Improvement:** Health values remain stable during refresh, updates are atomic, manual values remain untouched, and routine launch/foreground/pull refresh uses one shared path without false reauthorization.

### Tab-transition correction

**Before:** Native tab selection briefly composited outgoing and incoming page content, producing visible overlap and ghosting on the physical iPhone.

**Change:** The existing three-tab `TabView` now disables animation for the page-selection transaction. The destinations, navigation architecture, and single shared state remain unchanged.

**Why:** Overlapping page content made navigation look visually unstable.

**Improvement:** Only the selected page is visually active, giving Home, TwinTrack AI, and Profile clean native-feeling switches.

### Deferred final-polish item

The Home pull-to-refresh function is verified, but A still does not clearly see the native refresh indicator during the gesture. Spinner visibility is a non-blocking aesthetic issue reserved for the final UI/polish milestone. No further spinner changes should be attempted before then.

### Evidence

- Xcode build: pass
- Automated suite: 97/97 pass
- HealthKit: 35/35; Manual/State: 7/7; Home: 5/5; What-If: 17/17; History: 28/28
- Frozen Ridge: 21/21 golden parity
- Tab/UI: 4/4, including repeated switching and one active page header at a time
- Warnings: 0; errors: 0
- A physical retest: refresh function, stable Health values, no repeated access request, manual persistence, and tab transitions pass
- A physical retest: native spinner visibility deferred as non-blocking polish

No private HealthKit values, physical-device screenshots/video, identifiers, credentials, certificates, or provisioning information were inspected or recorded.
