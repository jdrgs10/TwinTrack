# Validation — 2026-09-21

- Before training: 14/14 source-semantics and RHR trend checks passed.
- Final new suite: **20/20 passed**, zero warnings, 1.79 seconds. Covers partial sleep, all scenarios, missing vs true zero, bounds, mixed source periods, RHR coverage/distribution/outliers/persistence/recovery/missing days/zero MAD/equality/aging/duplicate refresh/latest sample/time-zone/DST, parameter export, all seeds and preservation.
- Previous offline suites, run unchanged in a separate process: **59/59 passed**, 1.90 seconds (33 V1 + 12 first V2 + 14 previous seven-input). Three existing sklearn `InconsistentVersionWarning`s concern V1 pickle estimators saved in 1.9.0 and loaded in 1.8.0. They were not suppressed. This experiment uses frozen V1 JSON for parity; it does not rely on that pickle for the comparison.
- Total fresh final offline tests: **79/79**; zero failures; three legacy warnings. Initial 14 are a subset, not added again.
- Frozen V1 golden parity: **21/21**, maximum error `7.105427357601002e-15`, tolerance `1e-6`, Python JSON calculation. No claim of a new Swift test run.
- Full experiment rerun into a new temporary output directory: **29/29 files byte-identical**, including model binary, coefficients, synthetic CSVs and manifests.
- All **175 protected files unchanged** by SHA-256. Covers preserved V1/iOS sources, both prior V2 versions/reports and the two approved local research files. Generated Xcode user state is outside this scientific manifest and was already modified before the pass.
- Numerical experiment: 63 CV searches (30 seed/model + 3 pooled + 30 RHR-world refits); each tests five alphas with five folds. Same fixed 4,000 rows per evaluation cohort/model. 360 metric rows = 20 cohorts × 9 models × raw/clamped output.
- New seven-input extremes: all 128 rectangular corners finite, raw range `9.72005037615476` to `99.36344471600673`, none clamped. This checks bounded arithmetic, not human joint-profile plausibility.
- Final decision is still **DO NOT APPROVE**: computational correctness is not scientific/product acceptance.
- No app build/UI tests were required or run: production Swift and project configuration were not edited. No physical-device data was accessed. Nothing staged, committed or pushed.

Commands used with the pinned local Python environment:

```sh
# New folder
python -m pytest -q -p no:cacheprovider test_alignment.py
python evaluate.py
python evaluate.py --output /path/to/new/reproduction/results
# Previous seven-input folder, separate process
python -m pytest -q -p no:cacheprovider test_seven_input.py ../2026-09-21/test_experiment.py ../../tests/test_twintrack.py
```
