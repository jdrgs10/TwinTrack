# TwinTrack V2 model decision draft

**Status:** decision preparation only. No V2 model has been trained, selected, exported, or integrated.

## A. Deployed V1 reference

The current production reference is schema version 1, named **Tuned Standardized Ridge Regression**, and exported from ml/models/twintrack_model.joblib to ml/frozen_export/twintrack_model_params.json. The Swift implementation is ios/twintrack/twintrack/TwinTrackModel.swift.

V1 uses seven Double inputs in this exact order:

1. sleep_hours
2. steps
3. exercise_minutes
4. resting_heart_rate
5. study_minutes
6. screen_time_minutes
7. previous_score

The pipeline is StandardScaler with population standard deviation followed by Ridge with alpha 10.0. The app clamps the raw output to 0–100. The frozen export has 21 golden profiles at tolerance 1e-6. These facts establish reproducibility and implementation parity; they do not establish real-world academic validity.

## B. Current measurements and units

| Input or output | Current app meaning | Unit / range | Evidence |
| --- | --- | --- | --- |
| Sleep | Yesterday local noon through the earlier of now and today local noon | Hours | HealthDataWindow and SleepAggregation |
| Steps | Previous completed local calendar day | Count | HealthDataWindow and HealthKitService |
| Exercise | Previous completed local calendar day | Minutes | HealthDataWindow and HealthKitService |
| Resting heart rate | Latest finite positive sample in the previous 72 hours, timestamp retained | Beats per minute | HealthDataWindow, RestingHeartRateSelection, and HealthKitService |
| Study | User-entered duration | Total minutes; 0 to 15 h 59 min in the current UI | ManualDuration and Manual Inputs |
| Screen time | User-entered duration | Total minutes; 0 to 15 h 59 min in the current UI | ManualDuration and Manual Inputs |
| Previous score | User-entered prior score | 0 to 100 | PreviousScoreInput |
| V1 target | Synthetic dataset column assessment_score | 0 to 100 | generate_data.py |

The intended real assessment event, subject, aggregation rule, and prediction horizon relative to these inputs are **UNKNOWN** in the current repository. The synthetic generator creates same-row values and does not define a real-world collection schedule.

## C. Evidence inventory

Available:

- ml/frozen_export/twintrack_model_params.json: V1 schema, parameters, ranges, split metadata, and recorded metrics.
- ml/frozen_export/golden_profiles.json: 21 implementation-parity fixtures.
- ml/frozen_export/AUDIT.md: independent pre-port audit and reproducibility findings.
- docs/RIDGE_READ_ONLY_AUDIT.md: read-only interpretation of the current Ridge and baselines.
- ml/data/synthetic_students.csv and ml/src/generate_data.py: deterministic 1,000-row synthetic development dataset and its target-generation assumptions.
- ml/results/baseline_comparison.csv: results on the current synthetic split for mean-only, previous-score-only, and V1 Ridge.
- ml/results/prediction_results.csv and ml/results/feature_coefficients.csv: saved V1 analysis outputs. The coefficient table is sorted by absolute coefficient and must not be used as feature order.
- ml/models/model_comparison.joblib: a non-production comparison artifact described by the audit. It is not a V2 candidate.

Missing:

- No completed V2 research report or V2 research brief was found in the repository.
- No approved revised target definition, collection protocol, dataset, six-input experiment, seven-input V2 experiment, or replacement weights were found.
- No external or real-student validation evidence is present.
- No uncertainty or significance analysis establishes that V1 improves on the previous-score-only baseline.

The current saved synthetic holdout results are: V1 Ridge MAE 4.76146176524888, previous-score-only MAE 4.801499116660302, and mean-only MAE 7.1444925. The roughly 0.0400 MAE difference between V1 and previous-score-only is a result on the existing synthetic split, not evidence of a meaningful real-world advantage.

## D. Comparison required before selection

Run one controlled protocol that compares:

1. Unchanged V1 as the locked reference.
2. A revised seven-input Ridge candidate.
3. A revised six-input Ridge candidate excluding resting_heart_rate.
4. A previous-score-only baseline.
5. A mean-only baseline.

Each candidate must use the same declared dataset roles, target, prediction horizon, split or grouping rules, metrics, and final evaluation set. Report raw and clamped behavior separately where the clamp changes results. Do not claim that six inputs perform better until this comparison is executed.

## E. Decisions required before candidate generation

1. **Target and horizon:** Define the assessment outcome, subject or aggregation rule, and when it is predicted relative to the input windows.
2. **Input distributions and dependence:** Choose sourced or explicitly labelled development assumptions for marginal distributions, correlations, bounds, missingness, and repeated observations from one student.
3. **Target generation and noise:** Define a traceable relationship between inputs and target, including nonlinearities, interactions, noise distribution, clipping, and any ceiling or floor effects. Appearance is not a reason to weaken previous score or strengthen lifestyle effects.
4. **Resting heart rate:** Decide whether it is scientifically justified, sufficiently available, and aligned to the prediction horizon. Compare inclusion and exclusion; do not remove it by preference alone.
5. **Dataset roles and evaluation:** Separate candidate development, model selection, and a final locked evaluation set. Decide whether splits must be grouped or temporal. The existing V1 holdout has already been used for selection and reporting and should not become an untouched V2 final test.
6. **Decision rule:** Predefine primary and secondary metrics, acceptable complexity, missing-data coverage, and the threshold for replacing V1.

Every numerical assumption must cite a traceable source or be labelled **development assumption**.

## F. Product changes if the selected model changes

If V2 retains seven inputs, update the model version and status text, methodology, artifact provenance, training and evaluation documentation, golden profiles, and every deterministic tool that reports the deployed model version. Existing HealthKit and manual-input labels can remain if their meanings match the final schema.

If V2 excludes resting heart rate, update the complete-baseline rule, missing-input messages, Home input presentation, Health Permissions explanation, Model Information input count, Methodology, What-If controls, assistant snapshot and tool schemas, prediction-history encoding and versioning, tests, and accessibility labels. Historical V1 snapshots must remain interpretable as seven-input results.

Any selected model requires a versioned export, independent audit, new golden parity fixtures, Swift integration, regression tests, and a separate physical review. V1 remains deployed until that work is explicitly approved and completed.
