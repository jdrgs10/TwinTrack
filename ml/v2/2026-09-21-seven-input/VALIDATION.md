# Seven-input offline validation — 2026-09-21

Scope: numerical research code, new synthetic artifacts, preserved prior V2 and V1 Python reference. No app code was edited and no Xcode/Swift/UI/device run is claimed.

| Check | Result |
| --- | --- |
| New generator/contract checks before training | 8 passed, 6 artifact-dependent tests deselected; 1.96 seconds |
| New seven-input tests, final combined run | **14/14 PASS** |
| Previous V2 invariant tests | **12/12 PASS** |
| Existing V1 Python/assistant regressions | **33/33 PASS** |
| Complete applicable Python suite | **59 passed, 3 warnings in 2.37 seconds**, exit 0 |
| V1 frozen JSON/golden arithmetic | **21/21 PASS**, maximum error 7.105427357601002e-15, tolerance 1e-6 |
| Pooled seven-input sklearn / exported standardized formula / raw equivalent | PASS, tolerance 1e-10 |
| Serialized new model round trip | PASS, tolerance 1e-10 |
| Model selection / preprocessing | Training-only five-fold CV; fold-local scaler; pooled scaler independently matches 45,000 training rows |
| Holdout isolation | 60,000 synthetic development rows; 45,000 training / 15,000 held-out; all seed-row keys unique |
| Common final comparisons | Eight candidates on identical 4,000-row cohorts, 17 scenario/transport cohorts, raw and clamped metrics |
| Seed stability | Ten central seed fits for each new model; ten additional seven-input fits per null/negative/positive RHR world |
| Nonlinear target behavior | Sleep/exercise caps, diminishing study increments and screen neutral zone verified; these are generator assumptions, not nonlinear model inference |
| Feasibility / missingness | All 16 new-generator scenarios pass finite/bounds/time checks; invalid inputs rejected; missing values stay null |
| Extreme profiles | 128 corners per candidate; new seven accepts 72 and rejects 56 time-infeasible corners; allowed raw range [11.518228, 99.299889] |
| Preservation | **134/134 pre-existing files unchanged** by SHA-256, including prior V1/iOS inventory, previous V2 files/report and two approved local research sources |
| Full independent rerun | **27/27 generated result files byte-identical**, including joblib and hash manifest |
| Integration decision | **DO NOT APPROVE** while 28-day model input contract differs from current app measurements; no integration performed |

The three warnings come from the unchanged existing V1 suite loading Pipeline/Ridge/StandardScaler pickles saved under scikit-learn 1.9.0 into 1.8.0. New artifacts use 1.8.0 consistently. This experiment evaluates frozen V1 through its JSON formula; parity passes. No warning was silently removed. No test failure occurred, and no coefficients, seeds, noise levels or assertions were adjusted after results.

The complete experiment succeeded on its first full run, then ran once into a fresh temporary directory solely for reproducibility verification. Both output manifests and all 27 result files matched exactly. Canonical results were not overwritten. The protocol, config and scientific generator assumptions were fixed before training. Documentation is generated afterward from canonical result files.

There are 14 new focused tests: deterministic generation; all-scenario bounds/time feasibility; induced dependence/activity overlap; nonlinear target limits; common-input RHR assumption worlds; missingness integrity; training-only scaling/export; invalid-input rejection; pooled training/holdout separation; artifact/formula parity; common evaluation cohorts; prior/result hashes; V1 golden parity; full RHR seed coverage. No real student or private HealthKit data is used.

Reproduction (isolated Python 3.12, `requirements.txt`):

```sh
python -m pytest -q -p no:cacheprovider ml/tests/test_twintrack.py ml/v2/2026-09-21/test_experiment.py ml/v2/2026-09-21-seven-input/test_seven_input.py
python ml/v2/2026-09-21-seven-input/evaluate.py --output /path/to/a/new/results-directory
python ml/v2/2026-09-21-seven-input/document_results.py
```

Existing assistant regression tests mock Qwen responses. No private data was uploaded. Public literature was consulted; local NetHealth/strategy sources were read without copying them into the tracked research artifacts, and their hashes stayed unchanged. HSLS outcomes and MCS/COMPASS participant data were not opened or analyzed.

Only the new version directory plus `docs/V2_SEVEN_INPUT_FINAL_RECOMMENDATION.md` were created. The previous version/report remain untouched. Pre-existing Xcode user-workspace changes remain unrelated; no new `.DS_Store`, `xcuserdata`, DerivedData, simulator output, credentials, device identifiers or participant records are included in the file inventory. Nothing staged, committed or pushed.
