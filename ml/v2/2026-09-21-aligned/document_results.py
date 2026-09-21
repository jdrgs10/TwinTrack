"""Assemble the decision and complete assumption ledger from canonical offline outputs."""
import hashlib
import json
from pathlib import Path
import pandas as pd

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
R=HERE/'results'


def table(frame):
    def cell(v):
        if isinstance(v,float): return '—' if pd.isna(v) else f'{v:.9g}'
        return str(v).replace('|','\\|')
    return '\n'.join(['| '+' | '.join(map(str,frame.columns))+' |',
        '| '+' | '.join(['---']*len(frame.columns))+' |']+
        ['| '+' | '.join(cell(v) for v in row)+' |' for row in frame.itertuples(index=False,name=None)])


def leaves(obj,prefix=''):
    for k,v in obj.items():
        name=f'{prefix}.{k}' if prefix else k
        if isinstance(v,dict):yield from leaves(v,name)
        else:yield name,v


def run():
    p=json.loads((R/'new_ridge_seven_parameters.json').read_text())
    cfg=json.loads((R/'resolved_config.json').read_text())
    coef=pd.read_csv(R/'final_coefficients.csv')
    stability=pd.read_csv(R/'coefficient_stability.csv')
    central=stability[(stability.scenario=='central')&(stability.model=='new_ridge_seven')]
    rhr=stability[(stability.model=='new_ridge_seven')&(stability.feature=='resting_heart_rate')]
    metrics=pd.read_csv(R/'comparison_metrics.csv')
    main=metrics[(metrics.scenario=='central')&(metrics.output=='raw')]
    common=pd.read_csv(R/'common_support_metrics.csv')
    stresses=metrics[(metrics.model=='new_ridge_seven')&(metrics.output=='raw')]
    sensitivity=pd.read_csv(R/'what_if_sensitivities.csv')
    params=json.dumps({k:p[k] for k in ['model_version','features','mean','scale','coefficients_standardized','intercept_standardized','coefficients_raw','intercept_raw','alpha','training_rows','output_clamp']},indent=2)
    report=f'''# TwinTrack — V2 production alignment and RHR wellbeing decision

2026-09-21 · offline candidate **2.0-aligned.1** · **DO NOT APPROVE for iOS integration**.

All seven inputs remain, in their existing order. Choose **A: retrain to the app's captured snapshots**, not B: silently replace its windows with 28-day means. A new candidate and a separate RHR statistical design were produced. All new data are **EVIDENCE-INFORMED SYNTHETIC DATA**. No real student accuracy, clinical validity or completed iOS integration is claimed.

The numerical checks pass, but the product decision does not: manual reporting periods and the academic target remain undefined; a slightly negative exercise effect and unstable activity signs remain unsuitable for unqualified habit guidance. The separate teenage wellbeing design is specified and tested mechanically, but its alert performance is unvalidated. These are disclosed gaps, not problems solved by changing coefficients.

## 1. App input-window audit

Read directly from [HealthData.swift](../ios/twintrack/twintrack/HealthData.swift), [HealthKitService.swift](../ios/twintrack/twintrack/HealthKitService.swift), [TwinTrackState.swift](../ios/twintrack/twintrack/TwinTrackState.swift), [ProfileView.swift](../ios/twintrack/twintrack/ProfileView.swift), [WhatIfScenario.swift](../ios/twintrack/twintrack/WhatIfScenario.swift) and [WhatIfView.swift](../ios/twintrack/twintrack/WhatIfView.swift). No device, settings or health records inspected. “Current V2” below means preserved `2.0-seven-input.1`, not the shipped frozen V1.

| Feature | Current app source, units and exact definition | Previous V2 definition | Match? | Recommended final definition / decision |
| --- | --- | --- | --- | --- |
| sleep_hours | HealthKit sleepAnalysis; hours; union of accessible actual-asleep intervals from yesterday local noon to earlier of now/today noon. Partial before noon; naps in-window count; no averaging. | 28 completed noon-window means; ≥21 observed days. | No | A: retain captured window and cutoff; identify as recent sleep, not usual/monthly sleep. |
| steps | HealthKit stepCount; count; cumulative previous completed local calendar day, midnight to midnight. | 28-day mean daily steps. | No | A: previous-day total; preserve calendar/DST semantics. |
| exercise_minutes | HealthKit appleExerciseTime; minutes; cumulative same previous calendar day. | 28-day mean daily exercise. | No | A: previous-day Apple Exercise minutes; not all physical activity or a general workout duration. |
| resting_heart_rate | HealthKit restingHeartRate; bpm; latest finite positive sample by startDate within inclusive last 72 elapsed hours; timestamp retained. | Mean of daily resting-HR summaries over 28 days. | No | A: retain latest recent sample for Ridge. Historical daily trend is a separate feature outside the seven-input model. |
| study_minutes | Latest saved manual integer minutes; 0–959; no date, reporting period, subject or in/out-of-class distinction stored. | 28-day mean deliberate outside-class same-subject study minutes/day. | No | A: honestly model the latest saved scalar. Do not claim daily/same-subject meaning. Reporting-period decision remains unresolved. |
| screen_time_minutes | Latest saved manual integer minutes; 0–959; no date, duration window, recreational/study/content distinction stored. | 28-day mean recreational screen use excluding study/double counting. | No | A: latest saved scalar; do not relabel as measured recreational/daily average. Meaning remains unresolved. |
| previous_score | Latest saved manual finite 0–100 score; date and subject absent. | Comparable same-subject score, ≤90 days old, predicting an assessment seven days later. | No | A: latest saved score. Cannot assert freshness, comparability or a seven-day outcome from the current record. |

Additional exact behavior:

- Sleep counts asleepCore/Deep/REM/Unspecified, ignores awake/inBed, clips and unions overlaps across accessible sources. An asleep source can prevail over another source's awake interval. This does not reproduce Apple Health's private source-priority rules.
- Activity queries use HealthKit cumulative sums with strict start-date membership, intended [previous midnight, current midnight). They do not manually sum Watch/iPhone sources or prorate crossing samples. Calendar days can be 23/25 hours; RHR's 72 hours are elapsed time.
- RHR selection filters invalid newest samples before choosing the latest valid one; equal timestamps choose the higher bpm deterministically. This is a tie-break, not a health inference.
- All seven missing inputs remain absent. No accessible sleep intervals → missing, not zero. No quantity sum → missing; a genuine accessible step/exercise zero is valid. RHR must be >0. Invalid/failed reads are distinct from missing. Blank manual entries remove the saved value.
- Shared refresh commits all four results together. Launch/foreground/pull use the existing shared path. Freshness checks day/sleep-start/time zone and available RHR timestamp; sleep end need not equal a continually advancing now. Manual save stores no timestamp despite its unused `now` parameter.
- Prediction currently requires an explicit run; refresh/rendering does not execute Ridge. Historical snapshots use `explicitRun.v1`. What-If captures a baseline and temporary seven-feature overrides, recalculates the frozen model, and never writes back to state/HealthKit/history.
- Current What-If checks finite/nonnegative values plus a floating-point upper guard, RHR >0 and prior ≤100. It has **no scientific support bounds**. Step buttons do not constrain typed values. This must change in a separately approved integration, not in this pass.

## 2. Final seven-input contract and alignment decision

The proposed literal source contract is the table's A column. All seven positions remain unchanged. Keep health windows practical and explicit; do not replace the recent Home readings merely to fit an earlier simulation. Research on longer-term sleep associations does not validate the precise previous V2 contract for all seven features. For example, [Okano et al.](https://www.nature.com/articles/s41539-019-0055-z) found associations over learning-period sleep, not simply the preceding night. This argues against calling a recent sleep snapshot a validated grade forecast; it does not establish a universal 28-day app requirement.

**Target change is material:** the new offline output is a hypothetical **current-profile educational score, 0–100**, with no forecast horizon. It is not a validated future assessment, GPA, same-subject score or readiness diagnosis. Its synthetic `assessment_score` column name is retained for runner compatibility only. The previous assessment target must not survive silently in UI/assistant explanations.

Literal numerical/source alignment is achieved for an offline surrogate; scientific measurement alignment is incomplete. The generator approximates one synthetic overnight episode, source-day totals and noisy saved scalar reports. It does not reproduce actual HealthKit records, multiple sleep-source conflicts, all DST elapsed durations, wear-time bias or observed manual reporting behavior. The actual app continues to use the audited Calendar implementation. The prior gate `input_contract_matches_current_app=true` refers only to this literal snapshot contract and is explicitly qualified in `acceptance.json`.

Before production approval, A must settle what study/screen durations describe and what output the product claims. Existing undated values cannot be reinterpreted as observed daily averages. This is a product definition gap, not authorization here to collect more identifiers, add features or change the app.

## 3. Retraining and common evaluation

New directory: [ml/v2/2026-09-21-aligned](../ml/v2/2026-09-21-aligned/README.md). Both previous V2 versions and frozen V1 are preserved. [Protocol](../ml/v2/2026-09-21-aligned/PROTOCOL.md) was fixed before training; [assumption ledger](../ml/v2/2026-09-21-aligned/ASSUMPTION_LEDGER.md) records every resolved setting.

The previous bounded correlated generator supplies latent usual-profile factors and its hypothetical target; old observation noise is disabled in memory. New observations use a refresh-hour sleep cutoff, source-day activity variation, an RHR sample-age variable and self-report error. No timestamp/source field becomes an eighth predictor. All distribution values are development assumptions, not empirical HealthKit error rates. Latent outcomes retain previous-score slope .8, central noise SD8 and small lifestyle terms; no coefficients were tuned manually. Generated observations are bounded to simulation support. **Real inputs must never be clamped to these bounds.**

Ten fixed seeds3101–3110 ×6000 rows: 4500 training +1500 holdout per seed. Pool all 45,000 training rows; exclude all 15,000 holdouts. StandardScaler lives inside five-fold training-only CV. Alpha grid [.1,1,10,100,1000]; pooled CV seed3201; selected alpha **100**. Final4000 rows use seed99001. Thirty additional RHR-world refits are diagnostics, not artifact selection. There were63 searches overall, each25 CV fits plus refit. No seed was discarded.

Nine fixed models score identical final rows, with raw and clamped metrics, calibration, paired intervals, missingness and extremes. Nineteen new-generator scenarios plus one earlier-generator transport cohort =20; `measurement_double` and `source_variation_double` are deliberately equivalent after observation replacement, not independent evidence.

Final central synthetic test, raw output (4000 rows/model):

{table(main[['model','mae','rmse','r2','bias','calibration_slope']])}

All historical models are transported to the same rows; this is not proof their original deployment contracts hold. A second comparison applies the **previous numerical bounds only** (2960/4000 rows,74%); it does not validate old dates/subjects/28-day coverage or the old joint-time constraint:

{table(common[['model','n','mae','rmse','r2']])}

New-seven minus matched-new-prior MAE = **−0.044449539**, paired synthetic95% interval **[−0.076016143, −0.012859233]**. This tiny assumed-data improvement is not real-world accuracy. No earlier .10 selection gate is repurposed: seven features are a user constraint.

Sensitivity to assumptions, new-seven raw MAE (4000 rows each):

{table(stresses[['scenario','mae']])}

Missingness experiment: all-seven complete coverage **40.775% (1631/4000)**; MAE6.452826 on that selected subset. This is a deliberately assumed missingness process, not measured app availability or accuracy. Model-specific coverage is also recorded; reduced-feature models' wider coverage is not permission to substitute them silently. Missingness tables check required values, not old metadata eligibility.

## 4. Final seven-input Ridge parameters

Offline numerical artifact only: [full-precision JSON](../ml/v2/2026-09-21-aligned/results/new_ridge_seven_parameters.json) and paired model binary. `raw = intercept_standardized + Σ(coefficient_standardized[i] * (x[i] − mean[i]) / scale[i])`; display clamp0–100 only after eligibility. Equivalent raw-unit form is exported. Do not round these constants in a later approved Swift port.

```json
{params}
```

## 5. Coefficient stability

Ten independent central training fits, not ten copies of the pooled artifact:

{table(central[['feature','raw_mean','raw_min','raw_max','positive_fraction','negative_fraction']])}

Previous score is the largest absolute standardized coefficient in **10/10** fits. Sleep/study are positive10/10; screen negative10/10. Steps positive7/10, exercise positive3/10. Both fail the predeclared80% sign-consistency check. Their effects are small; that does not establish reliable direction. Keep the fitted negative exercise coefficient visible as a limitation; do not make it positive by hand. No causal advice to exercise less follows from it.

## 6. Original-unit sensitivities

Holding the other six numbers fixed, within support, before output clamping:

{table(coef[['feature','raw','increment','effect']])}

Always say **“The model estimate changes by…”**, not that grades will improve. Prior +10 points changes the estimate by7.794376 points; the entire hypothetical improvement comes from the model formula, not a recommended habit. RHR +5bpm changes it by−.213650 points. These are conditional synthetic-model sensitivities; latent confounding and noisy proxies can alter their signs/magnitudes.

## 7. RHR academic role

Fitted raw RHR coefficient **−0.04272991639474873 points/bpm**. Central ten-seed range **−.056142954 to −.020880770**; negative10/10 under the assumed small negative latent effect. Its standardized magnitude .298369 is much smaller than previous score9.650262.

New-seven versus matched-new-six: MAE6.516991 versus6.525087; ΔMAE **−.008095918**, paired95% interval **[−.017076676, +.000901836]**,2000 bootstraps. The interval spans zero. It measures only synthetic row variation, not uncertainty about real teenage effects.

{table(rhr[['scenario','raw_mean','raw_min','raw_max','positive_fraction','negative_fraction']])}

With zero direct latent RHR effect, fitted signs are negative7/10 and positive3/10, because proxies/correlations/noise can still create associations. With positive latent effect, positive7/10. Central sign stability is not physiological proof. None of the alternate worlds supplies the exported model.

Safe interpretation: “Resting heart rate is retained as part of the student profile, but its contribution to this synthetic academic estimate is small and uncertain.” The completed NetHealth aggregate does not calibrate RHR: its daily average heart rate is a different measure. Do not infer that changing heart rate causes a grade change.

## 8. Separate RHR wellbeing design and evidence

Purpose: notice sustained differences from the student's own recent pattern. **Not a Ridge input transformation, score modifier, medical screening tool or emergency trigger.** Existing academic RHR remains latest72-hour sample; wellbeing uses separate historical daily values of the same already-authorized type. No heartRate/HRV/age/location permission is added.

Evidence and limits, checked2026-09-21:

| Source | Supported design inference | What it does not establish |
| --- | --- | --- |
| [Quer et al.,92,457 adults](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0227709) | Large between-person differences favor personal comparison. Adult study examined episodes beyond2 SD of previous20 readings lasting≥3 consecutive measurements in5 days. | Not an adolescent Apple Watch validation, diagnostic threshold, or validation of TwinTrack's28-day/MAD rule. |
| [Apple restingHeartRate documentation](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/restingheartrate) | RHR is a discrete estimate; Watch can replace current/previous-day samples. Requery and select by timestamp rather than counting refreshes. | No Apple endorsement of TwinTrack's trend/grade interpretation. Resting HR differs from a sedentary ordinary-heartRate sample. |
| [Apple Vitals](https://support.apple.com/en-ae/120142) | Personal typical ranges and careful watch fit matter; readings are affected by several contexts. Apple's app has its own setup and multi-metric behavior. | Its seven-night setup is not a validated minimum for this single-metric teenage algorithm. Do not copy its clinical implications. |
| [NIST MAD](https://itl.nist.gov/div898/software/dataplot/refman2/auxillar/mad.htm) | Median absolute deviation is a robust scale statistic; normal-consistent scaling is approximately1.4826. | A statistical scale is not a medical threshold or a guarantee of a particular false-alert rate. |

Research supports personal comparison as a design direction. It does **not** provide one universal safe bpm deviation, baseline length or persistence rule for UAE adolescents. The choices below are explicit, conservative-intent **development assumptions**, not clinically calibrated cutoffs. Adult evidence must not be described as teenage validation.

## 9. Exact personal-baseline logic and state machine

Offline reference: [rhr_trend.py](../ml/v2/2026-09-21-aligned/rhr_trend.py), covered by synthetic tests. Proposed computation uses Calendar/time-zone dates; never subtract fixed24-hour seconds for day buckets.

1. Query existing restingHeartRate records over **33 completed local calendar days**, excluding today. For each local date select the latest finite-positive sample by startDate; equal timestamps choose higher bpm as the current app does. Compare absolute instants through repeated DST hours. No source IDs retained.
2. Let D=yesterday. Recent =D−4…D (5 days); baseline =D−32…D−5 (28 days). Recent values **never** enter their comparison baseline.
3. Require ≥21 valid baseline days, ≥4 in **each fixed7-day block**, ≥4 of5 recent days and D present. A weekly cluster cannot substitute for spread across the baseline. No interpolation, carry-forward, zero-fill or sample-count inflation.
4. Let m=median(baseline), s=1.4826×median(|x−m|). Require s>0; zero/undefined MAD gives insufficient range data, not an invented bpm floor or a health conclusion. One-dimensional quantization can make this common; sensitivity/coverage remain to be evaluated.
5. Flag higher if x>m+3s, lower if x<m−3s; equality is inside. There is no universal “healthy” bpm band. The factor3 is a development rule, not a calibrated medical or probabilistic guarantee.
6. Apply states in the order below. No prediction or emergency decision uses them.

| State | Exact rule | Quiet example copy |
| --- | --- | --- |
| Not enough recent data | Query unavailable/failed, any coverage gate fails, yesterday absent, or scale undefined/zero. | “Not enough recent data to compare your resting heart rate with your usual pattern.” For zero scale explain that a reliable range could not be estimated. |
| Within recent usual range | Both latest consecutive calendar days are observed and inside; OR every observed recent value is inside. | “Your recent readings are within your personal comparison range.” This is not a declaration of health. |
| Persistently different from recent baseline | Otherwise≥3 recent values beyond the same side, with no opposite-side flag. | “Your resting heart rate has been higher [or lower] than your recent usual range for several days.” |
| Noticeably different from recent baseline | Other recent outside values, including one-day or mixed-direction deviations. | “Some recent readings differ from your usual pattern.” Do not claim persistence. |

This is ≥3 recent days, not necessarily3 consecutive days; it deliberately differs from the adult study's episode definition. One isolated spike cannot become persistent. One inside day can coexist with persistence; **two consecutive latest observed inside days reset** to Within. A missing day breaks this two-day reset, and missing yesterday immediately yields insufficient data. Opposite-side excursions are “varied,” not persistent high/low.

Recompute from the fresh query on every existing refresh; no indefinite latch. Flags aging beyond five days, revised samples or a changed baseline can change state. Time-zone change rebuilds all buckets from timestamps. After a long gap, coverage must be re-established; do not carry an old state as current. A sustained shift can enter the rolling baseline and eventually cease to flag—this design is not continuous illness surveillance. No reset button erases history merely to get a desired state.

All28/21/4/5/3/2 choices require later empirical/usability assessment. “Conservative” describes the intended coverage/persistence safeguards, not a measured false-positive or false-negative rate. Rounded samples, autocorrelation and very small positive MAD can still cause nuisance flags.

## 10. Safety, age and privacy limits

Gentle optional follow-on: “Changes can happen for many reasons, including recovery, sleep, stress, exercise or illness. If this continues or you feel unwell, consider telling a parent, trusted adult or healthcare professional.” These are possible contexts, never diagnoses or an inference of the cause from RHR. Do not request those sensitive contexts merely to produce this comparison.

No alarming label, “dangerous” heart-rate boundary, international resource list, treatment, emergency escalation or clinical reassurance from the trend. The existing assistant safety route handles explicitly reported urgent symptoms/self-harm independently; this design neither weakens nor invokes it solely from a number.

The main personal-RHR study excluded under18s; teenage maturation, activity and measurement patterns limit transfer. Personal baselines reduce between-person comparisons but do not solve pediatric validity. Do not use adult population thresholds, collect DOB unnecessarily or infer age. Noise/fit, temporary recovery and insufficient wear can change or hide readings. Do not try to algorithmically diagnose illness, stress or fitness from them.

Processing stays local. A future service may read a33-day slice of the **same** restingHeartRate type into transient value/timestamp pairs, aggregate daily and discard samples. No cloud/backend/upload, raw-sample persistence, device/source IDs, prompt attachment, analytics payload or debug values. Retain one authoritative TwinTrackState with an optional transient trend result; clear it when health access/state is cleared. Refresh failure must not leave an old “Within” state presented as current. No push notification or background observer is proposed. This is not Apple-validated interpretation.

## 11. Missing-data and freshness rules

Prediction: all seven real values, current health-window metadata, finite values and approved model support required. Missing any → unavailable; out-of-support → abstain with reason, while preserving/displaying the actual input. Never force a real RHR into35–120 or force a manual duration into the simulation range. Retain actual sample date; do not manufacture one for legacy data. Before future V2 runs, require provenance adequate for the contract; historic snapshots remain historical.

Accessible zero activity or manual zero is different from inaccessible data. RHR0 invalid. Sleep with no accessible asleep interval stays missing; a zero-hour **hypothetical What-If** value is not evidence of an observed sleepless night. Old manual values have unknown age; the app cannot detect their staleness today.

Wellbeing coverage is independent: latest72-hour RHR can be usable by Ridge while insufficient historical days prevent the trend. Conversely, sufficient historical days do not supply a missing current Ridge value. Never forward-fill a repeated72-hour reading into a missing local date. The trend's statistical range does not use the academic RHR35–120 support bound.

## 12. Final proposed What-If ranges

These are **engineering support limits**, not recommendations, healthy ranges or empirically validated safe limits. They bound arithmetic/extrapolation, not all plausible joint behaviors. They are proposed only; Swift remains unchanged.

| Feature | Inclusive proposed support | Meaning of override |
| --- | --- | --- |
| Sleep |0–12 hours| Hypothetical captured-window sleep total, not permission to sleep0 or a causal dose. |
| Steps |0–30,000| Hypothetical previous-day total. |
| Exercise |0–180 minutes| Hypothetical previous-day Apple Exercise total. |
| RHR |35–120 bpm| Hypothetical latest resting sample; not an instruction to manipulate heart rate. |
| Study |0–360 minutes| Hypothetical saved report; daily meaning remains unestablished. |
| Screen |0–720 minutes| Hypothetical saved report; content/reporting period unknown. |
| Previous score |0–100| Hypothetical prior academic record; not a modifiable lifestyle habit. |

Apply the same numeric eligibility to baseline and all combined overrides in UI and assistant tools. Reject outside-range scenarios, do not silently clip. Recalculate the full scenario and subtract displayed clamped baseline. Preserve read-only historical cards/state isolation. Do not sum durations with different/unknown reporting periods into a fictitious single24-hour day. A future clarified common-day contract would require a genuine joint feasibility rule.

The linear model cannot reproduce assumed latent plateaus or diminishing returns. In final feasible increments:

{table(sensitivity[['feature','feasible_profiles','raw_delta_mean','hypothetical_generator_delta_min','hypothetical_generator_delta_max','surrogate_delta_mae']])}

The hypothetical-function columns plug noisy snapshots into the latent assumed function as a numerical approximation diagnostic only. They are **not** true counterfactual labels. Sleep above its latent cap still moves linear Ridge; exercise +30 minutes reduces this candidate by.025747 despite a nonnegative assumed latent effect. Tiny size does not make “exercise improves grades” defensible. No recommendation optimization over these coefficients.

## 13. Extreme profiles and validation

All128 rectangular corners are finite: raw **9.72005037615476–99.36344471600673**; zero clamped corners. They satisfy the fixed [−5,105] guard. Linear extrema over the numeric rectangle therefore remain within0–100. This is a numerical bound, not validation of all combinations or plausible scores at very low prior performance. The regression-to-mean floor is a simulator property, not a promised minimum grade.

Fourteen one-feature boundary fixtures export at1e−10 Python tolerance. Tests reject missing/nonfinite/negative/outside-support inputs; retain valid zeros; check export/pipeline/raw-formula equality. Final cohort and all stress metrics use the same rows per model. Full details: [VALIDATION.md](../ml/v2/2026-09-21-aligned/VALIDATION.md).

- New offline tests **20/20**, previous tests **59/59**, total **79/79**. Zero failures. Three pre-existing sklearn version warnings in the V1 pickle tests; none in new tests.
- Frozen Ridge Python golden parity **21/21**, maximum error7.105427357601002e−15, tolerance1e−6.
- Full independent rerun **29/29 result files byte-identical**. No seed/coefficients changed after inspecting results.
- **175 protected files unchanged**: V1/iOS, prior V2 artifacts/reports and approved local research. No Swift/Xcode/UI/device test run is claimed for this offline pass.

## 14. Exact proposed Swift integration changes — NOT PERFORMED

Do not start this plan until approval blockers are resolved:

1. `TwinTrackModel.swift`: retain immutable V1 and its21 golden profiles; add a versioned V2 parameter container from the full-precision export, same seven-feature order, StandardScaler+Ridge and output clamp. Add independently reviewed Swift parity fixtures for the new version; Python fixtures alone are insufficient.
2. `TwinTrackState.swift`: preserve one authority and explicit Run Prediction behavior. Add model-specific support/provenance eligibility without changing live HealthKit windows, manual values or V1 history. Refuse insufficient/unknown required metadata rather than inventing dates. Decide manual reporting meaning and student-facing target first.
3. `WhatIfScenario.swift`, `WhatIfView.swift` and the existing assistant tool boundary: share model-version eligibility/ranges; evaluate seven overrides against the captured same-version baseline; no real-state/history writes. Do not let a persisted V1 baseline be compared using V2 coefficients. RHR and previous score stay hypothetical, never habit recommendations.
4. `PredictionHistory.swift`/the existing snapshot schema: record model version and input-contract version on new runs; backward-decode old entries as V1 and never recompute saved historical scores/cards. Clear-history and saved-chat boundaries stay intact. Confirm the exact snapshot declaration file during implementation; no schema migration is executed here.
5. New pure `RestingHeartRateTrend.swift`: port the local-date, median/MAD, coverage/state/reset algorithm and offline fixtures; no access to Ridge. `HealthKitService.swift` may query the same RHR type for33 completed local dates; keep existing latest72-hour query and refresh semantics. No new authorization types, background observer or new persistent health database.
6. `HealthData.swift` plus `TwinTrackState.swift`: transfer only required value/timestamp pairs transiently and publish the separate trend assessment/coverage/as-of date; discard raw records, honor cancellation/generation identity and clear stale results on failures/access removal. Do not block the existing four-metric refresh on trend computation or overwrite current RHR with a historical median.
7. Existing Home/Profile/assistant copy only after approval: explain exact input periods, educational target and read-only personal comparison. No UI redesign in this pass. Quiet trend status should not create automatic crisis replies, chart points or prediction snapshots.
8. Integration validation later: Swift parity, calendar/DST/tie/replacement/missingness tests, all core/history/What-If/chat regressions, actual build and A physical review. This report authorizes none of those app changes yet.

## 15. Presentation-safe wording

“TwinTrack preserves seven profile inputs. Its offline V2 candidate uses the app's recent HealthKit snapshots and saved manual values, with previous performance remaining dominant.”

“The comparison uses evidence-informed synthetic data. Exact numerical assumptions are disclosed; the results are not validated accuracy for UAE students.”

“Resting heart rate has a small, uncertain contribution to the synthetic academic estimate. A separate proposed on-device comparison tracks sustained differences from a personal baseline and does not diagnose conditions.”

“What-If shows how the model estimate changes when inputs change; it does not show what will happen to a student's grades.”

These are suggested report statements only. No presentation or brochure was edited.

## 16. Claims TwinTrack must NOT make

- A validated future-exam/GPA prediction or a causal grade gain from sleep, exercise, RHR or screen use.
- A28-day/daily/same-subject manual average when only an undated saved scalar exists.
- That ten synthetic seeds validate a biological effect, seven inputs are scientifically necessary, or model errors are measured on real UAE students.
- That a personal RHR flag diagnoses illness, detects an emergency, supplies a healthy adult/teen range, or that Within means the student is medically well.
- That Apple validates this rule or that adult Fitbit episode findings establish teenage Apple Watch accuracy.
- That absent data are zero, old readings are fresh, a repeated sample is another day, or missingness coverage is empirically known.
- That HSLS/MCS/COMPASS comparisons against TwinTrack were completed. **NetHealth remains the only completed project real-data analysis**; it was not rerun. HSLS outcomes were not inspected. MCS has historical planning but no locally available original plan/completed analysis; COMPASS remains candidate/researched. Dataset strategy is planning/literature evidence, not participant results.

## 17. Final verdict

**DO NOT APPROVE.**

| Acceptance criterion | Finding |
| --- | --- |
| Seven explicit inputs in unchanged order | Literal stored-source contract documented; manual reporting period/content/subject unresolved. |
| App and generator match | Snapshot-level numerical alignment; not a validated measurement/assessment contract. No silent28-day conversion. |
| Prior remains important | PASS: strongest10/10. |
| Lifestyle effects plausible for interpretation | Small, but steps/exercise signs fail80% stability; slightly negative pooled exercise effect precludes unqualified habit guidance. |
| RHR academic effect small/transparent | PASS as disclosed synthetic association; incremental interval crosses zero. |
| RHR wellbeing separate | PASS by offline design; no Ridge coupling. |
| Non-diagnostic, evidence-informed trend | Design specified; thresholds/teen performance remain development assumptions. No medical-release claim. |
| What-If limits | Numeric bounds prevent unbounded extrapolation; do not validate joint profiles or causal advice. Manual period still unresolved. |
| Extreme profiles | PASS numerical guard128/128; not evidence of real score calibration. |
| Straightforward Swift port | Plan provided; no integration, build or physical validation performed. |
| Limitations and preservation | Documented;175 protected files unchanged; no staging/commit/push. |

Do not rerun seeds or enlarge lifestyle effects to force approval. The next decision is the product's academic output/reporting-period contract and whether its What-If explanation can honestly present tiny, unstable associations. If the goal remains an actual assessment forecast, that needs a prespecified target and suitable evaluation; renaming this synthetic profile score is insufficient. The RHR comparison may be considered independently as an explicitly experimental, quiet wellbeing feature, with age-appropriate review and validation before release.

Stop here. This pass does not modify the app, advance to integration, inspect HSLS outcomes or start another model version.
'''
    (ROOT/'docs/V2_PRODUCTION_ALIGNMENT_DECISION.md').write_text(report)
    ledger='''# Assumption/evidence ledger — 2.0-aligned.1

All new numerical observations and latent grade effects are **DEVELOPMENT ASSUMPTIONS**, not empirical participant estimates or medical thresholds. Read the decision report's source table for scientific context. The full prior latent-generator ledger remains preserved at `../2026-09-21-seven-input/ASSUMPTION_LEDGER.md`.

The latent generator uses the prior version's bounds and assumptions, with its observation measurement_sd set to zero in memory. The resolved config below controls the new snapshot observation layer/training/evaluation. The inherited `generator.measurement_sd.*` settings remain listed for provenance but are **not used** as extra observation noise; `snapshot.*` replaces that layer. `stress.measurement_multiplier` likewise is superseded by snapshot.variation_stress_multiplier for the two identical doubled-variation scenarios. Latent target, nonlinear transforms, correlations, clipping, time budget, outcome noise and alternate worlds are inherited, not newly fitted.

| Decision | Provenance/status | Interpretation |
| --- | --- | --- |
| Health windows/source units | VERIFIED SOURCE CODE | Actual Swift implementation, not measured participant distributions. |
| Manual reporting period/subject/date | UNKNOWN | Latest saved scalars only; no invented daily or same-subject data. |
| Forecast horizon | NONE for new prototype | Material target narrowing; no validated forecast. |
| Prior importance; weak wearable increment | COMPLETED NetHealth aggregate, qualitatively evidence-informed | Average HR is not RHR; no GPA-to-percentage conversion. |
| RHR academic numeric slope and all synthetic target effects | DEVELOPMENT ASSUMPTION | No empirical seven-variable causal/forecast equation. |
| Snapshot distributions/error/partial-night timing | DEVELOPMENT ASSUMPTION | One idealized episode, totals/scalars; no source-level/detailed DST simulator. |
| RHR personal comparison direction | EVIDENCE-INFORMED DESIGN | Adult within-person variability and official HealthKit mechanics. |
| 28/21 days, weekly coverage, 3×scaledMAD, 3of5, two-day reset | DEVELOPMENT ASSUMPTION | Not universal/pediatric/medical thresholds; false-alert rate unknown. |
| 1.4826 MAD factor | STATISTICAL CONVENTION | Approximate normal consistency, not a health cutoff. |
| Numeric What-If bounds | ENGINEERING ASSUMPTION | Not healthy ranges; preserve real values and abstain outside. |
| Teen transfer/real accuracy/causal effects | UNKNOWN | No new participant analysis or clinical validation. |

## Every resolved config leaf

Arrays list exact predeclared values. Training procedure/seeds are reproducibility choices; biological-looking constants remain synthetic assumptions. No data was used to choose a best-looking seed.

| Setting | Value |
| --- | --- |
'''
    for name,value in leaves(cfg):ledger+=f'| `{name}` | `{json.dumps(value,ensure_ascii=False)}` |\n'
    (HERE/'ASSUMPTION_LEDGER.md').write_text(ledger)
    files=sorted([f.relative_to(ROOT).as_posix() for f in HERE.rglob('*') if f.is_file() and '__pycache__' not in f.parts]+['docs/V2_PRODUCTION_ALIGNMENT_DECISION.md'])
    inventory=HERE.relative_to(ROOT).as_posix()+'/FILE_INVENTORY.md'
    if inventory not in files:files.append(inventory);files.sort()
    (HERE/'FILE_INVENTORY.md').write_text('# Files created in this pass\n\n'+f'{len(files)} files. Prior versions/report files are not new changes from this pass. No production edits.\n\n'+'\n'.join('- `'+f+'`' for f in files)+'\n')


if __name__=='__main__':run()
