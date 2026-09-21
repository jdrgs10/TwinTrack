# Offline V2 validation record — 2026-09-21

Scope: Python research experiment and unchanged V1 Python reference only. No Xcode build, simulator/UI test, physical-device access, fresh Swift parity run or iOS integration was performed or claimed.

| Check | Exact result |
| --- | --- |
| New V2 invariant tests | 12/12 PASS |
| Existing Python V1/assistant regression suite | 33/33 PASS |
| Combined final pytest run | **45 passed, 3 warnings in 1.84 seconds**, exit 0 |
| V1 golden fixture arithmetic | **21/21 PASS**, maximum error 7.105427357601002e-15; existing tolerance 1e-6 |
| Saved V1 pipeline versus frozen JSON | Maximum prediction error 0 |
| Saved V1 versus frozen joblib copy | Maximum prediction error 0 |
| V1 in-memory generator versus CSV | Numeric match below 1e-12 |
| V1 training scaler reconstruction | Mean and population-SD maximum errors 0 |
| V1 in-memory tuning reproduction | Selected alpha 10; coefficient maximum difference 8.881784197001252e-16 |
| V2 full-precision JSON versus sklearn | All 15 fitted pipelines passed held-out formula comparison, tolerance 1e-10 |
| Protected V1/iOS files | **94/94 SHA-256 unchanged**; generated xcuserdata excluded from hash inventory |
| Complete experiment rerun | **26/26 result files byte-identical**, including result hash manifest |
| Data-support checks | All ten scenarios pass finite values, declared feature/target bounds and joint time budget |
| Rejection checks | Missing/nonfinite/out-of-support required inputs and infeasible six-input time combinations rejected |
| Missingness | Missing values remain null; observed inputs/targets unchanged; no zero imputation |
| Removed RHR | Six-input prediction identical with RHR absent |
| Selection | Previous-only provisional research candidate; six/seven numerical complexity gates FAIL; deployment not approved |

The three final warnings are `InconsistentVersionWarning` for StandardScaler, Ridge and Pipeline: the preserved V1 pickle records scikit-learn 1.9.0, while this environment uses 1.8.0. Frozen JSON, pipeline and in-memory refit checks independently agree. Warnings were not suppressed in the regression run and do not establish compatibility for unrelated artifacts.

The first attempt to run the existing regression suite could not start because pytest was absent. pytest 8.4.2 was installed in the temporary isolated dependency directory; the unchanged existing suite then passed 33/33. After renaming one new test to explicitly say “synthetic correlations,” the combined suite passed 45/45. No assertion was weakened, no production file was edited, and no generated result was retuned.

The experiment completed successfully on its first full execution. It was repeated once to a fresh temporary output directory solely to verify reproducibility. All 26 result files matched byte-for-byte; canonical results were not overwritten. The endpoint-probe reference-versus-training-mean discrepancy in the written protocol is disclosed in the report/ledger; it does not change training or candidate selection.

Environment versions are in `results/environment.json` and pinned in `requirements.txt`. Exact scripts/config/protocol hashes from training are stored in that environment record; all generated result hashes are in `results/artifact_sha256.json`. The new-document/file inventory is generated separately so documentation additions do not mutate the experiment manifest.

Reproduce with an isolated environment, from repository root:

```sh
python -m pytest -q -p no:cacheprovider ml/tests/test_twintrack.py ml/v2/2026-09-21/test_experiment.py
python ml/v2/2026-09-21/experiment.py --output /path/to/a/new/output-directory
python ml/v2/2026-09-21/document_results.py
```

The existing assistant tests mock their Qwen calls. This offline pass sent no project/private/participant data to a model endpoint. Only public research web pages and package distribution downloads required network access. Local research reports remain ignored; no real HealthKit values or participant rows enter generated artifacts.

Git scope: all task-created files are under `ml/v2/2026-09-21/` plus `docs/V2_MODEL_FINAL_DECISION.md`. An already-modified Xcode `xcuserdata` workspace state is unrelated and left untouched. A pre-existing tracked `.DS_Store` is unchanged; it was not newly added/copied. Do not include unrelated generated state in any later commit. This pass does not stage, commit, push, or edit `.gitignore`/the local research exclusion.
