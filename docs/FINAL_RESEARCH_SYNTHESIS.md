# TwinTrack final research synthesis

Prepared 2026-09-22. Research/documentation only. No iOS, assistant, HealthKit, model artifact, coefficient, training or artwork changes. No staging, commit or push. Source hierarchy: frozen local NetHealth results; official NCES metadata; identified published research; final V2 artifact/decision; historical strategy only as planning context. These evidence types are not interchangeable.

## 1. Executive summary

**Verdict: A. RESEARCH SUFFICIENT FOR GRADUATION PROJECT — as an explicitly experimental engineering prototype, not a validated student prediction service.** This is a scientific scope recommendation, not a guarantee about an unseen university marking rubric or deadline.

NetHealth is the sole completed TwinTrack real-data comparison available for review. Prior academic performance dominated; adding early-semester wearables did not convincingly improve prediction. HSLS participant-level analysis remains **PENDING**, with a frozen local protocol and a material access limitation: school identifiers needed for the planned validation are suppressed in public-use student data. No local HSLS participant file or approved restricted environment was supplied. MCS and COMPASS have no completed TwinTrack participant-level analyses.

V2 2.0-final.1 is an evidence-informed **synthetic-trained** seven-input Ridge model. Its dominant previous-score term and restrained lifestyle effects are defensible modeling choices, but their magnitudes, time windows and real-student accuracy remain unverified. A second proxy-dataset study could address a useful question; it still could not establish V2 accuracy. Do not delay a clearly qualified prototype merely to accumulate dataset names.

## 2. Frozen NetHealth result and consistency review

Source: local-only `NetHealth_Final_Report.md`, SHA-256 `8c1b17ef20c1ca5f9f909b643c9ddaacd9991dcb3018630677430876e7abcfdb`. Reviewed, not altered or rerun. This is a consistency review of the saved report, not an independent replication: its referenced panel, fold-results CSV and exclusion file are not present in the approved research folder.

**Population and design.** A single Notre Dame undergraduate cohort; 207 unique students and 963 student-semester observations across seven target terms. There were 1,483 eligible transitions among 215 linked students; 520 transitions were excluded, with 64.9% retained. The 963 rows are not independent students. The outcome is the unweighted mean course grade points on a 0–4 scale, not official credit-weighted GPA or a single upcoming test percentage. Baseline A uses previous-term course-grade average. B adds first-28-day average sleep, steps, active minutes/MVPA and **average daily heart rate**, not resting heart rate. Study and screen time were absent.

At least 14 sleep days, 14 activity days and three prior courses were required. The report records ten repeated five-fold student-grouped validations, training-only scaling/nested grouped alpha selection, and identical A/B rows. Its paired bootstrap resampled 207 students with all their rows together, for 10,000 replicates.

**Main numerical results, preserving their estimands:**

| Metric | Model A, mean across 50 folds | Model B, reconstructed from rounded A + delta | Reported fold-mean B−A |
| --- | ---: | ---: | ---: |
| MAE (grade points) | 0.17127 | approximately 0.17130 | +0.00003 |
| RMSE (grade points) | 0.23888 | approximately 0.23941 | +0.00053 |
| R² | 0.52495 | approximately 0.52314 | −0.00181 |

B values in this table are arithmetic reconstructions from the saved rounded numbers, **not recovered exact source table values**. Positive error deltas mean worse prediction.

The separately reported paired student-cluster bootstrap intervals are ΔMAE [−0.00112, +0.00099], ΔRMSE [−0.00050, +0.00140], ΔR² [−0.00503, +0.00209]. They concern pooled prediction statistics, not interchangeable fold-average estimates. The pooled MAE point delta is reported as −0.00006, opposite the tiny fold-mean +0.00003. Do not silently attach a pooled interval to a fold-average point estimate as one identical estimator.

| Separately reported pooled/bootstrap quantity | A | B |
| --- | ---: | ---: |
| MAE | 0.17105 [0.15573, 0.18826] | 0.17098 [0.15552, 0.18836] |
| RMSE | 0.23939 [0.21070, 0.27497] | 0.23983 [0.21103, 0.27572] |
| Pooled out-of-fold R² | 0.54504 | 0.54292 |

Rounded pooled MAEs subtract to −0.00007, while the report gives −0.00006 from its calculation; retain this rounding distinction. A had higher pooled R² in nine of ten repetitions. None of these variations provides convincing wearable improvement.

**Robustness.** Reported B−A triples (MAE, RMSE, R²): OLS (+0.00003, +0.00054, −0.00182); term fixed effects (+0.00016, +0.00060, −0.00208); longest-bout sleep (−0.00025, +0.00027, −0.00077). Wearables-only diagnostic R² was −0.013. The prior-performance standardized coefficient was +0.262; wearable magnitudes were at most 0.013 in the descriptive full-sample fit. The preregistered joint improvement rule was not met.

**Reporting corrections for future summaries, without editing the frozen report:**

- Do not repeat “less than 0.1% on every metric.” The reported RMSE change is about 0.22% of A's fold-average RMSE; ΔR² is −0.181 percentage points. Use raw deltas.
- “All four secondary specifications” conflates three A/B robustness comparisons with a fourth, behavior-only diagnostic. Describe them separately.
- “Zero of three conditions” refers to the fold-mean decision framing; the tiny pooled MAE has the other sign. The overall gate still fails. Do not present either tiny sign as substantive evidence.
- Some originally promised tables/attachments are absent from the saved narrative. Exact fold-level reconstruction and independent interval verification require those original aggregate outputs; no rerun or methodological invalidity is inferred merely from missing attachments.

**Limitations.** Restricted grade range/ceiling, single high-achieving institution, compliance selection, attrition, repeated observations, inferred semester-code timing, summed-bout sleep including naps, no resting HR and no study/screen variables. No formal power analysis establishes sensitivity to very small effects. There is no causal identification. The result is “no convincing increment here,” not proof that sleep/activity never matter.

## 3. HSLS:09 — pending, not completed

The official audit supports a 2009→2012 mathematics question using `X1TXMTSCOR` → `X2TXMTSCOR`, with `S1HRMHOMEWK`, `S1HRTV`, `S1HRVIDEO`, `S1HRONLINE` as baseline behavioral proxies. Schoolday hour bands are not yesterday's exact minutes; math assessment T scores are not TwinTrack assessment percentages. The audited waves do not supply sleep duration, steps, exercise minutes or RHR. Extracurricular hours cannot substitute for exercise.

Public access exists, but the student codebook suppresses `SCH_ID`; survey weights do not supply a lawful school identity for group splitting. No participant file or authorized secure/restricted environment was available locally. **Analytic sample N, model metrics, coefficients and incremental result: PENDING / NOT ESTIMATED.** Public release counts must not be presented as our analytic sample. [NCES access](https://nces.ed.gov/surveys/hsls09/hsls09_data.asp), [student codebook](https://nces.ed.gov/pubs2015/2015036_student.pdf).

Local artifacts now contain the full field/access audit, frozen v1.0 protocol, hash manifest and execution template. The fixed plan compares weighted Ridge A (earlier math only) and B (same baseline plus four categorical behaviors), identical rows, nested school validation, survey-weighted metrics and explicitly conditional BRR uncertainty. It excludes imputed assessment targets and forbids outcome-driven specification changes. No transcript outcome switch, public student-fold substitution or model retuning is permitted without a new prospective amendment. [NCES design/weights](https://nces.ed.gov/pubs2014/2014361.pdf), [variable list](https://nces.ed.gov/pubs2014/2014361_2.pdf).

This is a **local preanalysis freeze**, not external registration. Documentation contains public descriptive information, and a public GPA/time-use search snippet was incidentally seen during discovery; the plan is not claimed literature-blind. No participant data or TwinTrack HSLS outcome analysis was examined before freezing it.

## 4. MCS status

**PLANNED / HISTORICAL RESEARCH EXISTS; NO COMPLETED TWINTRACK PARTICIPANT-LEVEL ANALYSIS.** The original research-plan file remains unavailable locally. The strategy document is a research/acquisition proposal, not a result. Neither missing plans nor descriptions of published MCS studies count as a TwinTrack experiment. No MCS effect size or model result is asserted here; recovering that plan is not required to finish this synthesis.

## 5. COMPASS status and external literature

**CANDIDATE / RESEARCHED; NO COMPLETED TWINTRACK PARTICIPANT-LEVEL ANALYSIS.** Separately, published research by Papasideris et al. (2021) analyzed 9,898 linked Canadian adolescent cases and described physical-activity/academic associations as trivial or effectively null. That is an external paper, not our analysis and not an out-of-sample V2 evaluation. Its self-reported grade/activity constructs differ from NetHealth and Apple Health. The paper's correction concerns references/citations and does not provide new TwinTrack results. [Original study](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0253142), [correction](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0259618).

## 6. Final V2 evidence alignment

Authoritative design: [V2 final blocker resolution](V2_FINAL_BLOCKER_RESOLUTION.md), final artifact `ml/v2/2026-09-21-final/results/new_ridge_seven_parameters.json`, SHA-256 `62cb14d443221f9f2e426280ebdf52d7ef8614812a89ef5031329642ff040024`. Earlier candidate reports are superseded for final numerical interpretation. The final assumption ledger explicitly separates modeling assumptions from empirical estimates.

V2 targets the next same-subject individual written quiz/test/exam percentage, 1–7 local days ahead; prior comparable assessment is 1–90 days old. Study/screen are yesterday's subject study/recreational totals; steps/exercise are previous-day totals; sleep uses the current completed/cutoff noon window; RHR is the latest valid sample within 72 hours. Those windows are product/development choices, not validated predictive horizons. Requiring seven available inputs is a product rule, not evidence that all seven are scientifically necessary.

Published synthetic evaluation: final 4,000-row set MAE 6.5346049, RMSE 8.1508881, R² 0.580072282; matched prior-only MAE 6.57051485. Difference about −0.03591 synthetic percentage points. These are **simulator results only**, not real-student accuracy, calibration or causal evidence. V1 comparisons on that synthetic distribution do not establish real-world V2 superiority. Nothing was retrained or rescored in this synthesis.

Qualitative alignment is strongest in emphasizing prior performance and keeping lifestyle increments restrained. Synthetic coefficient signs and stability partly reflect assumptions used to generate targets; they are not independent confirmations from new students. NetHealth influenced the rationale, so describing it as independent external validation of the resulting V2 would be especially inappropriate.

## 7. Feature-by-feature evidence assessment

Labels evaluate the final behavior against the reviewed evidence; they do not certify a fitted coefficient. No classification is an instruction to alter V2.

| Input | Classification | Evidence and boundary |
| --- | --- | --- |
| `previous_score` | **CONSISTENT WITH EVIDENCE** | Dominant prior performance agrees with NetHealth. V2's +0.778340203 per prior-score point is synthetic; semester mean versus recent subject assessment is a substantial mismatch. HSLS has not independently confirmed this for TwinTrack. |
| `study_minutes` | **PLAUSIBLE BUT UNCERTAIN** | Academic preparation is a plausible construct; NetHealth did not measure it and HSLS increment is pending. No local real-data estimate validates V2's +0.312678 points per 30 minutes. Time spent may reflect difficulty as well as productive study. |
| `sleep_hours` | **PLAUSIBLE BUT UNCERTAIN** | External observational sleep evidence supports studying this construct; NetHealth found no convincing joint wearable increment. Multiweek sleep patterns differ from one latest window. V2's +0.08895 points/hour is not established by either study. |
| `screen_time_minutes` | **PLAUSIBLE BUT UNCERTAIN** | Recreational-use definition is clearer than all-screen time, but effects depend on purpose, timing, displacement and confounding. No completed local screen increment exists. V2's −0.252576 points/hour is a synthetic assumption-driven sensitivity. |
| `steps` | **WEAKLY SUPPORTED** | NetHealth provides little conditional predictive support. Final effect is tiny and negative (about −0.033383 points/2,000 steps), with unstable seed direction. Neither beneficial nor harmful walking advice follows. |
| `exercise_minutes` | **WEAKLY SUPPORTED** | NetHealth and external COMPASS findings discourage a strong universal grade effect. V2 effect is tiny (+0.050707 points/30 minutes); Apple Exercise is not the same as all MVPA. This says nothing against exercise's other benefits. |
| `resting_heart_rate` | **NOT DIRECTLY TESTABLE** | Reviewed NetHealth measured average daily HR; HSLS lacks RHR. V2's −0.230850 points/5 bpm has no direct real-data validation here. Its synthetic seven-versus-six increment is uncertain, and personal RHR wellbeing trends remain a separate non-diagnostic feature. |

A relevant external sleep paper reports associations for multiweek sleep rather than the single night before a test; its observational college-course findings neither establish causation nor calibrate TwinTrack's latest-window slope. [Okano et al., 2019](https://www.nature.com/articles/s41539-019-0055-z).

None of these classifications means all seven inputs have equally strong evidence. We cannot defensibly rank study, sleep and screen by incremental predictive strength from the completed local evidence. Sleep has directly reviewed observational support; study/screen remain important untested local hypotheses. Exact coefficient magnitudes are unverified for **every** input, including prior score.

## 8. Cross-study comparison

| Source | Population | Relevant variables | Outcome | Prior-performance role | Lifestyle increment | Main result | Limits / TwinTrack relevance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Frozen NetHealth analysis | 207 US undergraduates; 963 repeated terms | Prior grades + early-term sleep, steps, MVPA, average daily HR | Later term course-grade mean (0–4) | Strong A baseline, dominant descriptive coefficient | B−A errors essentially unchanged/slightly worse | No convincing increment | Single cohort, selection, different windows; supports restraint, not V2 validation |
| HSLS proposed comparison | US 2009 ninth-grade cohort; paired N unknown | Prior math + homework/legacy-media categories | 2012 math T score | Prespecified A baseline, not yet fitted | **PENDING** | **NOT RUN** | School access blocked; proxy scales and long horizon; cannot agree/disagree empirically yet |
| V2 2.0-final.1 offline evaluation | Synthetic profiles; 4,000 final test rows | Exactly seven modeled inputs | Synthetic upcoming percentage | Dominant by generator/fitted design | Small synthetic improvement | Engineering behavior verified in earlier work | Not an independent real population or study result; accuracy unverified |
| Published COMPASS paper | 9,898 linked Canadian adolescents | Activity and academic measures, with study covariates | Later self-reported academic measures | Adjustments in an external association study; not our A/B design | No TwinTrack incremental metric | Trivial/effectively null activity association | External literature only; no local participant comparison |
| MCS | No local participant analysis | Candidate constructs in strategy | No local outcome analyzed | Not tested | Unknown | Planning only | Cannot supply results or validate V2 |

No pooling, meta-analysis or cross-scale MAE conversion is justified. NetHealth and the external COMPASS paper both caution against promising substantial academic benefit from activity, but they are different analyses. HSLS contributes a potential complementary homework/screen question, **not a confirming result**. Synthetic V2 behavior cannot serve as a second empirical replication.

## 9. Scientific limitations and direct answers

1. **Is earlier performance consistently strongest?** It was strongest in completed NetHealth and is dominant in V2's synthetic design. There is only one completed local real-data comparison; cross-study universal consistency is not established.
2. **Do lifestyles add meaningful information?** Not convincingly as a joint wearable block in NetHealth. The separate homework/screen question remains untested locally. A small contribution is possible; a null test is not equivalence.
3. **Which lifestyle evidence is strongest?** Sleep has pertinent observational literature, but this does not establish incremental predictive priority after prior grades. There is insufficient comparable evidence to rank the lifestyle inputs quantitatively.
4. **Which are weakest?** Steps/exercise conditional academic increments are weak; RHR has no direct validation in the reviewed studies. Study/screen coefficients and all production windows remain uncertain too.
5. **Causation?** No reviewed TwinTrack analysis identifies causal effects. Changing a model input is not an intervention study.
6. **Direct V2 validation?** None. Different populations, time horizons, scales, HR definitions and missing inputs prevent it.
7. **Defensible prototype?** Yes, with disclosed synthetic training, preserved null results, cautious numerical interpretation and abstention when data are unavailable. It is not established for consequential academic or medical decisions.
8. **What should judges hear?** An engineering demonstration with real-data research informing restraint, alongside an explicit need for prospective validation. Technical parity proves implementation consistency, not real prediction quality.

The audit is a focused evidence synthesis, not a systematic review of all published research. Source-code/test correctness, deterministic outputs, confidence under synthetic distributions and prospective accuracy are separate questions. No numerical real-world confidence interval is warranted for an individual prediction. No evidence here establishes necessity of all seven inputs, UAE calibration, subgroup fairness, clinical validity or usefulness of the experimental RHR thresholds.

## 10. Research completion decision

**A. RESEARCH SUFFICIENT FOR GRADUATION PROJECT.** This verdict applies to the experimental-prototype scope above. It does not mark HSLS complete or close the real-world validation gap.

No exact submission deadline or marking rubric was supplied, so no remaining-hours estimate is invented. In a finalization phase, obtaining restricted school linkage and running a second proxy study has uncertain lead time and cannot validate the actual app anyway. Finish honest reporting now. HSLS is worthwhile optional complementary research if lawful access and time become available; MCS/COMPASS are not prerequisites merely because they were shortlisted. If the actual rubric requires two executed empirical studies, that requirement must be assessed explicitly rather than hidden by this verdict.

For **claims of real-student predictive accuracy**, further research is required: a prospective study of the actual frozen app contract and target population. That is a substantive validation gap, not something one more unrelated dataset can automatically fix.

## 11. Presentation-safe claims

Use [PRESENTATION_RESEARCH_CLAIMS.md](PRESENTATION_RESEARCH_CLAIMS.md), which has exactly the three requested claim categories. Suggested explanation: “TwinTrack is an experimental, evidence-informed student app. In our completed NetHealth comparison, earlier academic performance dominated and wearables did not convincingly improve prediction. Our seven-input V2 was trained and evaluated on synthetic data; real-student accuracy remains unverified.”

Call HSLS “protocol prepared; participant analysis pending.” Call MCS/COMPASS “candidate research,” distinguishing the published COMPASS paper from our own work. What-If displays model sensitivity, never a promised change in a student's score.

## 12. Claims that must not be made

Do not claim validated student accuracy, measured effects of the seven V2 slopes, causation from sleep/study/screen/activity changes, RHR diagnosis, a completed HSLS/MCS/COMPASS TwinTrack study, or external validation of the production model by NetHealth. Do not treat synthetic R² as real accuracy, software parity as empirical validity, all 963 NetHealth rows as independent students, or missing HSLS results as a null finding.

## 13. Future validation and handoff

A defensible next empirical evaluation would freeze the current V2 and app input definitions before collecting prospective labels in a relevant population; obtain appropriate ethics/consent and local privacy safeguards; use the real forecast horizon and same-subject outcome; compare V2 with prior-only and simple baselines; separate students/schools and time between development and final evaluation; fit preprocessing only on training data; report coverage/abstentions, MAE/RMSE/R², calibration, uncertainty, subgroup performance and null/negative outcomes. Prespecify a practical benefit criterion and power/precision plan. No threshold or training adjustment should use the final test set. Causal recommendations and clinical claims would require different evidence.

**Outstanding materials:** HSLS participant package, release labels/readers and legitimate school-group analysis access are needed only to execute that pending study. Restricted data must remain in their approved environment; do not upload them here. Original NetHealth aggregate fold-results would improve reporting reproducibility, but are not required to repeat its documented conclusion; no raw student rows are requested. The MCS original plan remains missing and nonblocking. No additional input is needed to use this qualified synthesis.

Local master handoff updated. Local audit/protocol/template/hash remain under `.twintrack-local/research/HSLS/`, excluded via `.git/info/exclude`. Source NetHealth report and final model hash remain unchanged. No participant data were fetched or sent to external services. Stop after this synthesis.
