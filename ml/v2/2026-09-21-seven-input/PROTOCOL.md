# Seven-input constrained V2 protocol — fixed before training

Version `2.0-seven-input.1`, 2026-09-21. A explicitly retains all seven inputs as a product constraint. This supersedes feature-count selection for this experiment only; it does not change the earlier experiment or prove that seven inputs are scientifically necessary. No production/iOS integration, previous-artifact overwrite, participant-data analysis, NetHealth rerun or HSLS outcome inspection.

## Task and evidence boundary

Retain the prior research contract: UAE Grade 12, approximately ages 16–18, one comparable same-subject assessment percentage 0–100 exactly seven local calendar days after cutoff. Prior score is the most recent comparable same-subject assessment before cutoff, <=90 days old. Habits are arithmetic means over 28 completed local days; require >=21 observed days of each habit or abstain. Sleep uses completed noon windows. RHR is the mean of daily valid resting-HR summaries, not NetHealth average HR. Study is deliberate outside-class same-subject study; screen is recreational use excluding study and simultaneous double counting. The simulation models window summaries, not actual daily coverage or timestamp metadata. All timing thresholds are assumptions. Current app single-day/latest-72-hour values do NOT satisfy this contract; mapping must be resolved before integration approval.

NetHealth is completed, known development evidence: prior performance dominates; the wearable block showed no meaningful increment. The strategy PDF is planning evidence. Published MCS/COMPASS papers are not TwinTrack participant analyses. No compatible study estimates all seven numerical point-scale effects. Use the previous report's primary sources, including mixed RHR findings. All generator numbers are explicit DEVELOPMENT ASSUMPTIONS, not converted GPA effects, standardized betas or correlations.

## Revised generator choices

Keep the prior generator's latent engagement/fitness/screen-preference structure, Beta prior-score distribution, time budget, measurement-error and missingness mechanisms, with configuration fully materialized here. Change steps coupling from 70 to 50 steps per exercise minute and incidental steps from median 2,000/log-SD .35 to 3,000/.55: independent incidental activity reduces the near-deterministic .887 steps/exercise relationship. These numbers are assumptions, not a fitted adolescent covariance matrix.

Keep previous-score slope .8 and noise SD 8; do not reduce prior dominance or noise to improve appearance. A small negative RHR effect (-.03 points/bpm), tiny positive steps (.00003/count) and exercise (.003/minute below cap) test the product-constrained hypothesis; they are not empirical academic effects. Compare null/opposite/stronger RHR scenarios and refit those assumed RHR worlds separately to distinguish training variability from uncertain signal. Do not increase a coefficient if it is unstable.

Use a transparent bounded nonlinear *target assumption*: sleep plateaus at 8.5 h; study uses `180*log1p(minutes/90)` (local derivative 1 at 90 minutes); exercise plateaus at 60 min; screen has no direct penalty below 120 recreational minutes, then a weak slope. Subtract each transform's value at its reference. These choices avoid unlimited benefit / automatic harm from every minute. The existence, locations and shapes of those effects are NOT established by the evidence. Linear, shifted-cap, null and opposite-direction scenarios test the consequences; no curve search. Final model still uses the original seven raw inputs, StandardScaler and Ridge. Report any linear-surrogate failure to reproduce these plateaus rather than claiming nonlinear behavior in the exported Ridge.

## Fixed training/evaluation procedure

- Ten synthetic generation/split seeds 2101–2110; 6,000 rows each; 75/25 training/development holdout. No real student records. Each row is one independent hypothetical student/window.
- Each seed fits previous-only, six-input and seven-input pipelines with shuffled five-fold training-only CV, seed equal to generation seed. StandardScaler is inside CV. Alpha [.1,1,10,100,1000]; score negative MAE. No manual coefficient edits, sign constraints or seed selection.
- Final artifact: concatenate all ten *training portions* (45,000 rows), never their holdouts; select alpha with five-fold CV on that pool, random_state 2201. Export pooled previous-only, six-input and seven-input fits. Pooling is predeclared to reduce Monte Carlo error, not to pick attractive coefficients. Per-seed fits remain the stability evidence.
- Independent final cohort 4,000 rows, seed 98001. All candidates score exactly the same rows. Preserve separate new final cohort and previous-generator transport cohort (new seed 98002). The old final test is not reused as untouched evidence.
- Eight comparisons: frozen V1; frozen earlier previous-only/six/seven; new training-pool mean-only; new pooled previous-only/six/seven. Frozen earlier candidates cannot be credited/blamed solely for new-generator training mismatch; matched new baselines isolate current feature increments.
- Stress scenarios: null habits; doubled habits; RHR 0, -.06 and +.03; reversed sleep; noise 6/12; all-linear effects; shifted nonlinear parameters; population shift (Beta 6,4; sleep -1h; screen +60m); previous slopes .55/.95; old stronger activity coupling; doubled measurement error. Same random inputs/noise draws where parameters allow. Central-trained models are fixed, not tuned on scenarios.
- Additional prespecified refits across ten seeds for RHR 0/-.06/+.03 only: seven-input fits, training portions only, report coefficient/sign stability, never select those models for export. This exposes dependence on an assumed small RHR effect.
- MAE/RMSE/R², raw/clamped bias, calibration actual-on-prediction slope/intercept and ten rank bins. Paired bootstrap MAE differences with 2,000 row resamples, seed 78223; conditional synthetic uncertainty only.
- Missingness mask uses independent seed 98003: retain nulls, compare accuracy on identical complete-seven rows and report each model's coverage separately. No real availability-rate claim.
- Standardized and raw coefficient mean/sample SD/min/max/sign frequency for every feature, across all ten fits. No selecting a seed by signs. Report the pooled fit separately.
- What-If increments: sleep +1h, study +30m, screen +60m, steps +2,000, exercise +30m, RHR +5bpm, prior +10pts. Probe feasible ordinary final-cohort rows, raw/clamped changes and nonlinear latent-function differences on the same numeric profiles. The latter is a simulator approximation diagnostic, NOT real counterfactual validation. Also enumerate all 128 rectangular corners, reject infeasible time budgets, and test missing/nonfinite/out-of-range rejection and export parity.

## Acceptance rules, before results

Seven inputs are fixed by product choice, not required to beat previous-only by the old .10 threshold. Report incremental metrics and uncertainty regardless. Scientific acceptance is more than synthetic MAE:

1. Reproducible generation/training, hashes unchanged, explicit ledger, finite/bounded outputs and exact export checks must pass.
2. Previous score must have largest absolute standardized coefficient in every seed. Sleep/study must be positive and screen negative in >=80% of seeds for interpretable intended directions.
3. Weak wearable coefficients: >=80% sign agreement OR maximum absolute per-increment effect <=.5 point in all seeds. The latter means weak/uncertain, NOT scientifically stable. Opposite signs always remain visible in the report. These are prototype-review engineering thresholds, not clinical cutoffs.
4. Large raw corner excursions outside [-5,105] or unrealistic ordinary sensitivities require a flagged review, not a hidden clamp. What-If plateaus must be explicitly contrasted with the linear surrogate. No habit advice from unstable signs.
5. Document domain/task mismatch and real-data limitations. Do not approve a drop-in replacement while current app measurement windows differ from the model contract. `deployment_approved` remains false even if computational checks pass. The final report returns APPROVE FOR IOS INTEGRATION only if acceptance and input-contract mapping are resolved; otherwise DO NOT APPROVE with exact reasons. A's seven-feature constraint does not authorize changing HealthKit semantics.

## Preservation

Hash prior protected V1/iOS files, every previous version's non-cache artifact and report, and the two approved local research files before/after. Store only hashes/aggregate findings, never local research copies. Snapshot hashes of this protocol/config/scripts before training. Reproduce to a fresh output directory and compare artifacts. No staging/commit/push. No physical-device access or private health data needed.
