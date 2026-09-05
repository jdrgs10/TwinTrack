# TwinTrack ML Audit — Pre-Swift-Port Freeze

Independent audit of the uploaded archive. Nothing was retrained, regenerated,
or redesigned. Every number below was recomputed from the actual files.

**Environment caveat:** audited on scikit-learn 1.8.0 / numpy 2.4.4. The bundled
`.venv` pins scikit-learn 1.9.0 / numpy 2.5.2. The artifact loaded cleanly and
every committed number reproduced exactly, so the version gap did not bite — but
see Finding 3.

---

## Verdict

**Ready to freeze.** No blocking bugs. No data leakage. The production artifact
is bit-for-bit reproducible from the committed CSV.

---

## 1. Verified checklist

| Item | Result |
|---|---|
| Feature order | Matches the required order exactly, in all four places |
| Train/test split | `train_test_split(test_size=0.20, random_state=42)` → 800 / 200 |
| Scaler fit scope | **Training split only** — verified numerically, not just structurally |
| Final Ridge alpha | `10.0`, selected from a 10-point grid |
| Cross-validation | `KFold(n_splits=5, shuffle=True, random_state=42)`, training split only |
| Holdout MAE | `4.76146176524888` |
| Holdout RMSE | `5.868372602783463` |
| Holdout R² | `0.5704285621846623` |
| Baselines | Mean-only MAE 7.144 (R² ≈ 0) · Prev-score-only 4.801 · **Ridge 4.761** |
| Data leakage | **None found** |
| Automated tests | **33 / 33 pass**, zero xfail, zero skip |
| Production model owner | `ml/src/tune.py` — sole writer of `twintrack_model.joblib` |

### Leakage evidence

`scaler.mean_` matches the 800-row training mean to 0.0 and differs from the
full-dataset mean by up to 30.11 (on `steps`). The scaler saw training data only.
`StandardScaler` sits inside the `Pipeline`, so `GridSearchCV` refit it per fold.
The 20% holdout is touched exactly once, for reporting.

Confirmed `ddof=0` (population std). `scale_` matches `std(ddof=0)` to 0.0 and
differs from `ddof=1` by up to 1.55. **Swift must use population std.**

### Reproducibility

Retraining `tune.py`'s logic from the CSV reproduced `alpha=10.0`, CV MAE, and all
three holdout metrics identically. Coefficients matched the saved artifact to
8.9e-16. `generate_data.py` regenerates the CSV with **zero numeric difference**
across the numpy version gap (only CRLF vs LF differs), so the dataset is
genuinely deterministic.

Model comparison also reproduced: Ridge 4.637 CV MAE vs Random Forest 4.915 and
Gradient Boosting 4.918. Ridge wins on merit.

---

## 2. Findings

Nothing here blocks the port. Ordered by how much damage each could do during
the Swift rewrite.

### Finding 1 — `feature_coefficients.csv` is sorted by |coefficient|, not feature order

`explain.py` sorts before writing. Its row order is
`previous_score, study_minutes, sleep_hours, screen_time_minutes, steps, exercise_minutes, resting_heart_rate`
— **not** the model's feature order.

Porting coefficients from that CSV silently produces a model that runs, returns
plausible scores, and is wrong. This is the single most dangerous trap in the repo.

**Mitigation:** source parameters only from `twintrack_model_params.json`.
`TwinTrackModel.swift` carries a comment warning against this file, and
`GoldenRunner` asserts feature-order equality before comparing any numbers.

### Finding 2 — the 0–100 clamp is application-layer, not model-layer

`predict_score()` clamps in `twintrack_assistant.py`, `predict.py`, and
`simulate.py`. `evaluate.py` and `baselines.py` deliberately score **unclamped**
output.

This is currently invisible: on the holdout, raw predictions span 50.07–83.73, so
**0 of 200 rows clamp** and both metric sets are identical. It becomes visible the
moment real HealthKit data produces an extreme profile.

**Mitigation:** the export keeps `expected_raw` and `expected_clamped` as separate
fields, and Swift exposes `predictRaw` and `predict` separately. Two golden
profiles (`clamp_high_rail`, `clamp_low_rail`) pin both rails.

### Finding 3 — the artifact is a version-pinned pickle

`twintrack_model.joblib` is the only home of the trained parameters, and joblib
pickles carry no forward-compatibility guarantee. A future scikit-learn upgrade on
the Mac mini could make it unloadable, and the parameters would be gone.

**Mitigation:** `twintrack_model_params.json` is now a plain-text, version-independent
copy. Commit it. It is the durable record.

### Finding 4 — `TRAINING_RANGE` is computed from the full CSV, not the training split

`twintrack_assistant.py` builds it from all 1000 rows despite the name.

**Not leakage** — these bounds only drive extrapolation warnings and never touch
fitting or prediction. Verified harmless in practice: every feature's min and max
happen to fall inside the training split, so full-data and train-only ranges are
**identical**. Cosmetic naming issue; no behavioural fix needed.

### Finding 5 — `HOLDOUT_MAE = 4.76` is hardcoded in the assistant

Duplicated from `evaluate.py` rather than read from `saved["test_metrics"]`. It is
correct today. It will drift silently if the model is ever retrained.

**Mitigation:** the JSON export carries `provenance.holdout_metrics`; read from
there in Swift rather than retyping the constant.

---

## 3. The frozen pipeline — exact locations

| Concern | File | Detail |
|---|---|---|
| **Production model producer** | `ml/src/tune.py` | Sole writer. `GridSearchCV` over `ridge__alpha`, refit on 800 rows, dumped at lines 128–144 |
| Model comparison only | `ml/src/train.py` | Writes `model_comparison.joblib`, flagged `production_model: False`. Never touches the production file |
| Prediction contract | `ml/assistant/twintrack_assistant.py` | `predict_score()`, lines 41–53 — includes the clamp |
| Holdout metrics | `ml/src/evaluate.py` | Unclamped |
| Training-CV diagnostic | `ml/src/validate.py` | Training split only |
| Baselines | `ml/src/baselines.py` | Same split, same holdout |
| Data generation | `ml/src/generate_data.py` | `default_rng(42)`, 1000 rows |
| Tests | `ml/tests/test_twintrack.py` | 33 tests |

`Pipeline(steps=[("scaler", StandardScaler()), ("ridge", Ridge(alpha=10.0))])`

---

## 4. What to export to Swift

Ship these two files. Do not ship the `.joblib`, the venv, or any results CSV.

**`twintrack_model_params.json`** — feature order, `scaler.mean_`, `scaler.scale_`,
`ddof=0`, `ridge.coef_`, `ridge.intercept_`, alpha, clamp bounds, training ranges,
and provenance metrics.

**`golden_profiles.json`** — 21 profiles with `expected_raw` and `expected_clamped`.

### Exact values

Feature order (load-bearing):
```
sleep_hours, steps, exercise_minutes, resting_heart_rate,
study_minutes, screen_time_minutes, previous_score
```

```
scaler.mean_  = [6.9750875, 6835.025, 31.021375, 68.09925000000001,
                 90.76825000000001, 245.52300000000002, 74.94800000000001]

scaler.scale_ = [1.165721232689767, 2478.3349716846187, 18.76555103399245,
                 8.758956812172327, 48.136470237622326, 91.09202926710987,
                 12.11120951845851]

ridge.coef_   = [1.0313609218864506, 0.8551817402946157, 0.5057650814894945,
                 0.24125669488872578, 1.5671184670863296, -0.9375490969179391,
                 6.4394301275765775]

ridge.intercept_ = 67.90012499999999
alpha            = 10.0
```

### Prediction contract

```
z_i     = (x_i - mean_i) / scale_i
raw     = dot(coef, z) + intercept
clamped = min(100, max(0, raw))
```

Verified **bit-identical** (max diff `0.0`) to `Pipeline.predict` across all 200
holdout rows. There is no hidden transform to reverse-engineer.

**Use `Double`, not `Float`.** `Float32` carries ~7 significant digits; `steps`
has scale ≈ 2478 and values to 14286, so `Float` will not hold 1e-6.

---

## 5. Golden test profiles

Regenerate with `python ml/src/export_for_swift.py`. The script self-aborts if the
manual formula drifts from sklearn by more than 1e-9, so the golden file cannot be
written from a broken model.

21 profiles, chosen to fail loudly rather than uniformly:

| Group | Profiles | Catches |
|---|---|---|
| Structural anchors | `at_training_mean`, `one_sd_above_mean`, `one_sd_below_mean` | Wrong mean/scale/intercept. At the training mean every z is 0, so raw **must** equal the intercept exactly (67.90012499999999) |
| Repo profiles | `assistant_default_profile`, `simulate_improved_scenario`, `predict_py_example` | Regressions against the demo paths |
| Range corners | observed min/max, best/worst in-range | Sign errors and swapped features |
| Clamp rails | `clamp_high_rail` (raw 193.85 → 100.0), `clamp_low_rail` (raw −34.25 → 0.0), `just_below_high_rail` (95.07, must not clamp) | Missing, inverted, or over-eager clamping |
| Float precision | `high_precision_decimals`, `all_zeros`, `negative_inputs` | `Float` vs `Double`; crashes on absurd input |
| Real holdout rows | `holdout_row_0`–`4` | End-to-end drift |

Independently cross-checked: the five holdout profiles match the committed
`ml/results/prediction_results.csv` to 0.0 (one row at 1.4e-14).

### Why these anchors matter

`at_training_mean` alone validates `mean[]`, `scale[]`, and `intercept` together —
if any is mistyped, z ≠ 0 and the result diverges from 67.90012499999999.
`one_sd_above_mean` must equal `intercept + sum(coef)`. Both are asserted in the
generator, so a corrupt export fails at build time rather than in Swift.

Feature values are stored as a **keyed dictionary**, not a bare array, and Swift
rebuilds the ordered vector via `TwinTrackFeature.allCases`. A JSON key reordering
therefore cannot silently permute features.

### Result

Simulating the full Swift path against all 21 profiles:

```
worst raw Δ    : 2.84e-14
worst clamped Δ: 2.84e-14
failures       : none
headroom       : ~3.5e7x under the 1e-6 tolerance
```

If Swift lands outside 1e-6, the cause is a real porting defect — not accumulated
float error.

---

## 6. Suggested order of work

1. Commit `twintrack_model_params.json`, `golden_profiles.json`, and
   `export_for_swift.py` — this is the durable freeze.
2. Drop `TwinTrackModel.swift` into the Xcode project; wire `GoldenRunner.run`
   into an XCTest case and confirm 21/21.
3. Only then build the HealthKit layer on top.

Step 2 before step 3. If parity is going to break, it should break in an isolated
test with 21 named profiles — not while you are also debugging HealthKit
permissions a month before the presentation.
