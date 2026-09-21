# Offline V2 candidate comparison, 2026-09-21

All generated rows are **EVIDENCE-INFORMED SYNTHETIC DATA**, not real students. Numerical distributions/effects are explicit development assumptions. See `PROTOCOL.md`, `config.json`, `ASSUMPTION_LEDGER.md`, and `../../../docs/V2_MODEL_FINAL_DECISION.md`.

No production integration, V1 overwrite, NetHealth rerun, or HSLS/MCS/COMPASS participant-data analysis. V1 pickle loading reports a scikit-learn version warning (saved 1.9.0, runtime 1.8.0); frozen JSON/pipeline predictions and refit parameters are independently checked. All 94 tracked V1/iOS files are SHA-256 checked, excluding generated xcuserdata. Local private research files stay in ignored `.twintrack-local/`; source hashes and aggregate descriptions establish provenance.

Use Python 3.12 with `requirements.txt` in an isolated environment. From this directory:

```sh
python experiment.py --output /path/to/a/new/output-directory
python -m unittest -v test_experiment.py
```

The script refuses to overwrite an existing results directory. Unit tests check the saved canonical `results/` as well as fresh synthetic samples. The normal experiment writes only to the explicit output directory; all V1 generator/tuning reproduction is in memory. `results/artifact_sha256.json` inventories all generated artifacts. No V2 joblib is needed: JSON stores the full StandardScaler/Ridge double-precision formula, units/order, support bounds, abstention contract and explicit `deployment_approved: false` flag. `*_export_checks.json` are Python export fixtures, not completed Swift parity tests.

`synthetic_development.csv` contains the preselected seed-1101 cohort and explicit train/development-holdout assignment. Other seed cohorts regenerate from the code/config. `synthetic_final_test.csv` is a separate seed-97001 cohort; `synthetic_missingness_test.csv` preserves nulls. `metrics.csv` records every seed/model/output and every prespecified stress scenario. The same candidate models score all stress scenarios without refitting. Means-only cannot have a calibration slope; its slope/intercept fields are blank/null intentionally. Bootstrap intervals cover synthetic sampling only.

Selection thresholds were fixed before running the experiment. Do not lower them or change seeds to create a more attractive result. Full numeric findings and the distinction between a provisional candidate and deployment approval are in the final decision report.
