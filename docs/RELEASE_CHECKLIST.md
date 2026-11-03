# TwinTrack release checklist

Prepared 2026-10-06. I keep release readiness separate from software tests, physical acceptance and real-world model validation. This checklist adds no features and authorizes no Git action.

## Acceptance gates

| Gate | Status / evidence |
| --- | --- |
| Exact current branch, source and pending changes identified | `ios-development`, HEAD `2ea2aac`; latest reconciliation in [FINAL_APP_PASS](FINAL_APP_PASS.md). |
| Critical / High blockers resolved | The proven mixed-symptom denial bug is corrected; no additional proven Critical/High issue was found in the reviewed paths. Complete regression now passes; physical acceptance remains pending. |
| Complete configured unit and UI suite | **531/531 distinct cases, 534/534 executions PASS** (492 unit + 42 UI executions), 0 failures/skips, **2361.208 s**, October 6. All 39 UI methods included; launch runs four configurations. |
| Frozen V2 and preserved V1 parity | Fresh portable checks and the final complete Xcode run passed **176/176** and **21/21**. Frozen artifacts and seven-feature order are unchanged. |
| Explicit Xcode Build and Analyze | **PASS / PASS**, 02:20 Asia/Dubai, **12.3 s / 1.8 s**, both completed reports **No issues**. |
| Warnings disclosed by type | Final compiler/analyzer warnings **0/0**, build errors **0**; **2 Body frame runtime entries + 1 grouped debugger warning** remain disclosed. |
| Synthetic physical acceptance | **PENDING A**: [remaining checklist](FINAL_PHYSICAL_ACCEPTANCE.md). |
| Feature / UI freeze | **NOT FROZEN** until the complete source is accepted physically. |
| Real-student predictive accuracy | **NOT VALIDATED**; this is an experimental synthetic-trained model. |

## Research and privacy boundaries

I retain NetHealth as the only completed TwinTrack participant-level comparison. HSLS has protocol/access work only; MCS and COMPASS have no completed participant analysis. I do not use parity, synthetic metrics or completed app tests as empirical validation of V2. [Research synthesis](FINAL_RESEARCH_SYNTHESIS.md).

The final physical/demo preset isolates fictional Health, manual/history, profile/body/photo, appearance and chats. I do not request private HealthKit/BMI screenshots. Ordinary legacy simulator UI tests are not uniformly isolated and must not be run against normal physical-device stores as a privacy-safe test preset.

## Git approval boundary

Nothing is staged, committed, pushed or tagged by this run. The exact 16-file intended manifest is recorded in the current [final pass](FINAL_APP_PASS.md). A should review that manifest before approving one commit.

Exclude generated `xcuserdata`, `.DS_Store`, DerivedData/result bundles, simulator/runtime artifacts, private evidence, real health/profile/chat data, device identifiers, credentials and signing/provisioning material. Keep `.twintrack-local/` excluded via `.git/info/exclude`; it is never a commit input. Pre-existing tracked workspace state is left untouched, not staged as source work.

Proposed message: `Finalize TwinTrack safety, chat layout and release evidence`

Optional tag, only after A's physical approval and a reviewed commit: `v2.0-final.1-demo`. A tag is a project checkpoint, not proof of published release or validated prediction accuracy.
