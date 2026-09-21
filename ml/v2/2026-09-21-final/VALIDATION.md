# Final blocker-resolution validation — 2026-09-21

## Fresh test results

| Suite | Result | Warnings |
| --- | --- | --- |
| New final-contract tests |20/20 passed,2.19s|0|
| Preserved aligned tests, including separate RHR trend |20/20 passed,1.92s|0|
| Preserved V1/first V2/seven-input suites |59/59 passed,2.43s|3 existing sklearn pickle-version warnings|
| Total |**99/99 passed**, zero failures|3|

The17 pre-training semantic tests are a subset of the final20; they are not counted again. Tests were run in separate processes to avoid collisions among version-local `generator`/`train` imports. Prior suites were not edited.

Warnings: earlier V1 tests load StandardScaler, Ridge and Pipeline serialized with sklearn1.9.0 using runtime1.8.0. Warnings were not suppressed. New comparison uses immutable V1 JSON, independently checked against21 golden profiles; it does not depend on the legacy pickle for parity.

## Numerical and preservation checks

- V1 golden parity **21/21**; maximum error `7.105427357601002e-15`, tolerance `1e-6`. Python JSON parity, not a new Swift/device test.
- Main experiment: **28/28 result files byte-identical** in a fresh full rerun.
- Diagnostics: **5/5 files byte-identical** in a fresh rerun, including all seeds and the60000-row/seed diagnostic.
- **218 protected files unchanged** by SHA-256: prior V1/iOS, all previous V2 versions/reports and the two approved local research sources.
- Source hashes match pre-run protocol/config/generator/training/evaluation/diagnostic records.
- Exactly seven numerical Ridge features; date/subject/scale fields remain eligibility metadata. No target metadata is used in CV/scaling/prediction.
- Scaler fit on45,000 training rows only;15,000 holdouts excluded. Independent4000-row final cohort. Pipeline, standardized JSON and raw-unit formula agree within1e-10.
- Ten models ×20 cohorts ×2 output modes =400 common metric rows; all models use the same4000 rows in each cohort. Historical contracts differ, so those comparisons are transport diagnostics.
-128/128 new-model rectangle corners finite; raw9.311360416499532–99.72526775283444; zero clamps; fixed guard passes.
- Every predeclared activity magnitude, RHR-size, prior-dominance and direction/core numeric gate passes. Activity sign instability is disclosed and accepted only as tiny conditional model behavior.
- No diagnostic variant or large-sample model was selected; no manual coefficient manipulation.

## Scope

No production Swift edit, new Xcode build, UI test or physical-device inspection occurred. Those remain required during the separately approved integration milestone. No private health data, HSLS outcomes, NetHealth rerun, presentation changes, staging, commit or push.

The pre-existing modified Xcode user-state file was left alone. Local research remains ignored. Generated synthetic dates/subject keys are test metadata, not personal records.

## Reproduction commands

Use the pinned local Python environment, from each indicated version directory:

```sh
# Final version
python -m pytest -q -p no:cacheprovider test_final.py
python evaluate.py --output /path/to/new/results
python diagnose.py --output /path/to/new/diagnostics
# Aligned version, separate process
python -m pytest -q -p no:cacheprovider test_alignment.py
# Previous seven-input version, separate process
python -m pytest -q -p no:cacheprovider test_seven_input.py ../2026-09-21/test_experiment.py ../../tests/test_twintrack.py
```
