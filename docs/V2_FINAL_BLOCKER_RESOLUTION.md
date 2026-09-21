# TwinTrack — final V2 blocker resolution

2026-09-21 · candidate **2.0-final.1** · **APPROVE FOR IOS INTEGRATION** of the specification below.

This approves implementing an explicitly **experimental** seven-input design. It does not approve release, claim real-student accuracy, or imply the current V1 app already implements the new manual/target contract. No production Swift was edited. The parameter artifact correctly retains `deployment_approved: false`; build, integration parity and physical review are future gates.

## 1. Final target definition

**Experimental predicted percentage score, 0–100, for the student's next scheduled individually graded written quiz, test or exam in a selected subject.** Suggested compact label: “Experimental next-assessment estimate.” The student selects the subject and identifies its next assessment; TwinTrack cannot infer an unseen school calendar. Subject names are local metadata, not student/school identifiers or extra Ridge features.

“Next” means the earliest upcoming assessment in that subject, not whichever future assessment produces convenient eligibility. If the next is today or its date is unknown, do not skip it to target a later one. Group projects, coursework, GPA, multi-subject averages and noncomparable grading scales are outside this model's scope. If two eligible assessments share a date, the student identifies which assessment is intended; preserve that target identity in local provenance. No personalized claim of calibration or certainty.

This replaces the aligned candidate's unspecified current-profile score contract. The simulation still supplies hypothetical outcomes, not observed future assessments. Assigning a clear target resolves product semantics; it does not validate the predictor against that target.

## 2. Final prediction horizon

The chosen next assessment must be **1–7 local calendar days after the prediction date**, inclusive. No same-day or >7-day prediction; show that the estimate is available only when the next assessment falls within this window. Recheck dates on each explicit prediction run. Do not silently move the target when time passes, and keep saved predictions historical.

Seven days is a practical product-scope assumption, **not an evidence-proven validity cutoff**. The seven-feature model has no days-to-assessment feature and assumes the same mean relationship across eligible days. It does not predict future habits or learning over those days. A date seven days away is not scientifically as well-supported as one day away simply because both pass this gate. No model interval or guaranteed ±error band follows from synthetic MAE.

## 3. Final meaning of previous_score

Use the most recent completed, individually graded assessment in the **same selected subject**, dated **1–90 local calendar days before the prediction date**. Require same subject in this scoped version rather than silently substituting a different subject “where possible.” If unavailable, ungraded, undated, stale or incomparable, abstain and explain what is missing.

Normalize `100 × points earned / maximum possible points`; maximum must be finite and >0, earned finite and within0…maximum. A40/50 result is80. Require a comparable percentage scale; a percentage conversion does not guarantee equivalent difficulty, so that limitation remains. A student-confirmed already-percentage score may use maximum100. Ninety days is a declared product assumption, not an empirically established decay law.

Prior score, prior date/subject and target identity remain local. Existing undated records require reconfirmation. Preserve old values/history; do not manufacture dates or replace historical scores. Same-day prior results are excluded by this deliberately simple date-only contract to prevent temporal ambiguity. Previous score remains a background predictor, not a habit recommendation.

## 4. Final study_minutes definition

**Total deliberate outside-class study for the selected subject during the previous completed local calendar day**, midnight to midnight, in minutes. Include homework, revision, practice and academic screen time for that subject. Exclude timetabled class time, breaks and studying other subjects. Count elapsed time once; do not add overlapping study sessions. Explicit0 is valid; unknown is missing.

Proposed UI wording: “Study yesterday — [subject]”, with the exact source date and helper “Outside class, including study on screens.” Save the report's local date and subject. At local midnight it becomes an older report; require entry/reconfirmation for the new yesterday. Switching subject invalidates that study report for a new prediction until reconfirmed, without erasing it.

Why this choice:

| Option | Benefit | Reason for final decision |
| --- | --- | --- |
| Today's total | Simple recall | Incomplete and time-of-day dependent; mismatches previous-day activity. Not selected. |
| Previous completed day | One bounded period, short recall, same day as steps/exercise | **Selected** for an understandable, practical source contract. Single-day variability remains a limitation. |
| Recent7-day daily average | Potentially steadier | Requires seven dated entries or error-prone retrospective averaging; adds burden and differs from current HealthKit activity. Not selected. |
| Multi-week average | Better aligned with some longitudinal academic research | Requires more reporting/coverage and a broader app redesign; no precise transferable seven-input equation establishes it as a requirement. Not selected. |

Research distinguishes longer-term habits from one-night/day snapshots: [Okano et al.](https://www.nature.com/articles/s41539-019-0055-z) found college sleep associations over preceding learning periods rather than the single night before a test. That limits claims about this snapshot model; it does not validate yesterday's study minutes as an individual exam predictor.

## 5. Final screen_time_minutes definition

**Total active recreational/non-study screen-use time during the previous completed local calendar day**, in minutes. Include leisure gaming, entertainment and social browsing. Exclude schoolwork and all academic study, including other subjects; academic screen minutes counted in study must not also be leisure. Count simultaneous devices once by elapsed time, not summed device totals. Do not count unattended background playback as active screen use.

Proposed UI wording: “Recreational screen time yesterday”, with exact date; helper “Exclude schoolwork and study. Count overlapping devices once.” This is a manual estimate, not automatically verified Screen Time data. No additional system permission is proposed. If the student cannot separate categories or estimate the period, leave missing rather than fabricate a precise number.

Use the same previous-day choice as study and activity. Both manual numbers must be dated yesterday for a current prediction. Existing generic Screen Time values cannot silently become this newly defined leisure total. No7-day average or “30 minutes more today” interpretation is hidden in training or What-If.

## 6. Final seven-input measurement-window table

The **single proposed contract** below governs future UI, generator, numeric profile, What-If and Methodology. HealthKit definitions were checked against [HealthData.swift](../ios/twintrack/twintrack/HealthData.swift), [HealthKitService.swift](../ios/twintrack/twintrack/HealthKitService.swift), [TwinTrackState.swift](../ios/twintrack/twintrack/TwinTrackState.swift), [ProfileView.swift](../ios/twintrack/twintrack/ProfileView.swift) and [WhatIfScenario.swift](../ios/twintrack/twintrack/WhatIfScenario.swift). Current manual UI still has generic undated values; implementing this contract is required before enabling V2.

| Feature | Source | Final production window | Unit | Aggregation | Missing-data rule | What-If interpretation |
| --- | --- | --- | --- | --- | --- | --- |
| sleep_hours | Existing HealthKit sleepAnalysis | Yesterday local noon → earlier of now/today noon | Hours | Clip and union accessible actual-asleep intervals, including naps in window; no average | No accessible asleep interval→missing; never infer zero from absence | Hypothetical total in that same captured sleep window |
| steps | Existing HealthKit stepCount | Previous completed local calendar day | Count | HealthKit cumulative sum; no manual summing of overlapping sources | No accessible total→missing; accessible0 valid | Hypothetical previous-day step total |
| exercise_minutes | Existing HealthKit appleExerciseTime | Previous completed local calendar day | Minutes | HealthKit cumulative Apple Exercise time | No accessible total→missing; accessible0 valid | Hypothetical previous-day Apple Exercise total |
| resting_heart_rate | Existing HealthKit restingHeartRate | Latest finite-positive sample within preceding72 elapsed hours | bpm | Latest by sample start timestamp; equal timestamp deterministic tie-break | Missing/invalid/stale→unavailable; no substitution from personal median | Hypothetical latest resting sample, not a target to manipulate |
| study_minutes | Manual entry/reconfirmation | Previous completed local calendar day, selected subject | Minutes | Outside-class total, academic screens included, overlaps counted once | Unknown/undated/wrong day/wrong subject→missing; explicit0 valid | Hypothetical study total for that same day/subject |
| screen_time_minutes | Manual entry/reconfirmation | Previous completed local calendar day | Minutes | Active recreational total, study excluded, overlapping devices counted once | Unknown/undated/wrong day→missing; explicit0 valid | Hypothetical leisure total for that same day |
| previous_score | Manual comparable result | Latest same-subject prior assessment1–90 local days old | Percentage points | Earned/max×100; no averaging | Missing/undated/different subject/noncomparable→unavailable | Clearly hypothetical background score; never edits the real prior result |

All seven are required. Preserve current read-denial ambiguity, metric-specific failure handling, shared refresh and explicit Run Prediction. Sleep still intentionally overlaps a different period from yesterday's manual/activity day; RHR retains its timestamp. No28-day mean is mixed in. Calendar days may be23/25 hours; elapsed72-hour RHR stays distinct. The sleep window excludes Awake/In Bed and unions asleep overlaps; it is not Apple's private source-priority algorithm. Current RHR is not ordinary workout/instantaneous heart rate.

## 7. Steps instability diagnosis

The diagnosis reproduces the aligned generator using all ten original seeds, fixed training splits and prespecified layer ablations. [Diagnostic tables](../ml/v2/2026-09-21-final/diagnostics/summary.csv) are explanations of a simulator, not participant research or alternative artifact selection.

- Steps/exercise correlation averages **.572623** (range.554809–.594100); VIF averages **1.490193 for steps**, **1.501923 for exercise**. There is overlap, but not severe multicollinearity.
- Standardized design condition number averages **1.948276** (range1.898632–1.995898), compared with about2092 before scaling. Scaling corrects the unit disparity; pipeline/export checks agree. This is not evidence of a scaling/distribution implementation bug.
- The latent direct steps contribution has SD about **.072846 points**, versus outcome-noise SD **8 points**. Exercise's direct term SD is about **.057823**. Those terms are far smaller than random outcome variation; their conditional residual correlations with the outcome are near zero.
- Source snapshots are noisy proxies for latent usual activity. Shared step/exercise day variation changes how conditional effects are allocated. Removing that shared coupling or dropping exercise does not establish a robust meaningful step effect.

Fixed-alpha central diagnostic means show no sign cure from regularization:

| alpha | feature | mean_effect | min_effect | max_effect | positive_fraction |
| --- | --- | --- | --- | --- | --- |
| 0 | exercise_minutes | -0.0258647012 | -0.145601903 | 0.191389527 | 0.3 |
| 0 | steps | 0.010622343 | -0.108743129 | 0.0721104832 | 0.7 |
| 0.1 | exercise_minutes | -0.025864645 | -0.145599206 | 0.191378093 | 0.3 |
| 0.1 | steps | 0.0106219225 | -0.10873779 | 0.0721070202 | 0.7 |
| 100 | exercise_minutes | -0.0257992084 | -0.142968025 | 0.180500072 | 0.3 |
| 100 | steps | 0.0102136815 | -0.103696328 | 0.0691443072 | 0.7 |
| 1000 | exercise_minutes | -0.0246579429 | -0.123572193 | 0.115303092 | 0.3 |
| 1000 | steps | 0.00740449794 | -0.0749609153 | 0.0690189052 | 0.7 |

Effects above mean points per+2000 steps or+30 exercise minutes. OLS (alpha0), very light Ridge and alpha100/1000 retain the same central sign fractions. Changing alpha just to obtain positivity is unsupported.

## 8. Exercise instability diagnosis and decision rule

The earlier slightly negative pooled exercise estimate is consistent with **weak conditional signal plus outcome noise, proxy error and dependence**, not a demonstrated negative exercise effect on grades. It is not solely caused by including steps: removing steps still leaves a tiny negative diagnostic mean. Under zero direct activity effects, residual associations remain because measured inputs stand in for correlated latent factors. Linear approximation to capped effects contributes additional model misspecification.

Predeclared diagnostic ablations, fixed alpha100, original ten seeds:

| variant | feature | mean_effect | min_effect | max_effect | positive_fraction |
| --- | --- | --- | --- | --- | --- |
| activity_observation_noise_off | exercise_minutes | -0.0215559717 | -0.19643682 | 0.237579706 | 0.3 |
| activity_observation_noise_off | steps | 0.0486176809 | -0.115093609 | 0.268441018 | 0.8 |
| central | exercise_minutes | -0.0257992084 | -0.142968025 | 0.180500072 | 0.3 |
| central | steps | 0.0102136815 | -0.103696328 | 0.0691443072 | 0.7 |
| large_sample | exercise_minutes | 0.0119715762 | -0.0276907978 | 0.123675109 | 0.4 |
| large_sample | steps | 0.0278695001 | -0.0378691299 | 0.058359503 | 0.8 |
| latent_oracle | exercise_minutes | 0.0117565108 | -0.11903076 | 0.234951848 | 0.5 |
| latent_oracle | steps | 0.0506951012 | -0.0884964128 | 0.261824531 | 0.7 |
| no_direct_activity_target | exercise_minutes | -0.0522074872 | -0.171162326 | 0.154289182 | 0.2 |
| no_direct_activity_target | steps | -0.0139625417 | -0.128520176 | 0.0436016848 | 0.6 |
| no_outcome_noise | exercise_minutes | 0.00906632609 | -0.0230081822 | 0.033408045 | 0.6 |
| no_outcome_noise | steps | 0.0213512177 | -1.16939878e-05 | 0.0440559781 | 0.9 |
| no_shared_day_coupling | exercise_minutes | -0.0273161153 | -0.191353201 | 0.113147934 | 0.3 |
| no_shared_day_coupling | steps | 0.0299853903 | -0.0480017439 | 0.111227343 | 0.8 |

Feature omission, diagnosis only (neither feature is removed from the final artifact):

| features | feature | mean_effect | positive_fraction |
| --- | --- | --- | --- |
| seven | exercise_minutes | -0.0257992084 | 0.3 |
| seven | steps | 0.0102136815 | 0.7 |
| without_exercise | steps | 0.000132917429 | 0.6 |
| without_steps | exercise_minutes | -0.0179804604 | 0.3 |

Removing outcome noise changes mean exercise sensitivity from **−.025799** to **+.009066 points/+30min** and narrows its variation. The60000-row/seed diagnostic changes the mean to **+.011972** but is positive in only4/10 seeds. Even a latent-input oracle has very small, variable effects under noisy outcomes. Reducing source activity noise alone does not cure the negative mean. Thus neither “just multicollinearity” nor “just insufficient sample size” fully explains it. These controlled interventions identify contributions within the synthetic system, not human causation.

**Final choice: option A, retain both features fitted and active but effectively tiny.** Do not zero them manually, force signs, adopt unsupported noise reductions, or export a large-N diagnostic model. Published youth activity results can be small/mixed after adjustment; [COMPASS authors' study](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0253142) reports trivial magnitudes. This is literature evidence, not a completed TwinTrack COMPASS analysis or a coefficient source.

Rule fixed in [PROTOCOL.md](../ml/v2/2026-09-21-final/PROTOCOL.md) **before new results**:

1. Pooled absolute effect≤**.10 points** per+2000 steps/+30 exercise minutes.
2. Every central seed absolute effect≤**.50 points** at those increments.
3. Pooled absolute change across each full allowed range≤**1.5 points**.
4. Disclose unstable signs and prohibit causal/optimization advice; explain any persistent tiny negative association.

These are engineering limits for an experimental product, not p-value/clinical/evidence thresholds. The final model passes: steps −.033383/+2000, exercise +.050707/+30min; full-range magnitudes .500747/.304242. Sign uncertainty is accepted under this rule, not hidden. The earlier80% sign rule was explicitly reconsidered as the user requested; it was not silently lowered after seeing a favorable artifact.

## 9. Generator changes and evidence provenance

New version `2.0-final.1` preserves V1, all three earlier V2 versions and their reports. The current aligned source observation mechanism and numerical outcome assumptions remain. Two changes were required by the chosen meanings:

- Manual values now represent dated, non-overlapping previous-day totals, not undated reports. Rebalance study/screen proportionally within a separately simulated previous-day budget after exercise, previous-day sleep and a fixed480-minute reserved block; floor to whole minutes. **14.55%** of central final profiles require this adjustment. This is synthetic plausibility bookkeeping, not modification of real inputs or a universal schedule assumption. Real values outside support must be rejected/abstained, never scaled to fit.
- Add explicit synthetic cutoff/manual/target/prior dates, subject identities, assessment kind and percentage-scale metadata. The target label now represents the prespecified upcoming individual assessment. Dates are sampled1–7 days ahead and prior dates1–90 days back. They are **not new predictors**; the simulation assumes no direct horizon-specific effect. Synthetic subject keys carry no personal information.

Latent target still uses prior slope.8, outcome-noise SD8, RHR coefficient−.03, steps.00003 and exercise.003 below an assumed60-minute cap. Sleep/study/screen hypothetical functions remain unchanged. No effect was enlarged for display. Source-day and recall-noise scales remain development assumptions, not measured teenage HealthKit/manual error. All inherited and new numbers are recorded in [ASSUMPTION_LEDGER.md](../ml/v2/2026-09-21-final/ASSUMPTION_LEDGER.md) and resolved config.

This does not transform synthetic labels into real prospective results. The former latent profile generator supplies distributions; a declared future target and dating contract make the simulation's intended use explicit, not empirically validated. NetHealth remains related completed evidence; no new real-data analysis occurred.

## 10. Retraining and validation procedure

Ten predeclared seeds4101–4110 ×6000 synthetic rows; each75/25 training/holdout. Pool **45,000 training rows**, exclude **15,000 holdouts**. StandardScaler is inside five-fold training-only CV; fixed pooled CV seed4201. Final4000 rows use independent seed100001. No best-seed selection. Three matched mean/prior/six/seven comparisons use the same training pool; six excludes RHR for incremental diagnosis only.

Thirty seed/model fits +three pooled searches +thirty RHR-world refits =**63 CV searches**, each five alphas×five folds. Alternate RHR fits and diagnostic variants never select the artifact. Twenty evaluation cohorts×ten fixed models×raw/clamped =**400 metric rows**,4000 rows/model/cohort. The two doubled-variation scenario names coincide after the inherited measurement-layer replacement; they are not independent evidence.

Fresh tests: **20/20 new +20/20 aligned +59/59 earlier =99/99**, zero failures. Three existing sklearn pickle-version warnings in the earlier suite; no new-suite warnings. V1 frozen JSON parity **21/21**, maximum error **7.105427357601002e−15**, tolerance1e−6. No new Swift parity/build/UI/physical run is claimed.

Main experiment and diagnostics were rerun to fresh directories; all generated outputs must match byte-for-byte as recorded in [VALIDATION.md](../ml/v2/2026-09-21-final/VALIDATION.md). **218 protected files unchanged**, including previous V1/iOS, all prior V2 versions and approved local research. Tests include dates, horizon boundaries, prior normalization, missing/legacy/wrong-subject records, seven-feature identity, manual budget, What-If identity, train-only scaling, exports, all seeds and preservation. Preserved RHR trend tests remain green.

## 11. Final alpha

**0.1**, selected by training-only five-fold CV from [.1,1,10,100,1000]. The previous aligned alpha100 was not forced on the new artifact. Diagnostic fixed-alpha comparisons are a separate experiment and do not change final selection. StandardScaler+Ridge remains the entire numerical predictor.

## 12. Final scaler and intercept

Use the full-precision [parameter JSON](../ml/v2/2026-09-21-final/results/new_ridge_seven_parameters.json), not rounded table values. Standardized formula: `raw = intercept + Σ(coef[i] × (x[i] − mean[i]) / scale[i])`. Apply numeric AND metadata/freshness eligibility first, then clamp model output to0–100.

```json
{
  "model_version": "2.0-final.1",
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
    6.910532056110472,
    7579.6176444444445,
    35.616004765183405,
    70.06224157422614,
    81.225,
    222.69113333333334,
    72.08134473524811
  ],
  "scale": [
    1.8081970678397858,
    3714.3206672528972,
    39.43167004155552,
    6.954209824355679,
    58.99105937437563,
    118.71129985175519,
    12.395571969521258
  ],
  "coefficients_standardized": [
    0.16083873081088637,
    -0.06199779395318764,
    0.0666486658847992,
    -0.3210760453847087,
    0.6148398214983507,
    -0.4997276682425781,
    9.647971997056539
  ],
  "intercept_standardized": 71.70996613127207,
  "coefficients_raw": [
    0.08894977968470934,
    -1.6691556682164727e-05,
    0.0016902318825086722,
    -0.04617002556641393,
    0.010422593322089467,
    -0.004209604889059678,
    0.7783402025158153
  ],
  "intercept_raw": 18.383425705057114,
  "alpha": 0.1,
  "output_clamp": [
    0,
    100
  ]
}
```

## 13. Final seven coefficients

| feature | standardized | raw | increment | effect |
| --- | --- | --- | --- | --- |
| sleep_hours | 0.160838731 | 0.0889497797 | 1 | 0.0889497797 |
| steps | -0.061997794 | -1.66915567e-05 | 2000 | -0.0333831134 |
| exercise_minutes | 0.0666486659 | 0.00169023188 | 30 | 0.0507069565 |
| resting_heart_rate | -0.321076045 | -0.0461700256 | 5 | -0.230850128 |
| study_minutes | 0.614839821 | 0.0104225933 | 30 | 0.3126778 |
| screen_time_minutes | -0.499727668 | -0.00420960489 | 60 | -0.252576293 |
| previous_score | 9.647972 | 0.778340203 | 10 | 7.78340203 |

`effect` is points per the indicated increment, holding six inputs fixed, before output clamping. Previous score is appropriately dominant; tiny negative steps is neither erased nor translated into advice to walk less. No coefficient was manually assigned or edited.

## 14. Multi-seed stability

| feature | raw_mean | raw_min | raw_max | positive_fraction | negative_fraction |
| --- | --- | --- | --- | --- | --- |
| exercise_minutes | 0.00170020855 | -0.00375163269 | 0.00927221524 | 0.7 | 0.3 |
| previous_score | 0.776223774 | 0.76244025 | 0.796461694 | 1 | 0 |
| resting_heart_rate | -0.0465419591 | -0.0783168692 | -0.025117332 | 0 | 1 |
| screen_time_minutes | -0.00419562919 | -0.00582658812 | -0.00234159378 | 0 | 1 |
| sleep_hours | 0.0892734514 | 0.0177595612 | 0.147021891 | 1 | 0 |
| steps | -1.6853363e-05 | -7.92677369e-05 | 3.2967101e-05 | 0.4 | 0.6 |
| study_minutes | 0.0104240671 | 0.00861846746 | 0.0119667182 | 1 | 0 |

Previous score is strongest by absolute standardized coefficient in **10/10** seeds. Sleep/study positive10/10, screen negative10/10, RHR negative10/10. Steps positive4/10; exercise positive7/10. All magnitudes meet the predeclared tiny-effect bounds. The pooled exercise sign is now positive, but that alone is **not** the reason for approval: either sign was allowed if small and explained. Different seeds, clearer manual-day budgeting and sampling alter tiny conditional estimates. No causal direction was discovered.

## 15. Final What-If ranges, step sizes and meanings

All bounds below are **engineering support limits**, not healthy ranges or recommended behaviors. Sliders/buttons use the stated steps; typed entry may be finer within support. They adjust totals for the captured period in section6. No implicit averaging or days-to-window multiplication.

| feature | min | max | step | change_per_step | change_min_to_max |
| --- | --- | --- | --- | --- | --- |
| sleep_hours | 0 | 12 | 0.5 | 0.0444748898 | 1.06739736 |
| steps | 0 | 30000 | 500 | -0.00834577834 | -0.5007467 |
| exercise_minutes | 0 | 180 | 5 | 0.00845115941 | 0.304241739 |
| resting_heart_rate | 35 | 120 | 1 | -0.0461700256 | -3.92445217 |
| study_minutes | 0 | 360 | 15 | 0.1563389 | 3.7521336 |
| screen_time_minutes | 0 | 720 | 30 | -0.126288147 | -3.03091552 |
| previous_score | 0 | 100 | 1 | 0.778340203 | 77.8340203 |

Sleep is hours, steps count, exercise/study/screen minutes, RHR bpm, prior percentage points. “Min-to-max” is signed model sensitivity across that entire range with all else fixed; it is not advice to traverse it. Current controls need model-version-specific range validation at both manual UI and assistant-tool boundaries.

Example: +30 study minutes means “a hypothetical previous day with30 more outside-class study minutes in this subject”; the estimate changes by **+.312678 points**. It does not mean that30 more minutes today will raise the upcoming score. Recreational screens and study have exactly the same definitions in entry, generator, Ridge metadata, What-If and Methodology.

Before a scenario, validate the **real baseline** dates/subject/score normalization/health freshness. Then apply hypothetical numerical overrides to its copy. A previous-score override does not need to falsify the real assessment's recorded earned/max values: label it hypothetical, and never write it back. Retain target identity and source periods in the scenario. No automatic recommendation search over coefficients.

The linear model does not implement the simulator's nonlinear plateaus. Numeric bounds prevent unbounded extrapolation, not all implausible joint profiles. Sleep belongs to a different window; do not sum that sleep with yesterday's activity/manual values as if one day. Within-day study/screen totals exclude overlap; elapsed-day checks should use the actual local day length. Do not change current HealthKit totals or invent zero when a baseline is incomplete.

Extreme check: all **128 rectangular corners** finite, raw **9.311360416499532–99.72526775283444**, zero output clamps, fixed[−5,105] guard passed. Since Ridge is linear, these bound the whole numerical rectangle; they do not validate human outcomes or combinations. The nonzero low-score floor is synthetic regression toward the assumed population mean, not a guaranteed minimum score. Boundary exports remain Python fixtures pending an independent Swift port check.

## 16. RHR academic and wellbeing roles

Academic raw coefficient **−0.04617002556641393 points/bpm**; +5bpm corresponds to **−.230850 points**. Central seed range−.078317 to−.025117; negative10/10. The direct latent RHR assumption is unchanged at−.03; no academic weight was intentionally increased. A slightly changed fitted coefficient reflects refitting and covariance, not a manually selected effect.

Seven-minus-six final MAE =**−.001229312**, paired synthetic95% interval **[−.010198414, +.008383411]**. Incremental evidence spans zero. These intervals measure synthetic-row uncertainty only.

| scenario | raw_mean | raw_min | raw_max | positive_fraction | negative_fraction |
| --- | --- | --- | --- | --- | --- |
| central | -0.0465419591 | -0.0783168692 | -0.025117332 | 0 | 1 |
| rhr_negative | -0.0733246464 | -0.105225762 | -0.0519020753 | 0 | 1 |
| rhr_null | -0.0196952552 | -0.0514103605 | 0.00166681219 | 0.1 | 0.9 |
| rhr_positive | 0.00715571009 | -0.0245062003 | 0.0284426112 | 0.6 | 0.4 |

Null-world RHR remains negative9/10 here: noisy proxy associations can persist without a direct latent effect. Therefore sign stability is not evidence that RHR causes score differences. Safe wording: “RHR is retained in the student profile, but its contribution to the academic estimate is small and uncertain.”

The separate [preserved RHR wellbeing design](V2_PRODUCTION_ALIGNMENT_DECISION.md) remains unchanged:33 completed local days,28-day baseline excluding five recent days,≥21 baseline days with weekly coverage,≥4/5 recent days and yesterday present, median±3×1.4826MAD,≥3 same-side recent days for persistence, two latest inside days to clear. No imputation; zero/undefined MAD means insufficient range data. These are statistical development assumptions, not medical or teenage-validated thresholds.

It remains local-only, non-diagnostic and independent of Ridge. No score adjustment, emergency trigger, new HealthKit type or background observer. This blocker resolution does not authorize shipping an alert or claim Apple validates it. Age-appropriate wellbeing review/validation remains a separate release consideration.

## 17. Frozen V1 versus final V2: common comparison

Same4000 final synthetic rows, raw outputs. Reduced models are comparison baselines, never fallback replacements for required seven-input production behavior:

| model | mae | rmse | r2 | bias | calibration_slope |
| --- | --- | --- | --- | --- | --- |
| v1_frozen | 8.26252809 | 10.2791011 | 0.332156111 | -4.71136355 | 1.12458712 |
| old_previous_only | 6.57034134 | 8.20520733 | 0.574456659 | 0.149877548 | 0.987779215 |
| old_ridge_six | 6.57846567 | 8.20617906 | 0.57435586 | -0.0374594355 | 0.980884584 |
| old_ridge_seven | 6.5752487 | 8.20031042 | 0.574964441 | -0.0209079745 | 0.982039698 |
| previous_seven_pooled | 6.55368422 | 8.17360479 | 0.577728326 | -0.0140088518 | 0.989272112 |
| aligned_seven_pooled | 6.53677182 | 8.15144766 | 0.580014624 | 0.216799598 | 0.997465945 |
| mean_only | 10.0994834 | 12.5820448 | -0.000615282271 | 0.312000191 | — |
| new_previous_only | 6.57051485 | 8.20717152 | 0.5742529 | 0.261274776 | 0.998034414 |
| new_ridge_six | 6.53583422 | 8.1568595 | 0.579456773 | 0.2578411 | 0.997736446 |
| new_ridge_seven | 6.5346049 | 8.1508881 | 0.580072282 | 0.25783018 | 0.998833232 |

`new_previous_only`, `new_ridge_six`, `new_ridge_seven` share the new training pool. `old_*`, `previous_seven_pooled` and `aligned_seven_pooled` are preserved historical artifacts. All models score the same numbers; historical models' different original window/support/target contracts make their scores **transport diagnostics**, not valid deployments under the new metadata. Mean-only has undefined calibration slope.

Final V2 MAE **6.534605**, RMSE **8.150888**, R² **.580072**, bias **+.257830**, calibration slope **.998833**. Matched prior-only MAE6.570515: improvement.035910 points, paired interval for V2-minus-prior[−.067291995,−.004348122]. Frozen V1 MAE8.262528 on this new synthetic distribution. None proves superiority on students or real calibration.

Prespecified stress results, final seven-input artifact kept fixed:

| scenario | mae | rmse | r2 | bias |
| --- | --- | --- | --- | --- |
| central | 6.5346049 | 8.1508881 | 0.580072282 | 0.25783018 |
| null_habits | 6.57109473 | 8.19131308 | 0.564402891 | -0.133412669 |
| double_habits | 6.64798541 | 8.31497026 | 0.582061634 | 0.649734037 |
| rhr_null | 6.53720025 | 8.15232625 | 0.579688765 | 0.256007889 |
| rhr_negative | 6.53513523 | 8.15417163 | 0.580172401 | 0.259662674 |
| rhr_positive | 6.54228083 | 8.1584867 | 0.579021897 | 0.254193881 |
| opposite_sleep | 6.53417704 | 8.15702776 | 0.575723442 | 0.169273968 |
| low_noise | 5.00194138 | 6.25119987 | 0.703263933 | 0.192223317 |
| high_noise | 9.55740584 | 11.8570371 | 0.385740541 | 0.480090233 |
| linear | 6.53306288 | 8.14867556 | 0.580428622 | 0.0951807653 |
| shifted_caps | 6.53156375 | 8.14658907 | 0.57919914 | 0.249548936 |
| population_shift | 6.5877858 | 8.23477586 | 0.665056572 | 0.83785704 |
| previous_low | 6.91149786 | 8.61806266 | 0.325705199 | 0.237164488 |
| previous_high | 6.69636497 | 8.36353978 | 0.641178243 | 0.28146737 |
| strong_activity_coupling | 6.53585986 | 8.15195704 | 0.579991723 | 0.288400984 |
| measurement_double | 6.93082226 | 8.64317262 | 0.527816232 | 0.334455462 |
| sleep_complete | 6.53274965 | 8.15031125 | 0.580131718 | 0.306208916 |
| sleep_early | 6.53244507 | 8.14870073 | 0.580297636 | 0.0368823201 |
| source_variation_double | 6.93082226 | 8.64317262 | 0.527816232 | 0.334455462 |
| previous_generator_transport | 6.47754924 | 8.11835544 | 0.599603621 | -0.0954760757 |

Missingness sensitivity yields **41.375% coverage (1655/4000)** when all seven are required; selected-subset MAE6.433607. These missingness rates are assumptions, not observed availability. Numeric missingness comparisons do not imply older models satisfy target/date metadata. Data leakage checks exclude development/final rows from scaling/CV; no HSLS evaluation is used.

## 18. Scientific limitations and real-world claim boundary

**Even if this V2 candidate passes all offline checks, its predictive accuracy on real students remains unverified.** NetHealth is related evidence, not direct validation of this seven-input production model. Its average heart rate is not resting HR, its outcome/cohort differ, and no GPA error is converted into percentage-point accuracy. NetHealth was not rerun.

HSLS outcomes remain untouched. MCS and COMPASS participant analyses against TwinTrack are not completed. Their planning/literature documents are not result files. No private HealthKit records, personal photos, raw participant data or device identifiers were inspected or added.

Limitations include single-day noise, partial sleep before noon, unknown future behavior, self-report recall/categorization error, unmeasured subject difficulty/prior comparability, an arbitrary90-day prior-age gate, unvalidated1–7-day transport, nonlinear latent behavior approximated linearly, distribution clipping and missingness assumptions. The simulator uses one idealized overnight episode and a synthetic previous-day schedule; it is not a full HealthKit/source/DST physiology simulator. Its28-day latent-profile ancestry does not turn the observed inputs into28-day averages.

Tiny unstable directions are acceptable only as transparent conditional model behavior. Never say “exercise/steps will raise or lower your grade,” “this score is calibrated for UAE teenagers,” “seven inputs are scientifically necessary,” or “the personal RHR range diagnoses health.” No confidence interval from the synthetic bootstrap can be shown as an individual real-world prediction interval.

## 19. Exact proposed Swift integration changes — not performed

After A explicitly authorizes the next implementation milestone:

1. `TwinTrackModel.swift`: retain V1 immutable; add `2.0-final.1` using exact scaler/intercept/coefficients/order. Export format already contains target, ranges and missing-data policy. Add new independently checked Swift/Python parity fixtures; keep V1's21 golden profiles unchanged.
2. `TwinTrackState.swift`: introduce local contract metadata alongside existing seven values—manual day/study subject, selected subject/target date/assessment identity, prior date/subject/earned/max. These are eligibility/provenance, not new Ridge features or a second state owner. Preserve explicit Run Prediction, shared refresh and existing cancellation/staleness behavior. Require current manual day, same subject, normalized prior, target horizon and existing health freshness.
3. `ProfileView.swift` manual sheet: implement exact labels/helper text in sections4–5, date context and minimal local assessment metadata. Reconfirm legacy values; do not invent dates or silently reinterpret leisure/study. Require entry for a new day; preserve unsaved Cancel. Persist metadata atomically with the corresponding values so fields cannot belong to different commits. No cloud/account/location collection.
4. `WhatIfScenario.swift`/`WhatIfView.swift`: select bounds/step sizes by model version, validate real baseline first, then evaluate read-only hypothetical values using the same source-period/subject meanings. Share eligibility with assistant tools; show model-estimate changes, not causal advice. Do not change live HealthKit/manual/history values.
5. `PredictionHistory.swift`: add model/contract version and local target/source-day identity on new snapshots; keep old schema backward-compatible as V1. Never recompute or relabel old predictions/chats. Include model and target identity in reuse checks: equal seven values for a different assessment are not the same prediction. Preserve Clear History and chat isolation.
6. Existing Model Information/Methodology and assistant prediction explanations: one target/window contract; disclose experimental status and small uncertain activity/RHR effects. A model response cannot override deterministic metadata eligibility or make causal habit claims. No conversational architecture/UI redesign.
7. HealthKit production queries/windows stay unchanged. RHR wellbeing remains a separate design; do not merge personal median/trend state into the latest-sample Ridge input or start its implementation implicitly.
8. Before enabling V2: build, complete Swift/unit/UI regressions, V1+V2 parity, migration/reconfirmation, midnight/DST/subject/target rollover, missing-data/What-If/history/chat isolation, and A physical review. Keep V1 available until those pass. No implementation begins in this task.

## 20. Final verdict

**APPROVE FOR IOS INTEGRATION** of the specified experimental candidate and contract.

| Criterion | Resolution |
| --- | --- |
| Target/horizon | Next selected-subject individual quiz/test/exam,1–7 local days; explicit exclusions and abstention. |
| Previous score | Most recent same-subject result1–90 days old, earned/max×100; no undated fallback. |
| Seven input windows | One table; previous-day manual totals, existing HealthKit windows retained. |
| App/model/What-If agreement | Proposed implementation uses the same definitions. **Current Swift is unchanged V1**, so this is implementation approval, not a claim of present agreement. |
| Steps/exercise instability | Diagnosed weak conditional signal/noise/proxy overlap; no severe scaling/collinearity fault; predeclared tiny-effect gates all pass. |
| No coefficient manipulation | All fitted by StandardScaler+Ridge; fixed seeds and unique pooled artifact; no diagnostic variant selected. |
| Prior importance | Strongest standardized coefficient10/10. |
| RHR | Small, uncertain increment; target weight unchanged; separate wellbeing design preserved. |
| What-If/extrapolation | Explicit ranges/steps/source-period labels, numerical guards, no causal interpretation. |
| Extremes |128/128 finite within guard; calibration limited to synthetic outcomes. |
| Swift complexity | Existing state/model/history architecture retained; local metadata and versioned validation required. |
| Limitations | Real-world accuracy unverified, HSLS untouched, no clinical/RHR claim. |

The changed decision does **not** mean new real-world evidence appeared. It follows the user's request to define the contract and accept well-explained near-zero activity uncertainty under a rule fixed before artifact selection. Do not equate approval to integrate with approval to deploy or with proof of accuracy.

No staging, commit, push, production Swift edit, presentation work or iOS integration. Stop after this decision and wait for A.
