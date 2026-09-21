# TwinTrack — final seven-input V2 recommendation

2026-09-21 · `2.0-seven-input.1` · **Offline research candidate only; not integrated**.

## 1. Executive decision

The requested seven-input candidate is trained and exported as **StandardScaler + Ridge, alpha 0.1**, using all seven original input names/order. It is the single predeclared pooled-training candidate, not a manually adjusted or best-seed model. Final integration recommendation: **DO NOT APPROVE at this point**.

Computational checks pass and the model keeps prior attainment dominant with modest lifestyle sensitivities. Steps/exercise remain near-zero and sign-unstable; RHR is small and stable only conditional on an assumed negative effect. The model uses 28-day means, whereas current TwinTrack supplies previous-day/partial-sleep/latest-72-hour measurements. That unresolved input-contract mismatch prevents a drop-in integration approval. Also, a raw-input linear Ridge cannot reproduce the generator's sleep/exercise plateaus or screen neutral zone; future What-If messaging must not claim it does. No coefficients were changed after seeing these results.

This is not a recommendation to remove inputs against A's decision. Keep seven in this candidate. It is a recommendation to review and resolve the contract/interpretation issues before separately authorizing implementation.

## 2. Why seven inputs are retained

A explicitly chose seven as a **product-design constraint** to preserve lifestyle information, academic information and What-If. Exact order: sleep_hours, steps, exercise_minutes, resting_heart_rate, study_minutes, screen_time_minutes, previous_score. The old previous-only/six/seven candidates remain unchanged and are compared, not discarded. The earlier feature-count selection recommendation remains a record of a different decision rule; this pass does not rewrite it.

## 3. Scientific limitation of that product decision

Product inclusion is not evidence of predictive necessity, causal effect or meaningful incremental accuracy. Near-zero or unstable effects are allowed to remain visible. No coefficient was forced to a preferred sign, made equal to others, or enlarged to make What-If exciting. The old .10-point extra-feature rule is not the selection rule here because feature count is fixed by A; under that old rule the small current increment still would not justify extra features. This rule change is explicit and precedes training.

Research status: **NetHealth completed/frozen; HSLS not analyzed against TwinTrack; MCS no completed project participant analysis; COMPASS no completed project participant analysis.** The strategy PDF is planning/literature/dataset-selection evidence, not completed results. MCS's historical plan is unavailable locally. Published studies below are authors' research, not TwinTrack dataset analyses. No HSLS outcomes were inspected. NetHealth was not rerun.

NetHealth saved aggregate: 963 student-semesters from 207 students; prior-only fold MAE .17127, RMSE .23888, R² .52495 on its 0–4 course-grade scale. Added wearable-block fold ΔMAE +.00003 with a student-cluster interval spanning zero. The pooled bootstrap point (−.00006) is a different statistic; neither supports a material increment. Prior standardized coefficient ~.262 versus largest wearable ~.013. Limited cohort/attrition/outcome range prevent universal null claims. **Average daily HR is not resting HR.** No GPA error/effect is converted into test-percentage points. Existing aggregate findings are known development evidence, not a pristine V2 validation set.

## 4. Revised generator design

**EVIDENCE-INFORMED SYNTHETIC DATA**. Keep the earlier proposed population/task: UAE Grade12 (~16–18), a specified comparable same-subject test exactly seven local calendar days after cutoff, score0–100. Previous score is the most recent comparable same-subject result before cutoff, <=90days old. Habits represent 28 completed local-day averages with >=21 observed days each, otherwise abstain. Sleep uses completed noon windows; RHR is daily resting-summary average. Study is deliberate same-subject outside-class time; screen is recreational time excluding study/double counting. These are development assumptions, not verified current-app measurement semantics. Only summary rows, not real timestamps/day trajectories, are simulated.

Latent engagement, fitness and screen preference induce dependence. Bounded Gaussian sleep, skewed lognormal study/screen, Gamma exercise and Beta prior performance replace independent normal marginals. Prior score is weakly coupled to engagement. Steps include exercise-linked and independent incidental components; less coupling and greater incidental variation reduce the prior simulation's excessive overlap. RHR depends on fitness/sleep with noise. Daily-average time budget requires `60*sleep + study + screen + exercise <=960` minutes after reserving300 school and180 other; steps overlap activity. Measurement noise and outcome noise are separate; missingness retains nulls and includes shared/behavior-dependent failures.

Central hypothetical latent target before output clipping:

`72 + .8*(previous−72) + .5*(min(sleep,8.5)−7.5) + .00003*(steps−7000) + .003*(min(exercise,60)−35) − .03*(RHR−70) + .015*180*(log1p(study/90)−log(2)) − .004*(max(screen−120,0)−90) + Normal(0,8)`.

Target is clipped0–100. Inputs are observed noisy versions of these latent variables, then bounds/time constrained. No generator numerical slope is estimated from real students. Nonlinear forms implement bounded/diminishing *hypotheses*, not discovered curves. Exact8.5h/60m/120m/90m choices are not academic or medical thresholds. Alternative caps, linear/null/doubled effects and reversed sleep are stress-tested without changing the exported candidate. Screen is specifically recreational, and even this definition does not establish every high-use minute is harmful in real life.

Across60,000 synthetic development rows: steps/exercise correlation **0.538939**, study/screen **-0.329469**, sleep/screen **-0.440094**. These are assumed-data summaries, not empirical adolescent calibration. V1 generated inputs independently; earlier V2 steps/exercise correlation was ~.887. No attempt was made to force a match to NetHealth's .636 in a different cohort.

## 5. Full assumption/evidence ledger

| Feature | Evidence / expected direction | Prior-attainment adjustment / causal limits | Central numeric hypothesis and tested range | Confidence in transferable magnitude |
| --- | --- | --- | --- | --- |
| previous_score | Saved NetHealth strongly positive; prior performance dominates | Baseline predictor, not a manipulable habit | .8 point/point; stress .55 and .95; Beta distribution and regression-to-mean are assumed | Priority moderate; exact slope low |
| study_minutes | Positive effort effect plausible; context-specific college IV evidence | Some causal inference under IV assumptions; no compatible seven-input UAE estimate | .015 times centered `180*log1p(study/90)`; local slope .015 at 90; null/double/linear/alternative-scale stresses | Low |
| sleep_hours | Positive college wearable associations, mixed adolescent compositional results | Prior-GPA-adjusted evidence exists; NetHealth increment small; mostly observational | +.5 point/hour below assumed 8.5h cap, 0 above; null/double/opposite direction; cap9 and linear stresses | Low |
| screen_time_minutes | Mixed activity/content-dependent associations; some negative media findings | Some baseline-grade-adjusted longitudinal evidence; not causal point-scale effect | −.004 point/min above assumed recreational120m neutral zone; no effect below; null/double/threshold240/linear stresses | Low |
| steps | Weak direct academic evidence; activity overlap | NetHealth wearable block adds little; no separate transferable causal step effect | +.00003 point/step; null/double (0 to .00006); alternative activity coupling | Very low |
| exercise_minutes | Prior-adjusted COMPASS effects near zero; wellbeing does not imply grades | MVPA/Apple exercise constructs differ; no compatible causal estimate | +.003 point/min below assumed60m cap, 0 above; null/double/cap90/linear stresses | Very low |
| resting_heart_rate | Limited/mixed college findings; small negative association possible | No compatible prior-adjusted incremental prediction established; NetHealth average HR is not RHR | −.03 point/bpm; refit and transport at 0, −.06, +.03; central +5bpm = −.15 assumed latent points | Very low |

These ranges are **DEVELOPMENT ASSUMPTIONS for sensitivity testing**, not published confidence intervals or estimated plausible-effect bounds. No incompatible correlation, standardized beta, odds ratio, intervention effect or GPA slope is converted into assessment points.

Primary-source context (focused review, not systematic evidence grading):

- [Okano et al. 2019](https://www.nature.com/articles/s41539-019-0055-z): college wearable sleep over preceding weeks/months associated with grades; the single night before a test did not explain performance. Supports accumulated exposure rather than a one-day scientific forecast.
- [Creswell et al. 2023](https://doi.org/10.1073/pnas.2209123120): college sleep association with later GPA accounting for prior GPA. This does not establish an 8.5-hour academic plateau or UAE test-point effect.
- [Stinebrickner & Stinebrickner](https://www.nber.org/papers/w13341): a college natural experiment/IV study supports a role for study effort under its identification assumptions. It does not estimate our logarithmic scale or an adolescent minutes-to-score equation.
- [Papasideris et al. 2021, COMPASS](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0253142): adolescent activity associations were near zero with corresponding prior grades controlled. [Correction](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0259618) concerns references. This is external research, not TwinTrack analysis.
- [Maloney et al. 2026, MCS](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0346302): mixed time-substitution associations, including an adverse sleep association. Listed adjustments do not establish prior-attainment control. No recommendation to reduce sleep or imported compositional coefficient follows.
- [Poulain et al. 2018](https://link.springer.com/article/10.1186/s12889-018-5489-3): some longitudinal screen/subject associations after baseline grade adjustment; exposure categories differ from recreational minutes. Our neutral threshold is not estimated by that paper.
- [Tharion et al. 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10660775/): small resting-ECG college study did not establish an overall RHR association; HRV subgroup findings are not RHR grade coefficients.
- [Benítez-Agudelo et al. 2025](https://link.springer.com/article/10.1186/s40359-025-03041-z): negative end-semester RHR association in a small university cohort; compatible incremental prediction beyond prior attainment is not established. Its coefficient is not imported or rescaled.


The complete ledger is reproduced below and also saved separately as [ASSUMPTION_LEDGER.md](../ml/v2/2026-09-21-seven-input/ASSUMPTION_LEDGER.md). PUBLISHED EVIDENCE motivates possibilities; all chosen target magnitudes and distribution parameters remain DEVELOPMENT ASSUMPTIONS. Real forecast accuracy/causal dose response remain UNKNOWN.

| Parameter / relationship | Chosen value/range | Source | Evidence type | Confidence | Notes |
| --- | --- | --- | --- | --- | --- |
| version | "2.0-seven-input.1" | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| seeds | [2101, 2102, 2103, 2104, 2105, 2106, 2107, 2108, 2109, 2110] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| rows_per_seed | 6000 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| holdout_fraction | 0.25 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| pooled_cv_seed | 2201 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| final_seed | 98001 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| final_rows | 4000 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| old_generator_seed | 98002 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| missingness_seed | 98003 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| cv_folds | 5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| alpha_grid | [0.1, 1, 10, 100, 1000] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| bootstrap_replicates | 2000 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| bootstrap_seed | 78223 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| bounds.sleep_hours | [5, 10] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| bounds.steps | [1000, 18000] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| bounds.exercise_minutes | [0, 120] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| bounds.resting_heart_rate | [45, 100] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| bounds.study_minutes | [0, 300] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| bounds.screen_time_minutes | [0, 480] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| bounds.previous_score | [0, 100] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference. |
| reference.sleep_hours | 7.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| reference.steps | 7000 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| reference.exercise_minutes | 35 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| reference.resting_heart_rate | 70 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| reference.study_minutes | 90 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| reference.screen_time_minutes | 210 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| reference.previous_score | 72 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Centering/probe profile, not an optimum or training mean. |
| generator.latent_factors | "independent standard-normal engagement, fitness, screen preference" | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.sleep.mean | 7.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.sleep.screen_loading | -0.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.sleep.engagement_loading | 0.2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.sleep.noise_sd | 0.7 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.study.median | 75 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.study.engagement_loading | 0.35 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.study.screen_loading | -0.15 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.study.log_noise_sd | 0.4 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.study.zero_probability | 0.05 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.screen.median | 210 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.screen.preference_loading | 0.35 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.screen.engagement_loading | -0.15 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.screen.log_noise_sd | 0.35 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.exercise.gamma_shape | 2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.exercise.gamma_scale | 18 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.exercise.fitness_loading | 0.25 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.exercise.zero_probability | 0.05 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.time.minutes_per_day | 1440 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.time.school_minutes_daily_average | 300 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.time.other_reserved_minutes | 180 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.steps.base | 2500 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Weaker coupling/more incidental variation than prior V2; no empirical covariance calibration. |
| generator.steps.per_exercise_minute | 50 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Weaker coupling/more incidental variation than prior V2; no empirical covariance calibration. |
| generator.steps.incidental_median | 3000 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Weaker coupling/more incidental variation than prior V2; no empirical covariance calibration. |
| generator.steps.incidental_log_sd | 0.55 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Weaker coupling/more incidental variation than prior V2; no empirical covariance calibration. |
| generator.rhr.mean | 70 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.rhr.fitness_loading | -4 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.rhr.sleep_deficit_loading | 2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.rhr.noise_sd | 5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.previous.beta_a | 9 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.previous.beta_b | 3.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.previous.engagement_loading | 0.25 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation. |
| generator.measurement_sd.sleep_hours | 0.25 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.measurement_sd.steps | 400 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.measurement_sd.exercise_minutes | 5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.measurement_sd.resting_heart_rate | 2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.measurement_sd.study_minutes | 15 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.measurement_sd.screen_time_minutes | 25 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.measurement_sd.previous_score | 2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration. |
| generator.target.mean | 72 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.previous_slope | 0.8 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.outcome_noise_sd | 8 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.habit_coefficients.sleep_hours | 0.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.habit_coefficients.steps | 3e-05 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.habit_coefficients.exercise_minutes | 0.003 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.habit_coefficients.resting_heart_rate | -0.03 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.habit_coefficients.study_minutes | 0.015 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.target.habit_coefficients.screen_time_minutes | -0.004 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects. |
| generator.nonlinear.sleep_cap | 8.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Qualitative bounded-effects hypothesis; exact curve/threshold unsupported empirically; stress-tested, not optimized. Final Ridge remains linear. |
| generator.nonlinear.study_scale | 90 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Qualitative bounded-effects hypothesis; exact curve/threshold unsupported empirically; stress-tested, not optimized. Final Ridge remains linear. |
| generator.nonlinear.study_multiplier | 180 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Qualitative bounded-effects hypothesis; exact curve/threshold unsupported empirically; stress-tested, not optimized. Final Ridge remains linear. |
| generator.nonlinear.exercise_cap | 60 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Qualitative bounded-effects hypothesis; exact curve/threshold unsupported empirically; stress-tested, not optimized. Final Ridge remains linear. |
| generator.nonlinear.screen_neutral_minutes | 120 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Qualitative bounded-effects hypothesis; exact curve/threshold unsupported empirically; stress-tested, not optimized. Final Ridge remains linear. |
| generator.missingness.shared_wearable_failure_probability | 0.08 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.sleep_hours | 0.08 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.steps | 0.02 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.exercise_minutes | 0.06 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.resting_heart_rate | 0.3 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.study_minutes | 0.05 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.screen_time_minutes | 0.05 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.previous_score | 0.02 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.high_screen_threshold | 300 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.high_screen_added_probability | 0.05 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| generator.missingness.low_fitness_added_rhr_probability | 0.1 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero. |
| stress.low_noise_sd | 6 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.high_noise_sd | 12 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.rhr_slopes | [0, -0.06, 0.03] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.double_effect_multiplier | 2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_previous_beta | [6, 4] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_sleep_hours | -1 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_screen_minutes | 60 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.previous_slopes | [0.55, 0.95] | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_nonlinear.sleep_cap | 9 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_nonlinear.study_scale | 180 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_nonlinear.study_multiplier | 270 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_nonlinear.exercise_cap | 90 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.shifted_nonlinear.screen_neutral_minutes | 240 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| stress.measurement_multiplier | 2 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients. |
| increments.sleep_hours | 1 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| increments.steps | 2000 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| increments.exercise_minutes | 30 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| increments.resting_heart_rate | 5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| increments.study_minutes | 30 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| increments.screen_time_minutes | 60 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| increments.previous_score | 10 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Predeclared engineering/reproducibility choice, not an empirical estimate. |
| acceptance.sign_fraction | 0.8 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Prototype review policy, not scientifically validated clinical/educational threshold. |
| acceptance.weak_increment_max | 0.5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Prototype review policy, not scientifically validated clinical/educational threshold. |
| acceptance.raw_corner_min | -5 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Prototype review policy, not scientifically validated clinical/educational threshold. |
| acceptance.raw_corner_max | 105 | config.json / pre-run PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low scientific / explicit policy | Prototype review policy, not scientifically validated clinical/educational threshold. |
| Population/task | Grade12 UAE ~16–18; same subject; one test seven local days later; percentage0–100 | PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low transport evidence | Not a validated current-app task. |
| Prior-score age/definition | Comparable same-subject assessment before cutoff; <=90days | PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low | Metadata validation is not implemented by numeric prediction helper. |
| Habit window/coverage | 28 completed local days; >=21observed days each; available-day mean | PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low | No day-level simulation; observed-day selection can bias averages. |
| Habit constructs | Noon-window sleep; daily steps/exercise/resting-HR summaries; deliberate same-subject study; recreational screen excluding study | PROTOCOL.md | DEVELOPMENT ASSUMPTION | Low | Current single-day/72-hour app semantics differ; no silent substitution. |
| Latent factors/dependence | Independent N(0,1) engagement,fitness,screen preference; Gaussian copula normalizes prior loading by sqrt(1-loading²) | generator.py | DEVELOPMENT ASSUMPTION | Low | No latent participant traits estimated. |
| Time allocation | 60min/hour; proportional reduction of study/screen/exercise when daily-average budget exceeded | generator.py | DEVELOPMENT ASSUMPTION | Units exact; allocation low | School300/other180 reserved; steps overlap activity. Not a full day composition or DST duration simulation. |
| Clipping/measurement order | Latent bounds/time -> steps/RHR -> bounds -> Gaussian measurement noise -> bounds/time; latent target + Gaussian outcome error -> [0,100] | generator.py | DEVELOPMENT ASSUMPTION | Low | Clipping can introduce masses and error dependence; observed summaries need not equal latent targets. |
| Old coupling stress | 70 steps/exercise minute; incidental median2000/logSD.35 | Prior V2 config, generator.py | DEVELOPMENT ASSUMPTION | Low | Tests previous strongly coupled structure without fitting to NetHealth r=.636. |
| Output/input handling | Float64 StandardScaler/Ridge; output clamp0–100; reject missing/nonfinite/out-of-support/time-infeasible required inputs | train.py | DEVELOPMENT ASSUMPTION | High computational | No test-trained preprocessing. Seven raw features; no nonlinear inference transforms. |
| Export tolerances | 1e-10 JSON/pipeline; 1e-9 time comparison; 1e-10 SD threshold for undefined calibration slope; V1 original1e-6 golden tolerance | train.py / evaluate.py | DEVELOPMENT ASSUMPTION | Engineering | No physical/real-data validation follows. |
| Uncertainty/calibration | Paired row bootstrap95% at2.5/97.5 quantiles; OLS actual~prediction; ten rank bins | evaluate.py | DEVELOPMENT ASSUMPTION | Conditional synthetic only | No school/student clusters or biological parameter uncertainty in intervals; mean slope undefined. |
| Pooled artifact versus stability | 45000training rows pooled; 15000holdouts excluded; stability=ten independent4500-row fits | PROTOCOL.md | DEVELOPMENT ASSUMPTION | Reproducible selection | Synthetic sample size reduces simulation error, not real evidence uncertainty. |
| Prior-score generator slope | .8 central vs .55/.95 stress | config.json / V1 formula reference | DEVELOPMENT ASSUMPTION | Unknown real slope | V1 uses .55; neither .55 nor .8 can be called empirically correct for this task. |
| NetHealth result | 963student-semesters/207students; wearable block ΔMAE+.00003 in GPA units, interval covers zero | Frozen local aggregate report | EMPIRICALLY ESTIMATED | Moderate within that cohort | Not rerun; known development evidence; average HR ≠RHR; no point-scale conversion. |
| External direction evidence | Context-dependent sleep/study/screen effects; weak activity and mixed RHR evidence | Primary sources in report | PUBLISHED EVIDENCE | Varies by construct | No transferable seven-feature coefficient vector or nonlinear curve established. |
| Real accuracy/causal dose response | UNKNOWN | No compatible outcome evaluation | UNKNOWN | Unknown | No UAE participant analysis, HSLS outcome inspection, or MCS/COMPASS analysis performed. |


## 6. Ridge training procedure

Protocol/config written before any training. Ten seeds2101–2110, 6,000 rows each; 4,500 training and1,500 development holdout per seed. Each fits previous-only, six-input and seven-input pipelines with training-only shuffled five-fold CV, alpha[.1,1,10,100,1000], MAE criterion. StandardScaler is fitted inside each fold, population SD; Ridge intercept is unpenalized. Original seven raw inputs, no nonlinear inference feature transforms, sign constraints or hand edits.

Final artifact uses **all45,000 training rows**, excluding all15,000 development holdout rows; fresh five-fold training-only CV seed2201. Pooling was fixed before results to reduce simulation sampling noise, not to select pretty signs. Ten seed fits measure stability; pooled coefficients are reported separately. Final evaluation uses4,000 new synthetic rows seed98001; previous-generator transport uses new seed98002, not its already-used final test. Every candidate scores identical rows within each scenario. Synthetic rows lack real school/student dependence.

Matched new previous-only/six baselines share the same45,000 training pool and procedure. Preserved `old_*` candidates retain their old generator and4,500-row training, so differences against them combine generator/sample-size changes; they cannot isolate RHR's increment. The new matched six comparison does isolate the added input under this assumed world. No complex model search.

## 7. Selected alpha

Final seven-input alpha: **0.1**, selected by training-pool CV. Every per-seed and alternative-RHR selection is recorded in `training_cv.csv`; there is no test-based alpha selection. The earlier V1 alpha10 remains unchanged. Alpha values are not directly comparable independent of sample size/scaling; they are regularization settings, not effect sizes.

## 8. Final coefficients

The following table gives full-precision fitted parameters in exact feature order. Standardized formula is `intercept + sum(coef[i]*(x[i]−mean[i])/scale[i])`, followed by output clamp0–100. No manual coefficients are written into production.

| feature | mean | scale | standardized | raw |
| --- | --- | --- | --- | --- |
| sleep_hours | 7.50380621027999783 | 0.90840134223520119 | 0.40592145884587177 | 0.44685255291132270 |
| steps | 7698.37400594138216547 | 2436.46852294075870304 | 0.05001731148976180 | 0.00002052860975581 |
| exercise_minutes | 34.52263091389111338 | 26.83191186017345231 | 0.00802758828378000 | 0.00029918062960300 |
| resting_heart_rate | 70.01946419491873996 | 6.90603223143310796 | -0.18426781736579290 | -0.02668215426610520 |
| study_minutes | 81.90590953624725046 | 52.40397567581751304 | 0.73161765736419249 | 0.01396110978087120 |
| screen_time_minutes | 228.52134518672286845 | 106.45221823308600051 | -0.41872202578037693 | -0.00393342696592330 |
| previous_score | 72.01685042736114895 | 12.34292482717834183 | 9.58483852177060847 | 0.77654515894526055 |

Standardized intercept: **71.641848736886516**. Equivalent raw intercept: **13.819696567231965**. Full precision and metadata: `new_ridge_seven_parameters.json`; serialized sklearn pipeline: `seven_input_model.joblib`. Rounded display coefficients must not be used for integration parity.

## 9. Original-unit sensitivities

Model changes in predicted assessment points, holding other inputs fixed within support. These are **not causal promises**, and adding time can require reducing another activity.

| feature | increment | effect |
| --- | --- | --- |
| sleep_hours | 1 | 0.446852553 |
| steps | 2000 | 0.041057220 |
| exercise_minutes | 30 | 0.008975419 |
| resting_heart_rate | 5 | -0.133410771 |
| study_minutes | 30 | 0.418833293 |
| screen_time_minutes | 60 | -0.236005618 |
| previous_score | 10 | 7.765451589 |

Previous score remains by far the strongest standardized feature in all ten fits; do not weaken it to improve appearance. The central generator's .8 prior slope produces regression toward72; V1's .55 is also a synthetic choice. No compatible real data establishes whether either retention slope is correct. Prespecified .55/.95 transport stresses quantify sensitivity to that uncertainty.

## 10. Multi-seed coefficient stability

Ten independent4,500-row seven-input fits; standardized coefficient mean/sample SD/min/max and sign fractions. Sign fractions are proportions of synthetic fits, not probabilities of a real effect. All raw/effect statistics and six-input controls appear in `coefficient_stability.csv` and [RESULT_TABLES.md](../ml/v2/2026-09-21-seven-input/RESULT_TABLES.md).

| feature | standardized_mean | standardized_std | standardized_min | standardized_max | positive_fraction | negative_fraction |
| --- | --- | --- | --- | --- | --- | --- |
| sleep_hours | 0.403317 | 0.153814 | 0.216328 | 0.597447 | 1.000000 | 0.000000 |
| steps | 0.049591 | 0.107711 | -0.134978 | 0.171396 | 0.600000 | 0.400000 |
| exercise_minutes | 0.008495 | 0.125380 | -0.161202 | 0.202231 | 0.500000 | 0.500000 |
| resting_heart_rate | -0.183386 | 0.124335 | -0.336040 | -0.003077 | 0.000000 | 1.000000 |
| study_minutes | 0.734551 | 0.097872 | 0.591208 | 0.873315 | 1.000000 | 0.000000 |
| screen_time_minutes | -0.418633 | 0.096735 | -0.518546 | -0.206905 | 0.000000 | 1.000000 |
| previous_score | 9.559003 | 0.200506 | 9.288970 | 9.946204 | 1.000000 | 0.000000 |

Sleep/study/prior are positive10/10; screen negative10/10; RHR negative10/10 conditional on the central assumption. **Steps positive6/10, exercise positive5/10: unstable and effectively tiny.** Their maximum tested increment magnitude across seeds remains below the predeclared .5-point weak-effect threshold, which allows prototype review but does not establish stable directional advice. Never recommend less exercise when a seed gives a negative coefficient. Pooling narrows Monte Carlo error; it cannot resolve scientific uncertainty about effects.

## 11. Comparison with previous-score-only

Common central cohort, n4,000, all raw outputs; calibration regresses actual on predicted, bias is prediction−actual. Mean-only slope/intercept are undefined. Raw/clamped metrics are separately retained for every scenario in CSV.

| model | mae | rmse | r2 | bias | calibration_slope | calibration_intercept |
| --- | --- | --- | --- | --- | --- | --- |
| v1_frozen | 7.960147 | 9.987747 | 0.386848 | -4.473895 | 1.244163 | -11.903779 |
| old_previous_only | 6.533275 | 8.231206 | 0.583552 | -0.030908 | 0.998580 | 0.132454 |
| old_ridge_six | 6.478037 | 8.187411 | 0.587972 | 0.085945 | 0.998626 | 0.012453 |
| old_ridge_seven | 6.476617 | 8.184249 | 0.588290 | 0.084305 | 0.998792 | 0.002223 |
| mean_only | 10.241664 | 12.755410 | -0.000051 | 0.091222 | undefined | undefined |
| new_previous_only | 6.534778 | 8.231582 | 0.583514 | 0.063317 | 1.005953 | -0.489661 |
| new_ridge_six | 6.468564 | 8.172888 | 0.589433 | 0.049267 | 1.005575 | -0.448441 |
| new_ridge_seven | 6.466306 | 8.168088 | 0.589915 | 0.047739 | 1.005570 | -0.446513 |

Paired bootstrap differences (new seven minus comparator; negative means lower MAE):

| new_seven_minus | MAE difference | 95% lower | 95% upper |
| --- | --- | --- | --- |
| new_previous_only | -0.068472 | -0.104178 | -0.033386 |
| new_ridge_six | -0.002257 | -0.007724 | 0.003412 |
| old_previous_only | -0.066968 | -0.101897 | -0.031686 |
| old_ridge_six | -0.011730 | -0.025885 | 0.002785 |
| v1_frozen | -1.493841 | -1.637874 | -1.344452 |

The matched prior-only increment is about0.0685 MAE points. It is small even though its conditional sampling interval is below zero. The old .10-point rule would still favor simpler input selection; A's new constraint retains seven for product reasons. Bootstrap uncertainty covers simulated rows, not the uncertain target equation. The final cohort has now informed this review and is not untouched evidence for later iterations.

## 12. Comparison with six-input V2

Preserved old-six and matched new-six are both included. Seven's improvement versus the matched six is only about0.00226 MAE points and its interval crosses zero: **no established meaningful incremental RHR accuracy**. Do not credit seven for comparisons against a smaller, differently trained old-six alone. Synthetic missingness coverage and same complete-seven cohort errors are in `missingness_coverage.csv`; comparing own-eligible errors across different samples would be misleading. All seven remain required under this candidate, so missing RHR still causes abstention; no fake zero or optional-input substitution is proposed.

| model | n | coverage |
| --- | --- | --- |
| v1_frozen | 1627 | 0.406750 |
| old_previous_only | 3881 | 0.970250 |
| old_ridge_six | 2536 | 0.634000 |
| old_ridge_seven | 1627 | 0.406750 |
| mean_only | 4000 | 1.000000 |
| new_previous_only | 3881 | 0.970250 |
| new_ridge_six | 2536 | 0.634000 |
| new_ridge_seven | 1627 | 0.406750 |

These coverage rates are assumed-device/missingness simulations, not observations from TwinTrack users.

## 13. Comparison with frozen V1

V1 remains frozen. Reconfirmed original audit: alpha10, MAE4.76146176524888, RMSE5.868372602783463, R².5704285621846623 on its original200-row synthetic holdout. The old prior-only OLS R² was.5496868479533286. Those are different-generator metrics, not a scorecard against new V2's MAE. On the common new scenario V1 underpredicts partly because its imposed task/target relationship differs. The common table is transport testing, not proof of better real grades.

All stress/transport MAEs for fixed candidates:

| scenario | mean_only | new_previous_only | new_ridge_seven | new_ridge_six | old_previous_only | old_ridge_seven | old_ridge_six | v1_frozen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| central | 10.241664 | 6.534778 | 6.466306 | 6.468564 | 6.533275 | 6.476617 | 6.478037 | 7.960147 |
| double_habits | 10.469667 | 6.775306 | 6.569404 | 6.574848 | 6.769830 | 6.592723 | 6.595779 | 7.782926 |
| high_noise | 12.299841 | 9.496220 | 9.457407 | 9.458655 | 9.493976 | 9.463519 | 9.464420 | 10.504056 |
| linear | 10.254197 | 6.539279 | 6.460252 | 6.461586 | 6.539297 | 6.472450 | 6.473531 | 8.012290 |
| low_noise | 9.367777 | 5.025919 | 4.934422 | 4.938062 | 5.025024 | 4.947432 | 4.950105 | 6.811205 |
| measurement_double | 10.241664 | 6.879720 | 6.822998 | 6.826996 | 6.883828 | 6.836430 | 6.838566 | 8.147200 |
| null_habits | 10.104170 | 6.449451 | 6.533993 | 6.533540 | 6.452839 | 6.529413 | 6.529179 | 8.267157 |
| opposite_sleep | 10.197443 | 6.491056 | 6.490541 | 6.492114 | 6.490458 | 6.490750 | 6.492317 | 8.052867 |
| population_shift | 14.375821 | 6.595383 | 6.489049 | 6.492076 | 6.578144 | 6.499150 | 6.500991 | 7.455870 |
| previous_generator_transport | 10.089335 | 6.493047 | 6.434420 | 6.426746 | 6.497978 | 6.435186 | 6.431380 | 8.111769 |
| previous_high | 11.418618 | 6.754428 | 6.696573 | 6.698656 | 6.741648 | 6.694970 | 6.696695 | 8.529259 |
| previous_low | 8.467447 | 6.860704 | 6.800257 | 6.801806 | 6.877949 | 6.823810 | 6.824730 | 7.578913 |
| rhr_negative | 10.252481 | 6.543569 | 6.468674 | 6.474314 | 6.541939 | 6.481489 | 6.484748 | 7.962834 |
| rhr_null | 10.234460 | 6.528910 | 6.468540 | 6.466827 | 6.527457 | 6.475554 | 6.475224 | 7.959995 |
| rhr_positive | 10.229575 | 6.527673 | 6.474058 | 6.469510 | 6.525921 | 6.478298 | 6.476262 | 7.962567 |
| shifted_caps | 10.229927 | 6.518892 | 6.464859 | 6.467153 | 6.517526 | 6.472483 | 6.473918 | 7.971091 |
| strong_activity_coupling | 10.242349 | 6.535684 | 6.466608 | 6.468865 | 6.534110 | 6.466816 | 6.468144 | 8.037621 |

Null effects, higher noise, prior-retention shifts, changed measurement error, old activity coupling and opposite RHR/sleep assumptions expose dependence on unvalidated design choices. Models are not re-tuned on these final stress outcomes. Separate RHR refits below answer a different question: what if the assumed training signal changes?

## 14. RHR interpretation

Keep RHR as A requested, with a small fitted coefficient. Pooled +5bpm gives approximately−.1334 predicted points. Central sign stability10/10 is a conditional numerical result, **not new real-world evidence**. Refitting the same seed designs under changed RHR target assumptions yields:

| scenario | raw_mean | raw_std | raw_min | raw_max | negative_fraction |
| --- | --- | --- | --- | --- | --- |
| central | -0.026704 | 0.018325 | -0.050192 | -0.000444 | 1.000000 |
| rhr_negative | -0.053660 | 0.018346 | -0.077337 | -0.027564 | 1.000000 |
| rhr_null | 0.000271 | 0.018317 | -0.023042 | 0.026685 | 0.500000 |
| rhr_positive | 0.027252 | 0.018314 | 0.004109 | 0.053781 | 0.000000 |

With zero assumed direct RHR effect, signs split5/5; with positive signal all turn positive. This demonstrates dependence on the chosen effect rather than confirmation of physiology. NetHealth cannot calibrate this because its HR is not resting HR. RHR may chiefly serve wellbeing context even while retained in the prediction schema. No attempt was made to enlarge its academic coefficient to make it useful visually.

## 15. What-If behavior

All reported single-input raw changes are constant across ordinary profiles because raw-input Ridge is linear. Output clamping can flatten changes at boundaries. The tested final profiles for each increment are filtered by bounds/joint time feasibility. The generator-change column is a diagnostic of an assumed nonlinear equation on the same numeric profiles, not an empirical counterfactual effect.

| feature | increment | feasible_profiles | raw_delta_mean | raw_delta_min | raw_delta_max | clamped_delta_min | clamped_delta_max | hypothetical_generator_delta_min | hypothetical_generator_delta_max | surrogate_delta_mae |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sleep_hours | 1 | 3119 | 0.446853 | 0.446853 | 0.446853 | 0.446853 | 0.446853 | 0.000000 | 0.500000 | 0.135588 |
| steps | 2000 | 3969 | 0.041057 | 0.041057 | 0.041057 | 0.041057 | 0.041057 | 0.060000 | 0.060000 | 0.018943 |
| exercise_minutes | 30 | 3373 | 0.008975 | 0.008975 | 0.008975 | 0.008975 | 0.008975 | 0.000000 | 0.090000 | 0.060980 |
| resting_heart_rate | 5 | 3999 | -0.133411 | -0.133411 | -0.133411 | -0.133411 | -0.133411 | -0.150000 | -0.150000 | 0.016589 |
| study_minutes | 30 | 3492 | 0.418833 | 0.418833 | 0.418833 | 0.418833 | 0.418833 | 0.220278 | 0.776742 | 0.100525 |
| screen_time_minutes | 60 | 3195 | -0.236006 | -0.236006 | -0.236006 | -0.236006 | -0.236006 | -0.240000 | 0.000000 | 0.025610 |
| previous_score | 10 | 3806 | 7.765452 | 7.765452 | 7.765452 | 7.765452 | 7.765452 | 8.000000 | 8.000000 | 0.234548 |

Important limitation: the exported model still adds ~.447 points for sleep9→10h although the generator plateaus; still gives a small exercise effect above60m and a screen penalty below120m. Nonlinear training targets do not make linear inference nonlinear. Do not state that the model enforces saturation or a harmless-screen threshold. Modifying inference transforms would require a different model/export and is not smuggled into this seven-raw-input pass.

Research support: sleep5–10h; steps1,000–18,000; exercise0–120m; RHR45–100bpm; study0–300m; screen0–480m; prior0–100. These are engineering limits, not recommended health targets. Reject unsupported values and impossible time budgets; no inference input clamping. Prior score should remain fixed during habit What-If. Steps/exercise overlap and time displacement make independent slider interventions noncausal. A change to a28-day mean does not represent one day's action. Near-zero steps/exercise deltas may round to0.0 in the app; do not amplify them for appearance.

## 16. Extreme-case testing

Every candidate evaluated at all128 seven-dimensional bound corners; time-infeasible profiles are marked rejected, not silently accepted. The prior-only/mean corners include duplicate effective inputs. Full per-profile results retained; these probes are numerical stress tests, not likely student profiles.

| model | permitted | count | min | max |
| --- | --- | --- | --- | --- |
| mean_only | True | 128 | 71.641849 | 71.641849 |
| new_previous_only | True | 128 | 14.815428 | 93.722545 |
| new_ridge_seven | False | 56 | 13.752490 | 99.335791 |
| new_ridge_seven | True | 72 | 11.518228 | 99.299889 |
| new_ridge_six | False | 56 | 14.635475 | 98.890464 |
| new_ridge_six | True | 72 | 12.159407 | 98.714348 |
| old_previous_only | True | 128 | 14.301821 | 93.791562 |
| old_ridge_seven | False | 56 | 11.615548 | 99.750744 |
| old_ridge_seven | True | 72 | 9.416931 | 101.204801 |
| old_ridge_six | False | 56 | 12.245705 | 99.389694 |
| old_ridge_six | True | 72 | 9.880678 | 100.851388 |
| v1_frozen | False | 56 | 21.873035 | 100.364455 |
| v1_frozen | True | 72 | 17.449332 | 97.130240 |

The new seven candidate passes the predeclared raw-corner [-5,105] engineering guard; output remains0–100 after clamp. Rare combinations and low prior-score tails can still be outside empirical training support despite passing bounds. Missing/nonfinite/out-of-range values are rejected. JSON, raw-equivalent arithmetic and serialized pipeline agree to1e-10. Python V1 parity remains21/21; no new Swift or device run is claimed. See [VALIDATION.md](../ml/v2/2026-09-21-seven-input/VALIDATION.md).

## 17. Known limitations

No compatible UAE real dataset, representative calibration, causal validation or prospective forecast evaluation. Every new row is synthetic. No independent completed HSLS/MCS/COMPASS TwinTrack result exists. NetHealth is known development evidence; underlying referenced result tables were not independently recomputed. No formal systematic review or power/fairness claim. Prior-score dominance is evidence-informed qualitatively, but its numerical slope is still assumed.

The nonlinear shapes/thresholds, means, loadings, time budget, errors and missingness rates are not fitted to target-population data. No individual daily records, school clustering, repeat students, socioeconomic confounding, adaptive study response or real assessment difficulty are modeled. Measurement-noise assumptions affect fitted coefficients. Seven inputs may provide useful product context without meaningful academic improvement. Steps/exercise lack stable signs; RHR's stable direction follows the central assumed signal. Synthetic interval precision does not repair those limitations.

**Blocking integration issue:** current app sleep/steps/exercise/RHR timing is not this28-day summary contract, and manual entries lack this study/screen period plus subject/date comparability metadata. Seven identical field names do not make semantics identical. No permission to change HealthKit semantics or UI is inferred. A must choose and explicitly approve the measurement contract before any integration. Review linear What-If limitations at the same time. This task stops at a candidate, not a live replacement.

## 18. Presentation-safe claims

- Seven inputs were retained as an explicit product constraint, with modest fitted lifestyle effects and dominant prior attainment.
- A documented correlated synthetic generator includes bounded target hypotheses, time constraints, measurement noise and missingness.
- Across ten central-assumption fits, RHR was small/negative; null/opposite-signal refits show that this is assumption-dependent. Steps/exercise were tiny and unstable.
- Eight candidates were compared on common synthetic cohorts, including preserved earlier artifacts and matched newly trained baselines.
- Numerical reproducibility and parity establish implementation consistency, not real academic accuracy or causality.

## 19. Claims TwinTrack must NOT make

- “Seven inputs are all scientifically necessary,” “RHR reliably improves real grade forecasts,” or “the coefficient sign proves a biological mechanism.”
- “V2 has real UAE prediction error6.47” or “new synthetic MAE proves superiority to V1.”
- “Changing sleep/study/RHR by this amount causes this grade gain.”
- “The fitted linear model implements the generator's nonlinear plateaus.”
- “HSLS/MCS/COMPASS have been validated against TwinTrack,” or “NetHealth average HR estimates resting-HR effects.”
- “These exact distributions, thresholds, slopes or missingness rates were estimated from compatible real students.”
- “V2 is integrated, independently Swift-parity verified, approved for a drop-in deployment, or based on private user HealthKit data.”

## 20. Exact proposed Swift integration parameters

Proposed arithmetic only, **not authorization to integrate**. Artifact version `2.0-seven-input.1`; feature order preserved. Use Double throughout, population-SD scaler and output clamp0–100. No generator transformations in inference. Exact arrays:

```json
{
  "features": [
    "sleep_hours",
    "steps",
    "exercise_minutes",
    "resting_heart_rate",
    "study_minutes",
    "screen_time_minutes",
    "previous_score"
  ],
  "mean": [
    7.503806210279998,
    7698.374005941382,
    34.52263091389111,
    70.01946419491874,
    81.90590953624725,
    228.52134518672287,
    72.01685042736115
  ],
  "scale": [
    0.9084013422352012,
    2436.4685229407587,
    26.831911860173452,
    6.906032231433108,
    52.40397567581751,
    106.452218233086,
    12.342924827178342
  ],
  "coefficients_standardized": [
    0.4059214588458718,
    0.05001731148976185,
    0.008027588283780076,
    -0.18426781736579292,
    0.7316176573641925,
    -0.4187220257803769,
    9.584838521770608
  ],
  "intercept_standardized": 71.64184873688652,
  "coefficients_raw": [
    0.4468525529113227,
    2.0528609755808444e-05,
    0.000299180629603044,
    -0.0266821542661052,
    0.013961109780871202,
    -0.003933426965923342,
    0.7765451589452605
  ],
  "intercept_raw": 13.819696567231965,
  "alpha": 0.1,
  "output_clamp": [
    0,
    100
  ],
  "task": {
    "population": "UAE Grade12; same subject/comparable assessment",
    "horizon_local_days": 7,
    "habit_window_completed_local_days": 28,
    "minimum_observed_days": 21,
    "maximum_prior_score_age_days": 90
  }
}
```

Before a separately approved port: resolve timing/subject/date/coverage contract; independently audit parameters and generate new V2 Swift golden profiles; retain V1 predictor/artifacts for rollback and immutable history; version model/task provenance in snapshots/tools; preserve real-baseline/What-If isolation; align missingness and input bounds; document experimental/noncausal status. Then run full app regressions and A's physical review. None of those production changes occurred here.

**Final recommendation: DO NOT APPROVE FOR IOS INTEGRATION yet.** Seven-input research candidate and required artifacts are ready for A's review; input-window compatibility and What-If interpretation remain unresolved. Exact files/hashes: [FILE_INVENTORY.md](../ml/v2/2026-09-21-seven-input/FILE_INVENTORY.md). Prior V1, prior V2 and all iOS files are preserved. Nothing staged, committed or pushed.
