# TwinTrack research claims and public wording

Research cutoff: 6 October 2026. This document covers claims, presentation, website, CV and judge defense. It changes no application, model or input. Product facts below follow the supplied project record; release-specific implementation and contribution claims require their own records. See the [scientific foundation](FINAL_RESEARCH_SYNTHESIS.md), [input matrix](TWINTRACK_INPUT_EVIDENCE_MATRIX.md) and [future protocol](TWINTRACK_FUTURE_VALIDATION_PROTOCOL.md). Literature supports critical interpretation, not verified TwinTrack accuracy.

The current system is **TwinTrack Ridge V2, 2.0-final.1**, standardized Ridge Regression with **alpha=0.1**, seven numerical features and an `assessment_score` output. Historical V1 used alpha=10 and synthetic holdout metrics; those values describe neither current V2 performance nor real students. Subject, assessment and date metadata are contextual eligibility information, not additional Ridge features.

## Public claims audit

“Safe” means defensible within the stated scope. “Unsupported” means the required demonstration is absent; it does not necessarily mean the claim could never become true. “False/misleading” identifies a contradiction or an important omitted boundary.

| Public statement | Verdict | Evidence and qualification | Recommended wording | Avoid |
|---|---|---|---|---|
| 1. “Sleep affects grades.” | **SAFE WITH QUALIFICATION** | Duration findings are mixed; [adolescent review](https://doi.org/10.1016/j.sleep.2021.04.015). Quality, timing and deprivation are different constructs. | “Sleep duration is a plausible academic correlate, with mixed evidence.” | “Every extra hour raises your score.” |
| 2. “More study improves grades.” | **FALSE/MISLEADING** as a universal rule | Time alone misses task difficulty and strategy; [homework review](https://doi.org/10.1002/cl2.1431). | “Study minutes describe quantity; effective practice and completion matter.” | “Thirty more minutes guarantees improvement.” |
| 3. “Exercise improves academic performance.” | **SAFE WITH QUALIFICATION** | Some programs benefit selected outcomes; [adolescent trial](https://doi.org/10.1186/s12889-021-10901-x). Assigned programs differ from Apple Exercise Time. | “Some school activity programs show modest academic benefits.” | “Apple exercise minutes have a proven grade effect.” |
| 4. “Screen time lowers grades.” | **FALSE/MISLEADING** without context | Activities differ; pooled total-use evidence includes nulls: [review](https://doi.org/10.1001/jamapediatrics.2019.3176). | “Some recreational screen-use patterns are associated with lower attainment.” | “All screen minutes are equally harmful.” |
| 5. “Daily steps predict grades.” | **UNSUPPORTED** as an established general claim | Direct evidence is weak and includes a large [prospective null](https://doi.org/10.1001/jamanetworkopen.2026.36973). | “Steps are an exploratory movement-volume input.” | “10,000 steps improves academic performance.” |
| 6. “Resting heart rate predicts grades.” | **UNSUPPORTED** as a reliable or incremental claim | Small direct studies exist, including a [secondary-school null](https://doi.org/10.3390/children11040396). HRV and average HR are different. | “RHR is exploratory; consistent added academic value is unestablished.” | “Lower RHR means higher grades,” or “no studies exist.” |
| 7. “TwinTrack predicts assessment scores.” | **SAFE WITH QUALIFICATION** | It produces a model estimate; prospective usefulness has not been established. | “TwinTrack generates experimental assessment-score estimates.” | “It knows your next grade.” |
| 8. “TwinTrack uses AI.” | **SAFE** | Ridge provides the numerical estimate; Apple Foundation Models supports conversation/explanation when available. | “Ridge calculates the estimate; on-device AI supports conversation and explanation.” | “An AI tutor understands your learning” without that functionality. |
| 9. “TwinTrack is a digital twin.” | **SAFE WITH QUALIFICATION** | [Consensus definitions](https://doi.org/10.17226/26894) emphasize dynamic representation and feedback; full fidelity is unestablished. | “A digital-twin-inspired student reflection prototype.” | “A complete, validated replica of the student.” |
| 10. “TwinTrack is personalized.” | **SAFE WITH QUALIFICATION** | Personal inputs differ; academic coefficients are shared, not individually learned. | “Uses your profile inputs with a shared model.” | “Learns your personal physiological response to studying.” |
| 11. “TwinTrack is evidence-based.” | **SAFE WITH QUALIFICATION** only after rewording | Evidence strength differs sharply across exact inputs; literature review is not system validation. | “An evidence-informed experimental prototype.” | “All seven inputs are scientifically proven.” |
| 12. “TwinTrack is privacy-first.” | **UNSUPPORTED** as an unqualified assurance | A privacy/security audit, data-flow inventory and operational safeguards are separate evidence. | Describe verified permissions, storage, deletion and transmission behavior specifically. | “Completely private,” “risk-free,” or “compliant” without verification. |
| 13. “TwinTrack runs on-device.” | **SAFE WITH QUALIFICATION** | Publish only if the frozen release's inference path confirms it; this research did not audit execution. | “The academic calculation runs on-device,” if verified. | “Nothing ever leaves the phone” inferred from local inference. |
| 14. “TwinTrack's predictions are accurate.” | **UNSUPPORTED** | Synthetic development and NetHealth do not validate current V2 accuracy. | “Real-world accuracy remains to be evaluated prospectively.” | “Scientifically validated accuracy,” or historical synthetic R² as a user guarantee. |
| 15. “TwinTrack helps students improve.” | **UNSUPPORTED** as a demonstrated outcome | Neither usability nor improved grades has been established by the supplied research. | “Designed to support reflection; benefits require user studies.” | “Proven to improve grades or wellbeing.” |
| 16. “TwinTrack uses real-world research.” | **SAFE WITH QUALIFICATION** | Literature review and one completed participant-level analysis inform limitations; other datasets remain unfinished. | “Its research foundation includes literature and a completed NetHealth analysis.” | “Validated on NetHealth, HSLS, MCS and COMPASS.” |
| 17. “Wearable data improves prediction.” | **FALSE/MISLEADING** as a TwinTrack result | Completed NetHealth comparison found effectively no incremental wearable value. | “Additional wearable predictive value remains unestablished.” | “Wearables improve accuracy,” or explaining the null away as established fact. |

Claims about engineering reliability require test records; claims about privacy require the relevant implementation and governance review. Neither can be supplied by citations about academic behavior. “Evidence-informed” describes the current critical research foundation, not proof that every original design choice came from research.

## Five presentation findings

1. **Prior achievement is the strongest-supported input.** Strong stability in [longitudinal school research](https://doi.org/10.1038/s41539-018-0030-0) supports a demanding previous-score baseline, not a fixed limit on potential.
2. **Minutes are incomplete measurements.** Study strategy, sleep characteristics, and screen context cannot be reduced to universal “more” or “less” rules.
3. **The physiological inputs are unevenly supported.** Broader activity evidence does not directly establish Apple exercise time, steps, or resting HR as academic predictors.
4. **The project's completed real-data result is null.** NetHealth: 207 students, 963 repeated terms; in reported means across 50 folds, wearable additions changed MAE by +.00003 grade points, RMSE by +.00053 grade points (0–4 scale), and R² by −.00181. Separately pooled estimates also showed no convincing improvement. It does not validate V2.
5. **Three different evaluations are needed.** Engineering checks verify exercised software behavior; prospective prediction studies assess accuracy and added value; user studies assess understanding and usefulness.

Suggested presentation takeaway: “The defensible achievement is an explicit, testable prototype with a transparent research boundary. Its academic usefulness is an open question.”

## Website-ready research section

TwinTrack is a digital-twin-inspired student reflection prototype. It brings together a previous assessment score, study time, recreational screen time, sleep, steps, exercise minutes and resting heart rate to generate an experimental score estimate and explore alternative input profiles.

The research behind these inputs is uneven. Previous academic performance has the strongest support. Findings for study duration, sleep duration and recreational screens are mixed and depend on how each behavior is measured. Evidence about exercise programs or fitness does not directly validate Apple Exercise Time. Steps and resting heart rate remain exploratory academic inputs.

TwinTrack's completed NetHealth analysis included 207 students and 963 student-semester observations. Adding available wearable measures provided effectively no improvement beyond previous performance. That analysis involved different measures, students and outcomes; it does not validate TwinTrack V2.

Synthetic data supports engineering development, not claims of real-world accuracy. The What-If feature shows how the shared model responds to changed inputs; it does not establish what changing a habit would cause for an individual student. The next research step is prospective evaluation against simple academic baselines, alongside studies of whether students understand and find the prototype useful. TwinTrack should be treated as an experimental reflection aid, with real-world predictive usefulness still to be established.

| Input | Direct academic evidence |
|---|---|
| Previous score | Strong |
| Study minutes; sleep hours; recreational screen minutes | Mixed |
| Apple exercise minutes; steps | Weak direct support |
| Resting heart rate | Insufficient consistent/incremental evidence |

Research links: [prior achievement](https://doi.org/10.1038/s41539-018-0030-0), [homework](https://doi.org/10.1002/cl2.1431), [sleep](https://doi.org/10.1016/j.sleep.2021.04.015), [screens](https://doi.org/10.1001/jamapediatrics.2019.3176). Ratings concern academic evidence, not the health value of sleep or movement.

## One CV research bullet

Use this only if the contributor's documented role supports it; the wording attributes a contribution, not sole authorship of the review, implementation or participant analysis. “Evidence-informed” is defensible because the package integrates supporting and contradictory research while separating it from project validation.

- Contributed to an evidence-informed research foundation for TwinTrack, critically assessing seven academic-model inputs, documenting limitations and a null wearable comparison, and defining prospective validation against prior-performance baselines.

## Judge defense

### 1. Why did you choose these seven variables?

**One sentence:** They define a manageable prototype combining academic history, reported behavior and wearable context, with unequal scientific support.

**30 seconds:** The set is a practical scope, not a discovery of the seven causes of achievement. Prior score has the strongest foundation; the other inputs test whether accessible context could add useful information. This review makes their limitations explicit without changing the frozen release.

**Deep technical:** Construct validity is the central qualification: hours differ from sleep quality, steps from fitness, and credited exercise minutes from intervention dose. Correlation cannot justify coefficients or prove conditional information beyond prior score. Feature-group comparisons on prospectively collected, appropriately separated data would test incremental value; the current selection alone cannot.

### 2. Which variable has the strongest evidence?

**One sentence:** Previous academic performance has the strongest evidence for predicting later attainment level.

**30 seconds:** A recent relevant score summarizes prior learning and aspects of the student's educational circumstances. Its dominance is therefore expected. The important question is whether the full model contributes useful additional information, rather than whether it can outperform a weak constant prediction.

**Deep technical:** Comparability matters: same-subject scores, grading scales, assessment difficulty and timing influence transport. Predicting level is distinct from predicting improvement. The primary persistence benchmark simply carries forward the last eligible score. A separate prior-only regression estimates its mapping on training data; neither uses future information. Dominance neither proves causality nor limits a student's capacity to improve.

### 3. Which variable has the weakest evidence?

**One sentence:** Resting heart rate has insufficient consistent evidence for adolescent academic prediction or added value beyond prior achievement.

**30 seconds:** Direct studies exist, so “there is no research” would be inaccurate. However, small studies include null and conflicting results. Findings about HRV, fitness or average heart rate cannot establish the case for the particular resting-heart-rate value used in TwinTrack.

**Deep technical:** The required estimand is incremental prospective value of this measured RHR construct for the specified academic target and horizon. Bivariate physiology–grade associations do not estimate it. Measurement protocol, illness, medication, age and stress can affect readings. The separate wellbeing baseline also does not turn the academic model into an individualized RHR-response model.

### 4. Why keep steps?

**One sentence:** Steps remain an explicitly exploratory activity proxy in a frozen prototype, not a proven academic predictor.

**30 seconds:** They are interpretable as walking-related movement and may be useful for reflection. That does not establish a grade benefit. Keeping them now preserves a fixed system that can be tested; it does not protect them from later removal if prospective evidence shows no value.

**Deep technical:** Ambulatory volume omits intensity, sport type, sedentary context and learning mechanisms. Device agreement establishes measurement performance, not academic usefulness. A prespecified future group comparison and training-only refitted step ablation could test contributions, with uncertainty and multiple comparisons handled explicitly. Neither a health guideline nor a synthetic coefficient establishes an academic step threshold.

### 5. Why keep resting heart rate?

**One sentence:** It is a disclosed exploratory limitation retained to preserve the frozen system's comparability.

**30 seconds:** Physiological plausibility alone is not enough to justify a strong grade claim. The current academic input is not validated as a reliable independent predictor. Research should evaluate it honestly, including the possibility that it contributes no useful information and should be reconsidered in a separately versioned model.

**Deep technical:** RHR definitions differ by rest protocol and vendor estimation; a latest reading may not represent a stable baseline. Shared Ridge coefficients encode a fitted association, not a physiological mechanism. Future tests should examine added held-out performance and sensitivity to measurement coverage; no new personalized threshold or coefficient is justified by this review.

### 6. If NetHealth showed wearables did not help, why still use them?

**One sentence:** They remain exploratory features of the fixed prototype, and the completed null result must stay central to its limitations.

**30 seconds:** NetHealth gives no reason to advertise a wearable accuracy advantage. Its population, outcome and available measurements differed from V2, so it also is not a direct test of the current app. The honest position is uncertainty about transfer, alongside a real negative incremental result.

**Deep technical:** The reported 50-fold means for the prior-performance benchmark were MAE .17127 and RMSE .23888 (0–4 grade points), and R² .52495; the wearable increment was effectively null. Average daily HR is not RHR, and study/screens were unavailable. Measurement mismatch, aggregation and limited variation are possible issues, not proven explanations. Repeated terms require student-aware evaluation and cannot be counted as independent participants.

### 7. Why not use motivation or socioeconomic status?

**One sentence:** The prototype has a deliberately limited input contract, so it cannot claim to represent all determinants of achievement.

**30 seconds:** Motivation, attendance, resources and school context matter, but measuring them well introduces additional design and governance questions. Omitting them keeps the current scope manageable; it does not make them irrelevant. Their absence is a reason to be cautious about interpreting lifestyle associations.

**Deep technical:** Omission affects confounding, transportability and calibration; prior score may capture some history but cannot guarantee adjustment. Adding sensitive contextual variables would require a specified use, measurement validation and fairness assessment. The scientific question is whether the limited system is useful for its declared purpose, not whether seven inputs exhaust an educational causal model.

### 8. Why use synthetic data?

**One sentence:** Synthetic data enables controlled engineering development without establishing real-world student accuracy.

**30 seconds:** It can exercise data handling, input ranges and deterministic calculations while reducing the need to use student records during development. Performance against generated labels mainly shows how well a model reproduces the generator. A real prospective evaluation is still required before making an accuracy claim.

**Deep technical:** A synthetic holdout shares assumptions with its generator, including functional form, noise and relationships. Cross-validation within that distribution cannot establish target-population validity. Historical V1 metrics must remain labeled historical and synthetic; current V2 alpha=.1 must not be confused with V1 alpha=10. Engineering parity and scientific validity answer separate questions.

### 9. Why should anyone trust the model?

**One sentence:** Trust should be limited to verified software behavior and transparent limitations until prospective usefulness is demonstrated.

**30 seconds:** A reproducible calculation can be inspected and tested, but consistency is not accuracy. Users should know that the score is experimental, what information it uses, and what evidence is missing. Understanding and appropriate reliance require testing with users as well as evaluating predictions.

**Deep technical:** Assess deterministic implementation separately from MAE, RMSE, calibration, subgroup error, missingness and uncertainty. Compare paired predictions against a demanding prior-score baseline using clustered uncertainty and preserved time ordering. A plausible-looking number is not a calibrated forecast; no individual predictive interval should be presented as validated without an appropriate real-data procedure.

### 10. Is What-If causal?

**One sentence:** No; it is model-based scenario or sensitivity analysis, not an estimate of a behavioral intervention's effect.

**30 seconds:** Changing an input and recalculating shows how the shared formula responds. It does not show what will happen if a student changes that habit. Real habits interact, compete for time, and reflect circumstances that the model does not capture.

**Deep technical:** A contrast between two fitted predictions is not an identified individual treatment effect. Identification would require a defensible causal design, confounding assumptions, feasible interventions and relevant outcomes. Independently moving correlated inputs can also create implausible profiles. The slider response should not be relabeled a causal counterfactual or a personalized prescription.

### 11. Why Ridge?

**One sentence:** Ridge is a defensible simple, deterministic regularized model for a small numerical prototype, not a proven best-performing choice.

**30 seconds:** It reduces coefficient instability by penalizing large weights and is straightforward to implement and inspect. Standardization matters because the features use very different units. These are engineering advantages; comparative performance would need testing against reasonable alternatives on suitable real data.

**Deep technical:** The L2 penalty shrinks coefficients and can stabilize fits with correlated predictors, but imposes bias and retains a linear response. Standardized magnitude is conditional on scaling, correlations and training distribution, not causal importance. Alpha=.1 is the frozen V2 specification; this review does not show it is empirically optimal for the intended student population.

### 12. What would make TwinTrack scientifically valid?

**One sentence:** Evidence must demonstrate a specified useful performance level prospectively in the intended population, beyond appropriate baselines.

**30 seconds:** Record predictions before assessments, keep the release fixed, and compare results against simple academic benchmarks. Evaluate errors and uncertainty across students and settings. Separately establish whether students understand the estimates and benefit from using the product; good predictions alone do not establish improved grades.

**Deep technical:** Preregister outcomes, eligibility, missing-data rules and primary comparisons; respect student, time and school grouping. Evaluate frozen V2 without refitting; any learned comparator belongs inside training partitions. Report calibration and paired incremental error with cluster-aware intervals. External validation addresses transfer; a separate intervention study would be needed for improvement claims. HSLS, MCS and COMPASS work is not completed validation.

### 13. Would you change the model after this research?

**One sentence:** No changes are authorized now; the research identifies limitations and hypotheses for later versioned evaluation.

**30 seconds:** Changing features or weights during the freeze would undermine comparability. The immediate change is to the claims: make experimental status and weak inputs clear. A later model revision should follow prospectively specified evidence and preserve the current release as a documented reference.

**Deep technical:** Literature cannot supply transferable coefficients, optimal thresholds or proof that dropping a feature will improve held-out accuracy. Future development should separate exploratory selection from confirmatory testing, version data and transformations, and retain untouched evaluation sets. Negative findings should inform the next research decision without being converted into an untested production modification.
