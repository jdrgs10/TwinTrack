# Seven-input V2 research candidate — 2026-09-21

This new version preserves A's seven-input product constraint. All new training/evaluation rows are **EVIDENCE-INFORMED SYNTHETIC DATA**, not real students. The numerical generator assumptions are not validated academic effects. Read `PROTOCOL.md` and the final report before using any artifact.

The recommended seven-input research artifact is `results/new_ridge_seven_parameters.json`, paired with `results/seven_input_model.joblib`. It is NOT integrated or approved for deployment. All coefficients are fitted by StandardScaler + Ridge, never manually assigned. `coefficients_raw` are the algebraic conversion of fitted standardized coefficients, not separate hand-picked parameters.

With Python 3.12 and an isolated environment containing `requirements.txt`, from this directory:

```sh
python evaluate.py --output /path/to/a/new/results-directory
python -m pytest -q -p no:cacheprovider test_seven_input.py
python document_results.py
```

`generator.py` specifies correlated synthetic window summaries; `train.py` fits fold-local scaling/Ridge and exports parameters; `evaluate.py` orchestrates the fixed protocol. Existing result directories cannot be overwritten. `document_results.py` generates the ledger, result tables, final report and file inventory from canonical `results/`. Tests use canonical results for preservation/artifact checks.

The final artifact pools exactly 45,000 training rows from ten fixed seeds; 15,000 development holdout rows are excluded. `synthetic_v2.csv` stores all 60,000 rows with seed, row and split labels. Final and missingness datasets contain separate 4,000-row cohorts/masks. No participant files, private chat/health data, device identifiers or research-report copies are included.

The old `../2026-09-21/` version and frozen V1 remain unchanged. Evaluation imports the prior generator read-only for new-draw transport testing and reads its JSON candidates. `results/protected_sha256.json` covers prior V1/iOS, previous-version files/report, and the two approved ignored local research sources. `results/artifact_sha256.json` covers every generated result except itself. New scripts/config/protocol hashes are recorded before training in `results/environment.json`.

Use `comparison_metrics.csv` for all models on identical rows; distinguish `old_*` preserved artifacts from `new_*` models fitted on the new pooled training data. Coefficient stability covers ten independent 4,500-row fits, not ten copies of the pooled artifact. Alternative RHR refits are assumption diagnostics, never candidate selection. The previous generator's old final test is not reused as pristine evidence.

All three new exports retain the proposed 28-day input-window / seven-day forecast contract. Current app previous-day/latest-72-hour inputs are not interchangeable. `checked_predict` validates numeric bounds/time feasibility only; actual subject/date/coverage checks still require separately approved integration. The nonlinear assumptions shape only the synthetic target: the exported raw-input Ridge remains linear and does not implement those plateaus.

Full outcome: `../../../docs/V2_SEVEN_INPUT_FINAL_RECOMMENDATION.md`. Exact created-file inventory: `FILE_INVENTORY.md`. No stage, commit, push or iOS integration is part of this pass.
