"""Render the review artifacts from the fixed experiment; never trains or tunes."""
import hashlib
import json
from pathlib import Path

import pandas as pd

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
R=HERE/"results"
C=json.loads((HERE/"config.json").read_text())


def table(frame,precision=6):
    def text(v):
        if isinstance(v,float): return "undefined" if pd.isna(v) else format(v,f".{precision}f")
        return str(v).replace("|","\\|")
    rows=["| "+" | ".join(map(str,frame.columns))+" |","| "+" | ".join(["---"]*len(frame.columns))+" |"]
    rows += ["| "+" | ".join(text(v) for v in row)+" |" for row in frame.itertuples(index=False,name=None)]
    return "\n".join(rows)


def leaves(d,prefix=""):
    for k,v in d.items():
        name=f"{prefix}.{k}" if prefix else k
        if isinstance(v,dict): yield from leaves(v,name)
        else: yield name,v


EVIDENCE="""| Feature | Evidence / expected direction | Prior-attainment adjustment / causal limits | Central numeric hypothesis and tested range | Confidence in transferable magnitude |
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
"""


def ledger():
    rows=[]
    for name,value in leaves(C):
        note="Predeclared engineering/reproducibility choice, not an empirical estimate."
        if name.startswith("generator."):
            note="Retained prior V2 assumption; not fitted to real people. See generator.py for dependence, clipping and time allocation."
        if name.startswith("generator.steps."):
            note="Weaker coupling/more incidental variation than prior V2; no empirical covariance calibration."
        if name.startswith("generator.target."):
            note="Hypothetical latent score effect/noise. Keeping seven inputs does not establish seven useful academic effects."
        if name.startswith("generator.nonlinear."):
            note="Qualitative bounded-effects hypothesis; exact curve/threshold unsupported empirically; stress-tested, not optimized. Final Ridge remains linear."
        if name.startswith("generator.missingness."):
            note="Assumed whole-window failure, partly screen/fitness-dependent; no measured HealthKit availability claim. Never impute zero."
        if name.startswith("generator.measurement_sd."):
            note="Assumed independent Gaussian error in window summaries before support/time reconstraint; not device error calibration."
        if name.startswith("bounds."):
            note="Engineering support only; not healthy targets or verified population limits. Reject unsupported inputs; no input clamping at inference."
        if name.startswith("reference."):
            note="Centering/probe profile, not an optimum or training mean."
        if name.startswith("stress."):
            note="Alternative assumption; fixed before results. No fitting of caps or selection of prettier coefficients."
        if name.startswith("acceptance."):
            note="Prototype review policy, not scientifically validated clinical/educational threshold."
        rows.append([name,json.dumps(value),"config.json / pre-run PROTOCOL.md","DEVELOPMENT ASSUMPTION","Low scientific / explicit policy",note])
    rows += [
        ["Population/task","Grade12 UAE ~16–18; same subject; one test seven local days later; percentage0–100","PROTOCOL.md","DEVELOPMENT ASSUMPTION","Low transport evidence","Not a validated current-app task."],
        ["Prior-score age/definition","Comparable same-subject assessment before cutoff; <=90days","PROTOCOL.md","DEVELOPMENT ASSUMPTION","Low","Metadata validation is not implemented by numeric prediction helper."],
        ["Habit window/coverage","28 completed local days; >=21observed days each; available-day mean","PROTOCOL.md","DEVELOPMENT ASSUMPTION","Low","No day-level simulation; observed-day selection can bias averages."],
        ["Habit constructs","Noon-window sleep; daily steps/exercise/resting-HR summaries; deliberate same-subject study; recreational screen excluding study","PROTOCOL.md","DEVELOPMENT ASSUMPTION","Low","Current single-day/72-hour app semantics differ; no silent substitution."],
        ["Latent factors/dependence","Independent N(0,1) engagement,fitness,screen preference; Gaussian copula normalizes prior loading by sqrt(1-loading²)","generator.py","DEVELOPMENT ASSUMPTION","Low","No latent participant traits estimated."],
        ["Time allocation","60min/hour; proportional reduction of study/screen/exercise when daily-average budget exceeded","generator.py","DEVELOPMENT ASSUMPTION","Units exact; allocation low","School300/other180 reserved; steps overlap activity. Not a full day composition or DST duration simulation."],
        ["Clipping/measurement order","Latent bounds/time -> steps/RHR -> bounds -> Gaussian measurement noise -> bounds/time; latent target + Gaussian outcome error -> [0,100]","generator.py","DEVELOPMENT ASSUMPTION","Low","Clipping can introduce masses and error dependence; observed summaries need not equal latent targets."],
        ["Old coupling stress","70 steps/exercise minute; incidental median2000/logSD.35","Prior V2 config, generator.py","DEVELOPMENT ASSUMPTION","Low","Tests previous strongly coupled structure without fitting to NetHealth r=.636."],
        ["Output/input handling","Float64 StandardScaler/Ridge; output clamp0–100; reject missing/nonfinite/out-of-support/time-infeasible required inputs","train.py","DEVELOPMENT ASSUMPTION","High computational","No test-trained preprocessing. Seven raw features; no nonlinear inference transforms."],
        ["Export tolerances","1e-10 JSON/pipeline; 1e-9 time comparison; 1e-10 SD threshold for undefined calibration slope; V1 original1e-6 golden tolerance","train.py / evaluate.py","DEVELOPMENT ASSUMPTION","Engineering","No physical/real-data validation follows."],
        ["Uncertainty/calibration","Paired row bootstrap95% at2.5/97.5 quantiles; OLS actual~prediction; ten rank bins","evaluate.py","DEVELOPMENT ASSUMPTION","Conditional synthetic only","No school/student clusters or biological parameter uncertainty in intervals; mean slope undefined."],
        ["Pooled artifact versus stability","45000training rows pooled; 15000holdouts excluded; stability=ten independent4500-row fits","PROTOCOL.md","DEVELOPMENT ASSUMPTION","Reproducible selection","Synthetic sample size reduces simulation error, not real evidence uncertainty."],
        ["Prior-score generator slope",".8 central vs .55/.95 stress","config.json / V1 formula reference","DEVELOPMENT ASSUMPTION","Unknown real slope","V1 uses .55; neither .55 nor .8 can be called empirically correct for this task."],
        ["NetHealth result","963student-semesters/207students; wearable block ΔMAE+.00003 in GPA units, interval covers zero","Frozen local aggregate report","EMPIRICALLY ESTIMATED","Moderate within that cohort","Not rerun; known development evidence; average HR ≠RHR; no point-scale conversion."],
        ["External direction evidence","Context-dependent sleep/study/screen effects; weak activity and mixed RHR evidence","Primary sources in report","PUBLISHED EVIDENCE","Varies by construct","No transferable seven-feature coefficient vector or nonlinear curve established."],
        ["Real accuracy/causal dose response","UNKNOWN","No compatible outcome evaluation","UNKNOWN","Unknown","No UAE participant analysis, HSLS outcome inspection, or MCS/COMPASS analysis performed."],
    ]
    text="# Seven-input assumption and evidence ledger\n\nEvery config leaf and additional semantic/numerical convention is listed. Values describing real studies are not used as synthetic target slopes. No seven-input academic effect vector was empirically estimated.\n\n"+table(pd.DataFrame(rows,columns=["Parameter / relationship","Chosen value/range","Source","Evidence type","Confidence","Notes"]))+"\n"
    (HERE/"ASSUMPTION_LEDGER.md").write_text(text)
    return text


def report():
    ledger_text=ledger()
    p=json.loads((R/"new_ridge_seven_parameters.json").read_text())
    coef=pd.read_csv(R/"final_coefficients.csv")
    stability=pd.read_csv(R/"coefficient_stability.csv")
    seven=stability[(stability.scenario=="central")&(stability.model=="new_ridge_seven")].set_index("feature").loc[p["features"]].reset_index()
    metrics=pd.read_csv(R/"comparison_metrics.csv")
    central=metrics[(metrics.scenario=="central")&(metrics.output=="raw")]
    raw=metrics[metrics.output=="raw"]
    comparisons=table(central[["model","mae","rmse","r2","bias","calibration_slope","calibration_intercept"]])
    pair=json.loads((R/"paired_mae.json").read_text())
    differences=table(pd.DataFrame([{"new_seven_minus":name,"MAE difference":v["difference"],"95% lower":v["ci95"][0],"95% upper":v["ci95"][1]} for name,v in pair.items()]))
    rhr=stability[(stability.model=="new_ridge_seven")&(stability.feature=="resting_heart_rate")]
    rhrtable=table(rhr[["scenario","raw_mean","raw_std","raw_min","raw_max","negative_fraction"]])
    whatif=pd.read_csv(R/"what_if_sensitivities.csv")
    extremes=pd.read_csv(R/"extreme_profiles.csv")
    extreme_summary=extremes.groupby(["model","permitted"]).raw_prediction.agg(["count","min","max"]).reset_index()
    missing=pd.read_csv(R/"missingness_coverage.csv")
    summaries=json.loads((R/"synthetic_summary.json").read_text())
    stress=raw.pivot(index="scenario",columns="model",values="mae").reset_index()
    dev=pd.read_csv(R/"development_metrics.csv").groupby("model")[["mae","rmse","r2"]].agg(["mean","std"])
    dev.columns=["_".join(c) for c in dev.columns]
    annex="# Full seven-input comparison tables\n\nAll values describe synthetic experiments. CSV/JSON retain full precision.\n\n"
    for title,frame in [("Common central cohort",central),("All scenario MAE",stress),("Development metrics",dev.reset_index()),("Coefficient stability, all fitted scenarios",stability),("Coverage and common-cohort errors",missing),("Extreme corners",extreme_summary),("What-If approximation checks",whatif)]:
        annex+="## "+title+"\n\n"+table(frame)+"\n\n"
    (HERE/"RESULT_TABLES.md").write_text(annex)
    outcome=f"""# TwinTrack — final seven-input V2 recommendation

2026-09-21 · `{C['version']}` · **Offline research candidate only; not integrated**.

## 1. Executive decision

The requested seven-input candidate is trained and exported as **StandardScaler + Ridge, alpha {p['alpha']}**, using all seven original input names/order. It is the single predeclared pooled-training candidate, not a manually adjusted or best-seed model. Final integration recommendation: **DO NOT APPROVE at this point**.

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

Across60,000 synthetic development rows: steps/exercise correlation **{summaries['correlations']['steps']['exercise_minutes']:.6f}**, study/screen **{summaries['correlations']['study_minutes']['screen_time_minutes']:.6f}**, sleep/screen **{summaries['correlations']['sleep_hours']['screen_time_minutes']:.6f}**. These are assumed-data summaries, not empirical adolescent calibration. V1 generated inputs independently; earlier V2 steps/exercise correlation was ~.887. No attempt was made to force a match to NetHealth's .636 in a different cohort.

## 5. Full assumption/evidence ledger

{EVIDENCE}

The complete ledger is reproduced below and also saved separately as [ASSUMPTION_LEDGER.md](../ml/v2/2026-09-21-seven-input/ASSUMPTION_LEDGER.md). PUBLISHED EVIDENCE motivates possibilities; all chosen target magnitudes and distribution parameters remain DEVELOPMENT ASSUMPTIONS. Real forecast accuracy/causal dose response remain UNKNOWN.

{ledger_text.split(chr(10)+chr(10),2)[-1]}

## 6. Ridge training procedure

Protocol/config written before any training. Ten seeds2101–2110, 6,000 rows each; 4,500 training and1,500 development holdout per seed. Each fits previous-only, six-input and seven-input pipelines with training-only shuffled five-fold CV, alpha[.1,1,10,100,1000], MAE criterion. StandardScaler is fitted inside each fold, population SD; Ridge intercept is unpenalized. Original seven raw inputs, no nonlinear inference feature transforms, sign constraints or hand edits.

Final artifact uses **all45,000 training rows**, excluding all15,000 development holdout rows; fresh five-fold training-only CV seed2201. Pooling was fixed before results to reduce simulation sampling noise, not to select pretty signs. Ten seed fits measure stability; pooled coefficients are reported separately. Final evaluation uses4,000 new synthetic rows seed98001; previous-generator transport uses new seed98002, not its already-used final test. Every candidate scores identical rows within each scenario. Synthetic rows lack real school/student dependence.

Matched new previous-only/six baselines share the same45,000 training pool and procedure. Preserved `old_*` candidates retain their old generator and4,500-row training, so differences against them combine generator/sample-size changes; they cannot isolate RHR's increment. The new matched six comparison does isolate the added input under this assumed world. No complex model search.

## 7. Selected alpha

Final seven-input alpha: **{p['alpha']}**, selected by training-pool CV. Every per-seed and alternative-RHR selection is recorded in `training_cv.csv`; there is no test-based alpha selection. The earlier V1 alpha10 remains unchanged. Alpha values are not directly comparable independent of sample size/scaling; they are regularization settings, not effect sizes.

## 8. Final coefficients

The following table gives full-precision fitted parameters in exact feature order. Standardized formula is `intercept + sum(coef[i]*(x[i]−mean[i])/scale[i])`, followed by output clamp0–100. No manual coefficients are written into production.

{table(coef[['feature','mean','scale','standardized','raw']],17)}

Standardized intercept: **{p['intercept_standardized']:.17g}**. Equivalent raw intercept: **{p['intercept_raw']:.17g}**. Full precision and metadata: `new_ridge_seven_parameters.json`; serialized sklearn pipeline: `seven_input_model.joblib`. Rounded display coefficients must not be used for integration parity.

## 9. Original-unit sensitivities

Model changes in predicted assessment points, holding other inputs fixed within support. These are **not causal promises**, and adding time can require reducing another activity.

{table(coef[['feature','increment','effect']],9)}

Previous score remains by far the strongest standardized feature in all ten fits; do not weaken it to improve appearance. The central generator's .8 prior slope produces regression toward72; V1's .55 is also a synthetic choice. No compatible real data establishes whether either retention slope is correct. Prespecified .55/.95 transport stresses quantify sensitivity to that uncertainty.

## 10. Multi-seed coefficient stability

Ten independent4,500-row seven-input fits; standardized coefficient mean/sample SD/min/max and sign fractions. Sign fractions are proportions of synthetic fits, not probabilities of a real effect. All raw/effect statistics and six-input controls appear in `coefficient_stability.csv` and [RESULT_TABLES.md](../ml/v2/2026-09-21-seven-input/RESULT_TABLES.md).

{table(seven[['feature','standardized_mean','standardized_std','standardized_min','standardized_max','positive_fraction','negative_fraction']])}

Sleep/study/prior are positive10/10; screen negative10/10; RHR negative10/10 conditional on the central assumption. **Steps positive6/10, exercise positive5/10: unstable and effectively tiny.** Their maximum tested increment magnitude across seeds remains below the predeclared .5-point weak-effect threshold, which allows prototype review but does not establish stable directional advice. Never recommend less exercise when a seed gives a negative coefficient. Pooling narrows Monte Carlo error; it cannot resolve scientific uncertainty about effects.

## 11. Comparison with previous-score-only

Common central cohort, n4,000, all raw outputs; calibration regresses actual on predicted, bias is prediction−actual. Mean-only slope/intercept are undefined. Raw/clamped metrics are separately retained for every scenario in CSV.

{comparisons}

Paired bootstrap differences (new seven minus comparator; negative means lower MAE):

{differences}

The matched prior-only increment is about0.0685 MAE points. It is small even though its conditional sampling interval is below zero. The old .10-point rule would still favor simpler input selection; A's new constraint retains seven for product reasons. Bootstrap uncertainty covers simulated rows, not the uncertain target equation. The final cohort has now informed this review and is not untouched evidence for later iterations.

## 12. Comparison with six-input V2

Preserved old-six and matched new-six are both included. Seven's improvement versus the matched six is only about0.00226 MAE points and its interval crosses zero: **no established meaningful incremental RHR accuracy**. Do not credit seven for comparisons against a smaller, differently trained old-six alone. Synthetic missingness coverage and same complete-seven cohort errors are in `missingness_coverage.csv`; comparing own-eligible errors across different samples would be misleading. All seven remain required under this candidate, so missing RHR still causes abstention; no fake zero or optional-input substitution is proposed.

{table(missing[missing.cohort=='model_eligible'][['model','n','coverage']])}

These coverage rates are assumed-device/missingness simulations, not observations from TwinTrack users.

## 13. Comparison with frozen V1

V1 remains frozen. Reconfirmed original audit: alpha10, MAE4.76146176524888, RMSE5.868372602783463, R².5704285621846623 on its original200-row synthetic holdout. The old prior-only OLS R² was.5496868479533286. Those are different-generator metrics, not a scorecard against new V2's MAE. On the common new scenario V1 underpredicts partly because its imposed task/target relationship differs. The common table is transport testing, not proof of better real grades.

All stress/transport MAEs for fixed candidates:

{table(stress)}

Null effects, higher noise, prior-retention shifts, changed measurement error, old activity coupling and opposite RHR/sleep assumptions expose dependence on unvalidated design choices. Models are not re-tuned on these final stress outcomes. Separate RHR refits below answer a different question: what if the assumed training signal changes?

## 14. RHR interpretation

Keep RHR as A requested, with a small fitted coefficient. Pooled +5bpm gives approximately−.1334 predicted points. Central sign stability10/10 is a conditional numerical result, **not new real-world evidence**. Refitting the same seed designs under changed RHR target assumptions yields:

{rhrtable}

With zero assumed direct RHR effect, signs split5/5; with positive signal all turn positive. This demonstrates dependence on the chosen effect rather than confirmation of physiology. NetHealth cannot calibrate this because its HR is not resting HR. RHR may chiefly serve wellbeing context even while retained in the prediction schema. No attempt was made to enlarge its academic coefficient to make it useful visually.

## 15. What-If behavior

All reported single-input raw changes are constant across ordinary profiles because raw-input Ridge is linear. Output clamping can flatten changes at boundaries. The tested final profiles for each increment are filtered by bounds/joint time feasibility. The generator-change column is a diagnostic of an assumed nonlinear equation on the same numeric profiles, not an empirical counterfactual effect.

{table(whatif)}

Important limitation: the exported model still adds ~.447 points for sleep9→10h although the generator plateaus; still gives a small exercise effect above60m and a screen penalty below120m. Nonlinear training targets do not make linear inference nonlinear. Do not state that the model enforces saturation or a harmless-screen threshold. Modifying inference transforms would require a different model/export and is not smuggled into this seven-raw-input pass.

Research support: sleep5–10h; steps1,000–18,000; exercise0–120m; RHR45–100bpm; study0–300m; screen0–480m; prior0–100. These are engineering limits, not recommended health targets. Reject unsupported values and impossible time budgets; no inference input clamping. Prior score should remain fixed during habit What-If. Steps/exercise overlap and time displacement make independent slider interventions noncausal. A change to a28-day mean does not represent one day's action. Near-zero steps/exercise deltas may round to0.0 in the app; do not amplify them for appearance.

## 16. Extreme-case testing

Every candidate evaluated at all128 seven-dimensional bound corners; time-infeasible profiles are marked rejected, not silently accepted. The prior-only/mean corners include duplicate effective inputs. Full per-profile results retained; these probes are numerical stress tests, not likely student profiles.

{table(extreme_summary)}

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

Proposed arithmetic only, **not authorization to integrate**. Artifact version `{p['model_version']}`; feature order preserved. Use Double throughout, population-SD scaler and output clamp0–100. No generator transformations in inference. Exact arrays:

```json
{json.dumps({k:p[k] for k in ['features','mean','scale','coefficients_standardized','intercept_standardized','coefficients_raw','intercept_raw','alpha','output_clamp','task']},indent=2)}
```

Before a separately approved port: resolve timing/subject/date/coverage contract; independently audit parameters and generate new V2 Swift golden profiles; retain V1 predictor/artifacts for rollback and immutable history; version model/task provenance in snapshots/tools; preserve real-baseline/What-If isolation; align missingness and input bounds; document experimental/noncausal status. Then run full app regressions and A's physical review. None of those production changes occurred here.

**Final recommendation: DO NOT APPROVE FOR IOS INTEGRATION yet.** Seven-input research candidate and required artifacts are ready for A's review; input-window compatibility and What-If interpretation remain unresolved. Exact files/hashes: [FILE_INVENTORY.md](../ml/v2/2026-09-21-seven-input/FILE_INVENTORY.md). Prior V1, prior V2 and all iOS files are preserved. Nothing staged, committed or pushed.
"""
    (ROOT/"docs/V2_SEVEN_INPUT_FINAL_RECOMMENDATION.md").write_text(outcome)


def inventory():
    files=[p for p in HERE.rglob("*") if p.is_file() and "__pycache__" not in p.parts and p.name!="FILE_INVENTORY.md"]
    files.append(ROOT/"docs/V2_SEVEN_INPUT_FINAL_RECOMMENDATION.md")
    rows=[[str(p.relative_to(ROOT)),p.stat().st_size,hashlib.sha256(p.read_bytes()).hexdigest()] for p in sorted(files)]
    (HERE/"FILE_INVENTORY.md").write_text("# Exact new-file inventory\n\nAll listed files are new. This inventory itself is also new and excluded from its own hash list. Previous work and production files are unchanged. Generated Python caches are excluded.\n\n"+table(pd.DataFrame(rows,columns=["Repository-relative path","Bytes","SHA-256"]))+"\n")


if __name__=="__main__":
    report()
    inventory()
