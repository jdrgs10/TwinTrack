# Snapshot-aligned seven-input V2 — offline decision only

Version `2.0-aligned.1`, 2026-09-21. **DO NOT APPROVE for iOS integration.** Read `../../../docs/V2_PRODUCTION_ALIGNMENT_DECISION.md` for the numerical results and unresolved product/scientific definitions. This folder contains only synthetic rows, code, aggregate reports and hashes. No participant or device records.

The seven raw features and their order are unchanged. `generator.py` separates latent hypothetical usual-profile factors from noisy app-source snapshots. There is no validated assessment horizon or reporting period for current manual entries. All observation distributions are development assumptions. `PROTOCOL.md` was fixed before training; `ASSUMPTION_LEDGER.md` lists the resolved numerical settings and provenance. No coefficient, sign, seed or noise level was selected to improve appearance.

`rhr_trend.py` is an offline, separately tested personal-baseline design. It is not shipped, does not affect Ridge and does not make medical assessments. Its thresholds require evaluation for the intended teenage audience. It never converts absent days into zero or repeated latest readings into new days.

Use Python 3.12 and the pinned dependencies, from this directory:

```sh
python evaluate.py --output /path/to/a/new/results-directory
python -m pytest -q -p no:cacheprovider test_alignment.py
python document_results.py
```

Tests use canonical `results/`. The experiment refuses to overwrite results; reproduction must use a fresh output directory. Run previous-version tests in a separate process because their bare `generator`/`train` module names intentionally resolve to their own versions.

The small adapters reuse preserved prior generator/training/evaluation code read-only. They change configuration and imported functions **in memory**, never the old files. Training-only five-fold CV chooses Ridge alpha. Ten training splits supply 45,000 pooled rows; 15,000 holdouts stay excluded. Final evaluation has 4,000 separate rows per scenario. `comparison_metrics.csv` compares nine models on common rows across 20 cohorts; two scenario labels intentionally coincide after replacing the measurement layer. Raw transport comparisons do not imply eligibility under old time-window contracts. `common_support_metrics.csv` applies the prior numerical bounds only, not prior subject/date/time-budget requirements.

`results/artifact_sha256.json` covers 28 other outputs; the complete 29-file set reproduced byte-for-byte. `results/environment.json` captures pre-training source hashes; `results/protected_sha256.json` checks 175 V1/iOS/prior-version/research files. `VALIDATION.md` records fresh test results. `FILE_INVENTORY.md` lists files created in this pass.

No Swift edit, Xcode run, physical HealthKit access, HSLS analysis, NetHealth rerun, staging, commit or push occurred.
