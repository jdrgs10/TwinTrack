# Final V2 blocker resolution — offline only

Version `2.0-final.1`. Decision: **APPROVE FOR IOS INTEGRATION of the specified experimental design**, not deployment or real-world accuracy. See `../../../docs/V2_FINAL_BLOCKER_RESOLUTION.md`. Current Swift remains V1; legacy manual records do not satisfy the new contract. All new rows are explicitly synthetic.

Seven raw features in unchanged order; StandardScaler + Ridge; no coefficient editing. New manual meanings are previous-day selected-subject study and previous-day recreational screen time. Target is the next same-subject individual quiz/test/exam 1–7 local days ahead, with the latest same-subject prior result 1–90 days old. Date/subject/scale fields are local eligibility metadata, never additional Ridge predictors.

`PROTOCOL.md` fixes definitions, seeds, tiny-effect acceptance and diagnostic ablations before results. The final artifact is the pooled training-only fit; diagnostic variants/large samples cannot select it. `results/new_ridge_seven_parameters.json` stores full precision. `deployment_approved: false` is intentional: implementation and physical validation are outstanding.

Python 3.12, isolated pinned dependencies in `requirements.txt`:

```sh
python evaluate.py --output /path/to/new/results
python diagnose.py --output /path/to/new/diagnostics
python -m pytest -q -p no:cacheprovider test_final.py
python document_results.py
```

Tests refer to canonical results. Experiment/diagnostic runners refuse overwrites. Prior suites require separate processes because version-local generator/train module names overlap. Imported prior code is read-only; configuration ablations exist in memory only and are restored. All earlier candidates and source artifacts are hash-protected.

`train.checked_predict` validates only numbers. Integration must validate real-baseline metadata with `metadata_eligible` AND current HealthKit freshness, before allowing a baseline or What-If. A hypothetical prior-score override remains explicitly hypothetical; do not overwrite the actual prior result or claim it is validated by the old numerator/denominator.

RHR wellbeing remains the separate, preserved design in `../2026-09-21-aligned/rhr_trend.py`; no clinical validation or new alert integration occurred. No Swift/iOS edit, NetHealth rerun, HSLS outcomes, real HealthKit data, stage, commit or push.
