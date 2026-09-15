# Frozen Ridge read-only review — 2026-09-14

No fitting, regeneration, reweighting or artifact loading through pickle was performed. This review reads the committed generator, tuning/evaluation code, exported JSON and result CSVs. Parameter sensitivities below were calculated directly from the JSON. No personal measurements or desired score are used.

## Target assumptions

`ml/src/generate_data.py` creates 1,000 independent synthetic rows with `default_rng(42)`. Each input is drawn from a clipped normal distribution; the generator does not represent repeated observations from real students, longitudinal effects, measurement error, school/subject difficulty or confounding.

The assumed target, before clipping and rounding, is:

```
18 + 0.9*sleep_hours + 0.00025*steps + 0.025*exercise_minutes
   - 0.035*(resting_heart_rate - 65) + 0.035*study_minutes
   - 0.012*screen_time_minutes + 0.55*previous_score + Normal(0, 6)
```

The target is clipped to 0–100 and rounded to one decimal. Inputs are rounded separately after the target calculation. These are developer assumptions for synthetic development, not empirically established effects on students. The target makes previous score particularly influential by construction. It has no optimal-sleep curve or delayed/causal intervention model.

## Inputs, units and actual app periods

| Ordered feature | Unit | Current input source / period | Exported observed synthetic range |
| --- | --- | --- | --- |
| sleep_hours | Decimal hours | Union of accessible asleep intervals, yesterday local noon to the earlier of now/today local noon | 4–10 |
| steps | Count | Previous completed local calendar day | 1,000–14,286 |
| exercise_minutes | Minutes | Previous completed local calendar day | 0–91.2 |
| resting_heart_rate | bpm | Latest valid finite positive sample in 72 elapsed hours; sample timestamp retained | 45–95.8 |
| study_minutes | Minutes | Latest explicitly saved manual value; no independently verified daily period | 0–262.7 |
| screen_time_minutes | Minutes | Latest explicitly saved manual value; no automatic Screen Time measurement | 30–531.7 |
| previous_score | Points / 100 | Latest saved manual previous score | 38.2–100 |

Missing values remain missing. These source periods do not become contemporaneous merely because they form one vector. The synthetic generator has no timestamps or HealthKit source semantics; matching variable names does not validate the mapping to a particular future assessment.

## Coefficient sensitivity

Frozen prediction: `raw = intercept + Σ coefficient[i] * (input[i] - mean[i]) / scale[i]`; displayed result is clamped to 0–100. Alpha is 10.0. Therefore each raw marginal sensitivity is `coefficient / scale` with all other inputs fixed.

| Feature | Raw points per unit | Illustrative change in raw output |
| --- | ---: | ---: |
| Sleep | +0.88474062 per hour | +1 hour → +0.884741 |
| Steps | +0.00034506 per step | +1,000 steps → +0.345063 |
| Exercise | +0.02695178 per minute | +30 minutes → +0.808554 |
| RHR | +0.02754400 per bpm | +10 bpm → +0.275440 |
| Study | +0.03255574 per minute | +60 minutes → +1.953344 |
| Screen time | −0.01029233 per minute | +60 minutes → −0.617540 |
| Previous score | +0.53169175 per point | +10 points → +5.316917 |

These are mathematical properties, not recommendations or causal effects. The learned RHR coefficient is positive despite a negative target assumption: weak signal, finite synthetic sampling and noise can reverse it. It is not evidence that raising RHR improves assessment performance and does not authorize changing the coefficient. Near the clamp rails, displayed deltas differ from raw deltas. Multiple changes must use one combined scenario and then the clamp.

## Supported computation versus extrapolation

The app's numerical validation allows finite nonnegative inputs, strictly positive RHR and previous score 0–100, with a floating-point overflow guard. Those constraints are not scientific support ranges. Duration-wheel limits are UI entry limits, not training evidence. An input can be valid for computation while far outside the observed synthetic range.

Even a vector within every univariate range can have an unusual combination of features. Outside those ranges, the linear model extrapolates without biological limits or saturation except the score clamp. A 0/100 result is a clamp, not confidence. More sleep/study cannot be inferred to indefinitely improve real outcomes. Neither in-range nor extrapolated scenarios have established real-world validity here. This audit changes no validation or warning behavior.

## Training, validation and baseline evidence

`ml/src/tune.py` uses an 80/20 split with seed 42, a StandardScaler/Ridge pipeline and five-fold shuffled training-only CV over ten alpha values. Pipeline placement refits scaling within each training fold. The exported provenance reports 800 training and 200 holdout rows. `train.py` is a separate comparison producer; it does not own the frozen production artifact.

Recorded synthetic results (read, not retrained in this milestone). Evaluation/baseline scripts score the unclamped pipeline output; the app applies its separate 0–100 clamp:

| Evaluation | MAE | R² |
| --- | ---: | ---: |
| Mean-only holdout baseline | 7.144493 | −0.000030 |
| Previous-score-only holdout baseline | 4.801499 | 0.549687 |
| Full Ridge holdout | 4.761462 | 0.570429 |

Ridge holdout RMSE is 5.868373; selected training-CV MAE is 4.636596. The full model's MAE improvement over previous-score-only is about **0.0400 points (0.83%)**, a small observed synthetic difference without an uncertainty/significance estimate. Selected-alpha CV is a model-selection statistic, not independent validation. The existing audit reports the scaler/split checks and exact reproducibility; this review confirms source structure and recorded artifacts, not a new training run. Reusing the same holdout after future design decisions would cease to provide an untouched final evaluation.

The existing 21 golden profiles establish Python/Swift implementation agreement, including precision and clamp behavior. Screenshot arithmetic at displayed precision also establishes only mathematical consistency. Neither establishes accuracy for A or any real student. NetHealth research is separate and does not validate this exact model.

## Evidence required before a proposed new version

1. Define the real assessment target, forecast horizon, intended student population and each input's measurement/source period before collecting or fitting data.
2. Obtain appropriate consent/governance and a data-minimization plan; do not repurpose A's private records as a tuning target.
3. Acquire representative paired outcomes and inputs, quantify missingness/device measurement error, and document confounding and selection bias.
4. Prespecify student-separated and temporal validation, holdout protection, simple baselines (especially previous score), uncertainty intervals and subgroup/calibration checks.
5. Evaluate whether lifestyle inputs add meaningful out-of-sample value beyond previous score. Causal What-If claims require stronger intervention evidence than predictive association.
6. Review safety/extrapolation limits, age applicability and communication. Independently review any proposed changes and obtain A's explicit approval before a separately versioned model, artifact export and new parity suite.

No desired score has been chosen. The frozen production model and seven-feature order remain unchanged.
