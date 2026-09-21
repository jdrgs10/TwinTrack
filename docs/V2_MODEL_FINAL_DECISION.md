# TwinTrack V2 model final decision — offline candidate review

Date: 2026-09-21. Experiment: `2.0-candidate.1`. Status: **offline evaluation complete; production replacement NOT approved**.

This report supersedes the preparation/status statements in `V2_MODEL_DECISION_DRAFT.md`, which remains an unchanged historical draft. No Swift, UI, HealthKit, assistant, production model, frozen parameter, or V1 golden-profile file was edited. Nothing was staged, committed, or pushed. All new observations are **EVIDENCE-INFORMED SYNTHETIC DATA**, not real students. Their numerical distributions/effects are development assumptions.

## 1. Executive recommendation

**Recommend the previous-score-only StandardScaler + Ridge as the provisional V2 predictive research candidate. Do not replace deployed V1 yet.** It is the simplest candidate under the selection rule written before training. Retain the six-input and seven-input exports as comparison artifacts.

The six-input model is the preferred *multivariable* candidate, but its 0.073997-point MAE improvement over previous-score-only does not meet the predeclared 0.10-point complexity threshold. Its paired interval excludes zero, so the gain is small rather than absent. Seven inputs offer no reliable improvement over six; RHR's coefficient is unstable. **Remove RHR from the proposed prediction contract and keep it available as optional wellbeing information**, subject to A's integration approval. This recommendation does not assert that RHR has no academic association in real people.

There is a product consequence: the selected one-input candidate cannot support grade-changing lifestyle What-If sliders. Those would leave its prediction unchanged. Do not silently swap it beneath the current seven-input UI or present six-input simulations as scientifically validated habit advice. A must approve that product tradeoff before any integration; further representative real-data evaluation remains necessary for scientific deployment claims.

## 2. V1 audit

Confirmed directly from `ml/src/generate_data.py`, training/tuning/baseline/validation scripts, `ml/data/synthetic_students.csv`, saved artifacts/results, frozen export, and `ios/twintrack/twintrack/TwinTrackModel.swift`. The audit regenerated the dataset **in memory**, reconstructed the original split/tuning, and compared saved pipeline predictions to frozen JSON. No production-writing script was executed.

The 1,000 independent synthetic rows use RNG seed 42. Inputs are independently sampled clipped normals:

| Input, exact frozen order | Normal mean / SD | Generator bounds |
| --- | --- | --- |
| sleep_hours | 7 / 1.2 | 4–10 hours |
| steps | 7,000 / 2,500 | 1,000–18,000 |
| exercise_minutes | 30 / 20 | 0–120 |
| resting_heart_rate | 68 / 9 | 45–100 bpm |
| study_minutes | 90 / 50 | 0–300 |
| screen_time_minutes | 240 / 90 | 30–600 |
| previous_score | 75 / 12 | 30–100 |

Unrounded target = `18 + .9*sleep + .00025*steps + .025*exercise − .035*(RHR−65) + .035*study − .012*screen + .55*previous + N(0,6)`, then clamp 0–100. CSV rounds sleep to two decimals, steps to integers, other inputs/target to one decimal. This is an assumed development formula, not an empirical educational equation. Its real assessment, subject and forecast horizon are undefined.

Split: 800 training / 200 test, seed 42. Tuning: shuffled five-fold training-only CV, seed 42, MAE, alpha `[.01,.1,.5,1,2,5,10,20,50,100]`. StandardScaler is inside the pipeline; population SD and means match training data exactly. Selected alpha 10; reproduced CV MAE 4.636596102141. Largest standardized coefficient refit difference: 8.88e-16. Saved-model/frozen-copy/JSON prediction differences: zero.

| Original V1 holdout, same 200 rows | MAE | RMSE | R² |
| --- | --- | --- | --- |
| Mean-only | 7.1444925 | 8.9537834 | −0.0000304 |
| Previous-score-only OLS | 4.8014991 | 6.0083787 | 0.5496868 |
| Frozen V1 Ridge | **4.7614618** | **5.8683726** | **0.5704286** |

The old seven-input MAE increment is only 0.0400374 points on this previously used synthetic split. No independent real-world improvement follows. V1 target mean/SD: 67.91/9.09274; prior score: 75.1114/12.16311. Input correlations reflect independent generation (steps–exercise −.021806; study–screen +.021873); prior–target correlation .725949. Full summaries/correlations are in `v1_audit.json`.

V1 learned raw slopes, in points per input unit: sleep .884741; steps .000345063; exercise .0269518; RHR **+.0275440**; study .0325557; screen −.0102923; prior .531692. RHR's positive fitted sign opposes its negative generator coefficient: a warning against treating a small estimated association as physiological truth. Swift uses the frozen StandardScaler formula then clamps 0–100; clamping changes none of the original holdout predictions.

**Golden checks: 21/21**, Python frozen-JSON arithmetic against existing golden outputs, maximum error 7.105427357601002e-15, tolerance 1e-6. This is not a new Swift execution. All 94 protected tracked V1/iOS files retain their pre-experiment SHA-256 hashes. Three distinct pickle compatibility warnings were recorded: saved scikit-learn 1.9.0 versus runtime 1.8.0, for Pipeline/Ridge/StandardScaler. Independent formula/refit checks passed; no warning is hidden or represented as zero warnings.

## 3. Research evidence summary

### Evidence classification and provenance

| Item | Classification | Actual status / permitted use |
| --- | --- | --- |
| Local `NetHealth_Final_Report.md` | COMPLETED ANALYSIS; project real-data aggregate report | Completed/frozen; read only, not rerun; development consistency evidence |
| Local `TwinTrack_Dataset_Strategy_2026-09-05.pdf` | STRATEGY / LITERATURE / DATASET REVIEW | 22-page planning document, not completed participant-level results |
| HSLS:09 | DATASET DOCUMENTATION / planned evaluation | **NOT ANALYZED AGAINST TWINTRACK**; no outcomes inspected or used |
| MCS project work | RESEARCH / ACQUISITION PLAN | Historical planning; original plan unavailable locally; **NO completed TwinTrack participant-level analysis** |
| COMPASS project work | CANDIDATE / RESEARCHED | **NO completed TwinTrack participant-level analysis** |
| External MCS/COMPASS papers below | PUBLISHED EXTERNAL RESEARCH | Authors' findings only; do not relabel as TwinTrack studies |
| New generator/experiment | DEVELOPMENT ASSUMPTIONS / SYNTHETIC RESULTS | Numerical stress-testing, not real validation |

Local files remain under `.twintrack-local/research/`, excluded through `.git/info/exclude`, not copied into tracked folders. Provenance hashes: NetHealth report `8c1b17ef20c1ca5f9f909b643c9ddaacd9991dcb3018630677430876e7abcfdb`; strategy PDF `0bdb6ff4272bebf97b2f82f329cb1782a837c047e3073fc7cb971fd383f8224f`. Referenced underlying NetHealth panel/fold/exclusion CSVs were not supplied; aggregate findings are verified against the saved report, not independently recomputed here.

### Frozen NetHealth findings

963 student-semesters, 207 students, seven target terms; ten repeated student-grouped five-fold evaluations with nested grouped alpha selection. Outcome is an unweighted course grade-point average on 0–4, not a UAE assessment percentage. Baseline A uses prior-term performance; B adds early-semester 28-day sleep, steps, MVPA and **average daily HR, not resting HR**. It does not include TwinTrack study/screen inputs.

Fold-average A: MAE .17127, RMSE .23888, R² .52495. B: MAE .17130, RMSE .23941, R² .52314. B−A: MAE +.00003, RMSE +.00053, R² −.00181. The saved report's student-cluster bootstrap intervals cover zero: MAE [−.00112,+.00099], RMSE [−.00050,+.00140], R² [−.00503,+.00209]. Its separately pooled bootstrap MAE point is −.00006; pooled R² A .54504/B .54292. **Pooled estimates and fold means are different summaries and must not be conflated.** Zero of three preregistered improvement conditions passed. Prior standardized coefficient ≈.262 versus largest wearable ≈.013; wearable-only R² −.013.

Limitations: one US college cohort, 35.1% complete-case attrition from 1,483 eligible rows, 12.3% target ceiling, no formal power analysis, limited compatible constructs. This is evidence for strong prior performance and a small/unestablished wearable increment in that study; not proof of universal null effects. Never rescale its GPA errors into a TwinTrack 0–100 accuracy claim. Because it informed this generator, NetHealth is already known development evidence, not a pristine V2 test set.

### Published primary sources used

- [Okano et al., 2019](https://www.nature.com/articles/s41539-019-0055-z): wearable sleep over weeks/months associated with college performance; single pre-test night was not the relevant finding. Prior-attainment-adjusted transfer to this task is not established.
- [Creswell et al., 2023](https://doi.org/10.1073/pnas.2209123120): multi-cohort college sleep study; association with subsequent GPA after prior GPA adjustment. Supports considering accumulated sleep, not transferring a GPA/hour slope to Grade 12 test points.
- [Stinebrickner & Stinebrickner, study effort natural experiment](https://www.nber.org/papers/w13341): context-specific instrumental-variable evidence on college study effort. Supports study as a plausible influence; no universal minutes-to-percentage coefficient follows.
- [Papasideris et al., 2021, COMPASS](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0253142): linked adolescent self-reported activity and Math/English grades with corresponding prior grades controlled; associations were trivial/null. [Published correction](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0259618) concerns references and does not supply TwinTrack validation.
- [Maloney et al., 2026, MCS](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0346302): adolescent time-diary compositions and later Attainment 8; mixed associations depending on displaced activity, including an adverse sleep association. Listed covariates do not establish prior-attainment adjustment. Do not translate compositional substitutions into independent Ridge slopes or recommend less sleep.
- [Poulain et al., 2018, LIFE Child](https://link.springer.com/article/10.1186/s12889-018-5489-3): longitudinal media/activity associations controlling baseline grades; results vary by activity and subject. Self-reported media categories differ from TwinTrack's proposed recreational screen minutes.
- [Tharion et al., 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10660775/): small medical-student resting ECG/academic study; no overall RHR association established. HRV subgroup findings are not RHR evidence and do not demonstrate incremental prior-adjusted prediction.
- [Benítez-Agudelo et al., 2025](https://link.springer.com/article/10.1186/s40359-025-03041-z): 115 Colombian university psychology students; end-semester RHR associated negatively with performance. Sex/age adjustment does not establish incremental prediction beyond prior attainment. Timing, population and 1–5 test scale differ from this proposal; coefficient is not imported.

This is a focused evidence review, not a systematic review or proof that no other relevant studies exist. No participant data from these papers was obtained or analyzed.

## 4. Final prediction-task definition

This is a **proposed research contract**, fixed before training; it is not the existing app's measurement contract.

| Aspect | Definition |
| --- | --- |
| Population | UAE Grade 12 students, approximately 16–18, one specified subject/course and comparable assessment format |
| Target | Percentage score 0–100 on one same-subject assessment exactly seven local calendar days after prediction cutoff |
| previous_score | Most recent comparable same-subject assessment, completed before cutoff and no more than 90 days old |
| Lifestyle period | Arithmetic mean over 28 completed local calendar days immediately before cutoff |
| Sleep | Completed noon-to-noon sleep windows assigned to their ending day; hours/day |
| Steps / exercise | Completed-day summaries, count/day and minutes/day |
| RHR comparison candidate | Mean of valid daily resting-HR summaries in that 28-day period; not average daily HR or latest 72-hour sample |
| Study / screen | Same-subject deliberate study outside class / recreational screen minutes; exclude study screen time and simultaneous double counting |
| Missingness | At least 21 observed days per required habit; otherwise abstain. No fabricated zero. Previous-only requires valid prior-score/subject/date metadata, not habits. |

The seven-day forecast, 90-day prior age, 28-day period and 21-day threshold are explicit development assumptions. Multiweek sleep literature motivates aggregation qualitatively; it does not estimate those particular choices. The simulator generates window-summary rows, not daily trajectories, so daily completeness and calendar handling remain unvalidated. Available-day averaging can itself be biased. Current app values must not be relabeled as 28-day means.

## 5. Feature-by-feature evidence table

Sources are linked in section 3; the distinctions below are essential to their interpretation.

| Feature | Evidence for later attainment / direction | After prior attainment? | Causal status | Measurement mismatch | Confidence in transferable numeric weight |
| --- | --- | --- | --- | --- | --- |
| previous_score | Strongest available project predictor; positive persistence | It is the baseline itself | Predictive, not a manipulable intervention | College term GPA versus comparable Grade 12 subject test | Moderate for priority; low for exact slope |
| study_minutes | Plausible positive effort effect; context-specific quasi-experimental college evidence | No compatible incremental TwinTrack estimate established | Some IV evidence under its assumptions; not universal causal dose | Diaries/college effort versus 28-day same-subject deliberate study | Low |
| sleep_hours | Positive in several college studies; mixed adolescent time-substitution evidence | Some college evidence yes; saved NetHealth increment small; MCS adjustment not established | Mostly observational; confounding/reverse causality remain | Wearable months/weeks or time diaries versus proposed window | Low |
| screen_time_minutes | Often negative for some recreational media/subjects; mixed displacement results | Some longitudinal baseline-grade-adjusted evidence | Observational, activity/content dependent | Total/category screen exposure versus recreational-only minutes | Low |
| exercise_minutes | Small/mixed/null academic association; wellbeing value does not imply grade slope | Prior-adjusted COMPASS and NetHealth do not show robust useful increment | Association is not a grade intervention effect | Self-reported MVPA/device active minutes versus Apple exercise minutes | Very low |
| steps | Little compatible direct academic evidence; overlaps exercise | NetHealth contribution not useful as part of wearable block | Noncausal proxy | College wearable daily steps versus proposed secondary-student window | Very low |
| resting_heart_rate | Limited/mixed small university studies; some negative association | Compatible prior-adjusted incremental RHR value not established; NetHealth HR is different | Proxy/confounding, not causal treatment target | Resting ECG/semester-end measurement versus HealthKit summaries | Very low |

No correlation, odds ratio, standardized beta, compositional replacement coefficient or GPA slope has been converted to a common assessment-point scale. Every numerical target slope below is a development assumption.

## 6. Resting-heart-rate recommendation

**Exclude RHR from V2 academic prediction; retain optional wellbeing display.** This is preferable to making RHR mandatory merely to fill a seventh feature.

Reasons together: no established compatible prior-attainment-adjusted academic increment; seven-input synthetic MAE is slightly worse than six; seven beats six on both MAE/RMSE in only 2/5 development seeds; RHR slope is positive in 2/5 fits and negative in 3/5; no defensible advice follows from its sign. Under explicitly assumed missingness, coverage falls from 64.85% (six) to 41.00% (seven). Those are simulation rates, not measured Apple Watch availability.

Central generation assigns zero direct RHR effect, so central results alone cannot justify exclusion scientifically. Nonzero-effect sensitivity cases in section 12 show ranking can change. Keeping RHR visible still provides user value without claiming an academic effect. Prediction removal requires updating eligibility, schemas, explanations and history versioning, not deleting HealthKit readings or rewriting old snapshots. No such integration was performed.

## 7. V2 synthetic-generator specification

All numeric parameters are in versioned `config.json`. Three independent standard-normal latent factors represent engagement, fitness and screen preference. Sleep uses a bounded Gaussian relationship; study and screen use skewed lognormal relationships; exercise uses a skewed Gamma/fitness relationship. Study/exercise include assumed 5% latent zeros. Previous score uses a scaled Beta(9,3.5), weakly coupled to engagement through a Gaussian copula, rather than an independent clipped normal. Steps include exercise-related and incidental components. RHR depends on latent fitness/sleep plus noise.

Sleep, study, screen and exercise obey a joint budget: `60*sleep + study + screen + exercise <= 1,440 − 300 school − 180 other` minutes. Over-budget primary activities are proportionally reduced. Steps overlap physical activity, not additional time. This simplifies a daily average and is not a complete time-use composition. Gaussian measurement errors are added to latent summaries, followed by bounds/time checks. True target generation uses latent values; models receive noisy observed values.

Central latent target before clamp:

`72 + .8*(previous−72) + .5*(sleep−7.5) + .015*(study−90) − .004*(screen−210) + N(0,8)`.

Direct steps/exercise/RHR effects are zero in the central assumption. All slopes, distributions, loadings and noise scales are hypothetical; no “best-looking” noise or seed was selected. Inputs are dependent; outcome exhibits assumed regression to the mean. Missingness is a separate whole-window mask with shared wearable failures and screen/fitness dependence, never zero imputation.

For seed 1101, generated means are sleep 7.508 h, steps 7,039, exercise 34.395 min, RHR 69.939 bpm, study 82.097 min, screen 228.241 min, previous score 72.241. Correlations: steps/exercise .887, study/screen −.332, sleep/screen −.433, prior/target .759. These are **simulation summaries, not empirical calibration**. The activity correlation is stronger than saved NetHealth .636, illustrating remaining covariance uncertainty. These mechanisms address V1's independent-input weakness but do not establish population realism.

## 8. Assumption/source ledger

See [ASSUMPTION_LEDGER.md](../ml/v2/2026-09-21/ASSUMPTION_LEDGER.md): every config leaf plus task, structure, transformations, missingness, support, numerical tolerances, selection rules and unknowns has value/range, source, evidence category, confidence and notes. Categories distinguish EMPIRICALLY ESTIMATED, PUBLISHED EVIDENCE, DEVELOPMENT ASSUMPTION and UNKNOWN.

The immutable [PROTOCOL.md](../ml/v2/2026-09-21/PROTOCOL.md) and config preceded training. One reporting deviation: endpoint export probes use the declared reference profile, rather than the training mean described in the protocol. Corner checks still enumerate the entire bounds grid. No task parameter, seed, generator slope, hyperparameter grid or selection threshold changed after results were seen.

## 9. Candidate comparison

Five independent 6,000-row development cohorts, seeds 1101–1105, each 4,500 training / 1,500 development holdout. Training-only five-fold CV with fold-local scaling selects alpha `[.1,1,10,100,1000]` by MAE. All fitted candidates selected .1. Seed 1101 was preselected for export; no best-seed picking, no holdout refit. One independent 2,000-row synthetic cohort, seed 97001, evaluates all five candidates on identical rows.

| Independent synthetic central test | MAE | RMSE | R² | Bias: prediction−actual |
| --- | --- | --- | --- | --- |
| Frozen V1, transported unchanged | 8.154576 | 10.116371 | .365240 | −4.952993 |
| Mean-only | 10.211532 | 12.701708 | −.000656 | −.325125 |
| Previous-score-only Ridge | **6.651097** | **8.253290** | **.577512** | −.137129 |
| Six-input Ridge | 6.577101 | 8.167940 | .586205 | −.163153 |
| Seven-input Ridge | 6.581027 | 8.173222 | .585669 | −.168413 |

Raw/clamped metrics are identical in every sampled evaluation cohort. Bound extremes below can require clamping. Calibration fits actual score against raw prediction: prior-only slope .993019/intercept .638749; six .993129/.656696; seven .992245/.725431; V1 1.242851/−11.328701. Mean-only slope is undefined. Decile means and bias are retained in `calibration.csv`; no calibration correction was fitted on test data.

**Do not compare V1's original MAE 4.76146 with V2's 6.65110 as a model ranking.** The outcome equation, noise, distribution, exposure period and task changed. Frozen V1 on these common V2 rows is an assumption-transport stress test, not a fair scientific validation of V2 superiority in students. V1's underprediction reflects, in part, the imposed target shift.

## 10. Six-input versus seven-input results

Seven−six paired MAE difference: **+.0039261**, synthetic row-bootstrap 95% interval **[−.0006263,+.0084346]**, 2,000 paired resamples. No reliable central gain. Six and seven development mean MAEs: 6.503670 and 6.504370. Seven beats six on both MAE/RMSE in 2/5 seeds.

Seven-input RHR slope across seeds: mean −.001933, SD .019481 points/bpm, range [−.024388,+.020189], positive 40%. Seed-1101 slope is −.0159507 points/bpm: +10 bpm changes its score by −.159507 points, holding others fixed. It is not stable enough to interpret as advice.

Six-input raw slopes across seeds also reveal problems: steps changes sign (positive 4/5); exercise is negative 5/5 despite zero direct exercise effect in the generator. Correlated/noisy proxies can yield counterintuitive conditional slopes; this does not establish that reducing exercise improves grades. No sign was manually flipped to improve appearance.

## 11. Baseline comparison

Six−prior paired MAE difference: **−.0739967**, 95% interval **[−.1195146,−.0291787]**. Seven−prior: **−.0700707**, interval **[−.1160309,−.0246295]**. Both improve MAE/RMSE in all five development cohorts; both fail the prespecified **at least .10-point** extra-feature requirement on the independent cohort. Previous-only improves MAE by 3.560435 points over mean-only in this assumed data-generating process.

The .10 criterion is an engineering complexity policy, not a scientific minimum important difference. A retrospectively lowered .05 policy would select six on these results; that sensitivity must be disclosed, not silently used to switch the winner. Bootstrap intervals quantify synthetic sampling, not uncertainty about actual students or the generator's effects. The cohort is now used for this final selection decision and must not be reused as an untouched final test for later model iterations.

## 12. Sensitivity and robustness results

Full tables: [RESULT_TABLES.md](../ml/v2/2026-09-21/RESULT_TABLES.md). Same central-trained candidates, no refitting, common random inputs/noise except the explicitly shifted population.

| Prespecified scenario | Prior-only MAE | Six MAE | Seven MAE |
| --- | --- | --- | --- |
| Central | 6.651097 | 6.577101 | 6.581027 |
| No direct lifestyle effects | 6.588014 | 6.631055 | 6.634420 |
| Doubled lifestyle effects | 6.851364 | 6.661419 | 6.664863 |
| Opposite sleep direction | 6.654210 | 6.631486 | 6.634871 |
| Noise SD 6 | 5.119926 | 5.023311 | 5.028152 |
| Noise SD 12 | 9.694987 | 9.643118 | 9.647021 |
| Direct RHR −.2 | 6.713860 | 6.613172 | 6.604037 |
| Direct RHR +.2 | 6.762319 | 6.708074 | 6.722616 |
| Assumed saturation | 6.626531 | 6.588599 | 6.592658 |
| Lower prior / less sleep / more screen | 6.691486 | 6.606623 | 6.610706 |

Exact full-precision source is `metrics.csv`; tables are rounded. Rankings depend on assumed effects: under null habits prior-only wins; under doubled habits six gains ~.190 points; with negative RHR signal seven modestly improves over six. This stress experiment does not test how well a model retrained on a different true population could recover that signal.

Nonlinearity: outcome-only stress caps sleep/study/exercise/screen at assumed 8 h/180 min/60 min/240 min. Exercise cap has no effect under its central zero coefficient. No empirically transferable curve or optimum was established, so no nonlinear feature transform was adopted. Avoid implying unlimited benefit, a scientifically optimal sleep duration, or causal substitution from a fitted linear slope.

Development holdout mean ± SD MAE: prior 6.590356 ± .148785; six 6.503670 ± .154158; seven 6.504370 ± .153329. Stability across these seeds does not cover different schools, grade systems, covariance structures, time trends or omitted confounders.

Missingness: 820/2,000 complete-seven rows; on those same rows MAE prior 6.556712, six 6.504124, seven 6.510040. Common-six rows total 1,297, prior MAE 6.566330 versus six 6.473805. Own eligible coverage: prior 96.25%, six 64.85%, seven 41%. Do not compare accuracy on those different eligible populations as a feature-gain estimate. No imputation, missing-as-zero or fabricated metric was used.

Extreme bounds: 128 corners per candidate; six/seven reject 56 time-infeasible combinations each, leaving 72 allowed corners. Allowed raw prediction ranges: six [9.880678,100.851388], seven [9.416931,101.204801]; upper output clamp therefore matters. Prior-only has only two distinct corner predictions, [14.301821,93.791562]; irrelevant lifestyle corners duplicate them. Numeric finite/bounds checks do not prove statistical support for every allowed combination. Many corners are far outside typical training density.

Validation: see [VALIDATION.md](../ml/v2/2026-09-21/VALIDATION.md). The complete experiment reproduced all 26 result files byte-for-byte; V1/iOS hashes remained unchanged. Model export formula comparisons passed at 1e-10. This does not replace a future independent Swift audit.

## 13. Recommended final V2 candidate

**Provisional research winner: `previous_only_candidate.json`.** StandardScaler + Ridge, alpha .1, one feature `previous_score`, version `2.0-candidate.1`, trained on preselected seed-1101 training rows only. Artifact explicitly records `synthetic_only: true` and `deployment_approved: false`.

Raw equivalent: **14.301820868795737 + .7948974159639575 × previous_score**, then clamp 0–100. A ten-point higher comparable prior score changes the model prediction by **7.948974 points**. It does not mean an intervention raising a prior grade causes that future gain. Unit changes in sleep/activity/study/screen/RHR have zero effect because those are not inputs to this candidate.

For review only, the six-input artifact retains this exact order: sleep_hours, steps, exercise_minutes, study_minutes, screen_time_minutes, previous_score. Its readable seed-1101 sensitivities, holding all others fixed and respecting bounds, are:

| Change | Six-input predicted-point change | Interpretation warning |
| --- | --- | --- |
| Sleep +1 hour | +.473005 | Conditional simulation, not a sleep intervention estimate |
| Steps +1,000 | +.203131 | Overlaps exercise; sign unstable across seeds |
| Exercise +30 minutes | −.372463 | Counterintuitive conditional slope; do not advise reducing exercise |
| Study +60 minutes | +.794494 | May violate time budget unless another activity decreases |
| Screen −60 minutes | +.182712 | Effect depends on displaced activity in real life |
| Previous score +10 points | +7.822844 | Prior attainment is not a lifestyle control |

This multivariable artifact is not silently substituted for the selected simpler model to preserve product appearance. All three exports retain means/scales, standardized/raw coefficients, intercepts, support bounds and explicit feature order at full precision. Python endpoint fixtures are not yet Swift golden parity evidence.

Replacement gates: reproducibility/transparency/simple deterministic export **PASS**; meaningful extra-feature increment **FAIL**; RHR stability/evidence **FAIL**; representative population/window validation **NOT ESTABLISHED**; prospective calibration/missingness validation **NOT ESTABLISHED**; independent Swift integration/parity and A approval **PENDING**. Therefore **no production replacement is authorized by this result**.

## 14. What-If ranges and limitations

For the selected prior-only model, do not offer lifestyle sliders that claim to improve grades. Retain wellbeing information separately and decide the future What-If product contract with A. Existing V1 What-If is untouched, not relabeled V2.

If A separately approves an explicitly experimental six-input simulator, use the following conservative **engineering support bounds**, not healthy targets: sleep 5–10 h/day; steps 1,000–18,000/day; exercise 0–120 min/day; study 0–300 min/day; recreational screen 0–480 min/day; valid prior score 0–100. Prior score should remain fixed in habit scenarios; RHR has no prediction control. Reject unsupported values, rather than silently clamping inputs. Output clamp is separate.

Respect the joint time budget, disclose when added time requires displacement, and avoid treating extra steps/exercise as independent interventions. A 28-day mean cannot be changed by one night's action. Scores near extremes and rare feature combinations remain extrapolations even inside rectangular bounds; the synthetic training prior minimum is about 21.29 despite the declared 0–100 support. Bounds are not empirically validated generalization limits. No automatic habit optimizer or causal grade recommendation is justified.

## 15. Remaining scientific limitations

- No compatible UAE Grade 12 dataset, real V2 holdout, prospective calibration or empirically estimated point-scale effect. Neither V1 nor this candidate has demonstrated real forecast accuracy for the newly defined task.
- NetHealth is a known college development result, not a V2 test. Its average daily HR cannot validate RHR. No HSLS/MCS/COMPASS TwinTrack participant analysis was performed.
- Distributions, correlations, effect sizes, missingness, noise and timing thresholds are assumptions. Only a limited predeclared set was stressed; latent covariance and measurement-error structures were not exhaustively varied.
- Window-summary simulation lacks real timestamps, missing-day patterns, repeated-student/school clusters, local assessment comparability, socioeconomic confounding and time-varying drift. A grouped/temporal real evaluation protocol is still needed.
- A prior-only numerical slope learned from an assumed target is itself provisional. Simplicity does not make the synthetic calibration empirical.
- Six-input conditional exercise/steps behavior is unsuitable for causal habit advice; simple linearity/clamping does not resolve this.
- Available-day means, construct mismatch and score age can bias predictions; numeric export checks do not enforce the proposed metadata gates.
- No formal systematic search, precision/power guarantee, demographic fairness validation or causal effect estimation. More complex models would not repair these evidence gaps.

Before any later HSLS analysis, freeze variable mapping, exclusions, preprocessing, baseline, evaluation questions and grouped/temporal split protocol **before examining outcomes**. Do not fill absent lifestyle constructs with zero. MCS acquisition planning may proceed only under a separately approved task; original historical plan remains unavailable locally.

## 16. Exact proposed iOS integration changes — approval required

These are a future plan, not edits in this milestone. A must first approve the one-input recommendation and its What-If consequences, or explicitly choose further six-input research instead. Approval to integrate an experimental prototype would not establish scientific validity.

| File/area | Proposed change if approved |
| --- | --- |
| New versioned V2 export and independent audit | Lock approved parameters/task metadata, publish separate V2 golden fixtures, retain all V1 data/parameters/fixtures unchanged; independent Python/Swift raw and clamped parity |
| `TwinTrackModel.swift` | Keep V1's seven-feature enum/profile/formula intact for historical/rollback use. Introduce a separately versioned predictor with the approved V2 input schema; never reinterpret V1 indices. |
| `TwinTrackState.swift` | Separate current model eligibility from wellbeing display completeness; require valid subject/prior-assessment date and target date. Prior-only prediction must not depend on RHR or habit availability. Preserve explicit Run Prediction lifecycle and one authoritative state. |
| `ProfileView.swift` ManualInputsSheet / `TwinTrackState.swift` input validation | Add approved subject/comparability/date metadata to previous score; retain user data. If a six-input research model is chosen later, collect actual documented habit-window summaries instead of relabeling single entries. |
| `HealthData.swift` / `HealthKitService.swift` | For prior-only, no need to change existing read semantics for optional wellbeing display. Six/seven research integration would require a separate approved 28-day aggregate/completeness contract with DST, missingness and sleep-window tests. |
| `HomeView.swift` | Report model version, task/horizon, experimental status and correct required-input messages; optional missing wellbeing data must not become a missing prior score. Do not claim real accuracy from synthetic MAE. |
| `WhatIfScenario.swift` / `WhatIfView.swift` | Resolve A's product choice; do not display false lifestyle score changes for prior-only or silently mix a V1 baseline with V2 scenarios. Experimental six-input behavior requires joint support checks and noncausal wording. |
| `AssistantTools.swift` / `AssistantProvenance.swift` / `AssistantResultCard.swift` | Version snapshot/tool input contracts and deterministic calculator provenance; remove universal seven-required-input assumptions for V2 while preserving Watch reads, safety and saved historical cards. |
| `PredictionHistory.swift` / `ConversationLibrary.swift` | Persist model/task/window provenance and schema version; backward-compatible decoding of immutable V1 snapshots/cards. Never recompute old results using V2 or overwrite real history. |
| `ProfileView.swift` / `ContentView.swift` Model Information and methodology copy | Accurate approved input count, optional RHR status, target/window description, synthetic-only evidence limitations; remove stale seven-input claims only where describing V2. |
| Unit/UI tests and documentation | New V2 parity/eligibility/support/history migration/tool-version tests, full V1 rollback and existing assistant/UI regressions, then physical review. No device identifiers or real health records in fixtures. |

The current app's seven-value profile, one-day/72-hour readings, explicit-run provenance and unversioned model assumptions cannot be fixed by replacing a coefficient array alone. The new metadata/window requirements are a separate approval scope; no architecture rewrite is proposed here.

## 17. Presentation-safe claims

- “We preserved the frozen V1 and compared five candidates on common synthetic scenarios under a written protocol.”
- “The saved NetHealth analysis found prior performance dominated, with no useful demonstrated increment from its available wearable block in that cohort.”
- “The six-input synthetic candidate produced a small gain; it did not meet our predeclared complexity threshold. Adding RHR did not provide a reliable gain.”
- “We recommend a simpler previous-score-only research candidate and optional RHR display, pending product approval and representative real validation.”
- “Correlated inputs, measurement noise, time constraints and explicit missingness improve the simulation design, but its numbers remain assumptions.”
- “Deterministic parity verifies implementation arithmetic, not prediction validity or causal habit effects.”

## 18. Claims that must NOT be made

- “V2 predicts UAE students' real grades with MAE 6.65” or “V2 is scientifically more accurate than V1.”
- “NetHealth proved wearable habits never matter,” “RHR has no relationship with attainment,” or “the study was well powered to rule out effects.”
- “HSLS, MCS or COMPASS have been analyzed/validated against TwinTrack.”
- “An extra hour of sleep/study will cause this many grade points” or “less exercise improves grades.”
- “The seven-day horizon, 28-day mean, coefficients, bounds or noise were estimated from compatible real students.”
- “GPA error converts directly to assessment-percentage accuracy,” or “synthetic confidence intervals measure real-world certainty.”
- “V2 is integrated, independently Swift-verified, or approved for production.”

Exact new-file paths/hashes: [FILE_INVENTORY.md](../ml/v2/2026-09-21/FILE_INVENTORY.md). Reproduction instructions: [README.md](../ml/v2/2026-09-21/README.md). Stop at this decision; A approval is required before further analysis or integration.
