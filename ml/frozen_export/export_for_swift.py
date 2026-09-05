"""
export_for_swift.py

Freezes the production TwinTrack Ridge pipeline into plain numbers that a
native Swift implementation can consume, and emits golden test vectors so
the Swift port can be verified against Python to ~1e-6.

This script is READ-ONLY with respect to the model:
it never retrains, never refits, and never touches twintrack_model.joblib.

Outputs (written to ml/export/):
    twintrack_model_params.json   scaler + ridge parameters, feature order
    golden_profiles.json          20 profiles with expected predictions

Run:
    python ml/src/export_for_swift.py
"""

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

ML_ROOT = Path(__file__).resolve().parents[1]
MODEL_FILE = ML_ROOT / "models" / "twintrack_model.joblib"
DATA_FILE = ML_ROOT / "data" / "synthetic_students.csv"
EXPORT_DIR = ML_ROOT / "export"

EXPORT_DIR.mkdir(parents=True, exist_ok=True)


# -----------------------------------------------------
# 1. Load the frozen production model
# -----------------------------------------------------

saved = joblib.load(MODEL_FILE)

model = saved["model"]
feature_columns = list(saved["features"])

scaler = model.named_steps["scaler"]
ridge = model.named_steps["ridge"]

mean = scaler.mean_
scale = scaler.scale_
coef = ridge.coef_
intercept = float(ridge.intercept_)


# -----------------------------------------------------
# 2. Prediction contract
# -----------------------------------------------------
#
# This is EXACTLY what Swift must implement. It has been verified
# bit-identical to sklearn's Pipeline.predict on all 200 holdout rows.
#
#     z_i    = (x_i - mean_i) / scale_i
#     raw    = sum_i(coef_i * z_i) + intercept
#     score  = min(100, max(0, raw))
#
# NOTE ON CLAMPING:
# The [0, 100] clamp lives in the APPLICATION layer
# (assistant.predict_score / predict.predict_score / simulate.predict_score),
# NOT inside the sklearn pipeline. evaluate.py and baselines.py deliberately
# score UNCLAMPED predictions. Swift must keep both values distinct.
# -----------------------------------------------------

def predict_raw(row_values):
    z = (np.asarray(row_values, dtype=float) - mean) / scale
    return float(z @ coef + intercept)


def predict_clamped(row_values):
    return max(0.0, min(100.0, predict_raw(row_values)))


# -----------------------------------------------------
# 3. Self-check against sklearn before exporting
# -----------------------------------------------------

df = pd.read_csv(DATA_FILE)
X = df[feature_columns]
y = df["assessment_score"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.20, random_state=42
)

sklearn_predictions = model.predict(X_test)
manual_predictions = np.array(
    [predict_raw(r) for r in X_test.values]
)

max_drift = float(np.max(np.abs(sklearn_predictions - manual_predictions)))

if max_drift > 1e-9:
    raise SystemExit(
        f"ABORT: manual formula drifted from sklearn by {max_drift:.3e}"
    )

print(f"Formula self-check OK (max drift {max_drift:.3e})")


# -----------------------------------------------------
# 4. Build the parameter export
# -----------------------------------------------------

training_range = {
    feature: [float(df[feature].min()), float(df[feature].max())]
    for feature in feature_columns
}

params = {
    "schema_version": 1,
    "model_name": saved["model_name"],
    "source_artifact": "ml/models/twintrack_model.joblib",
    "feature_order": feature_columns,
    "n_features": len(feature_columns),

    "scaler": {
        "type": "StandardScaler",
        "with_mean": bool(scaler.with_mean),
        "with_std": bool(scaler.with_std),
        "ddof": 0,
        "mean": [float(v) for v in mean],
        "scale": [float(v) for v in scale],
    },

    "ridge": {
        "alpha": float(saved["best_alpha"]),
        "fit_intercept": bool(ridge.fit_intercept),
        "coef": [float(v) for v in coef],
        "intercept": intercept,
    },

    "output_clamp": {"min": 0.0, "max": 100.0},

    "training_range": training_range,

    "provenance": {
        "test_size": float(saved["test_size"]),
        "random_state": int(saved["random_state"]),
        "n_rows_total": int(len(df)),
        "n_rows_train": int(len(X_train)),
        "n_rows_holdout": int(len(X_test)),
        "cross_validated_mae": float(saved["cross_validated_mae"]),
        "holdout_metrics": {
            k: float(v) for k, v in saved["test_metrics"].items()
        },
    },
}

params_file = EXPORT_DIR / "twintrack_model_params.json"
params_file.write_text(json.dumps(params, indent=2), encoding="utf-8")
print(f"Wrote {params_file}")


# -----------------------------------------------------
# 5. Build 20 golden profiles
# -----------------------------------------------------
#
# Chosen to exercise: the exact intercept, both clamp rails, the observed
# training-range corners, real holdout rows, and awkward float values.
# -----------------------------------------------------

def row(**kwargs):
    return [float(kwargs[f]) for f in feature_columns]


golden = []


def add(name, note, values):
    golden.append(
        {
            "name": name,
            "note": note,
            "inputs": dict(zip(feature_columns, values)),
            "expected_raw": predict_raw(values),
            "expected_clamped": predict_clamped(values),
        }
    )


# 5a. Structural anchors -------------------------------------------------

# All features at the training mean => every z is 0 => raw == intercept.
# This single case validates mean[], scale[] and intercept together.
add(
    "at_training_mean",
    "All z=0; expected_raw must equal ridge.intercept exactly.",
    [float(v) for v in mean],
)

# One standard deviation above the mean on every feature => raw == intercept + sum(coef)
add(
    "one_sd_above_mean",
    "All z=+1; expected_raw must equal intercept + sum(coef).",
    [float(m + s) for m, s in zip(mean, scale)],
)

add(
    "one_sd_below_mean",
    "All z=-1; expected_raw must equal intercept - sum(coef).",
    [float(m - s) for m, s in zip(mean, scale)],
)

# 5b. The profiles the repo itself already uses --------------------------

add(
    "assistant_default_profile",
    "current{} in twintrack_assistant.py and simulate.py.",
    row(
        sleep_hours=6.0, steps=4500, exercise_minutes=15,
        resting_heart_rate=72, study_minutes=60,
        screen_time_minutes=300, previous_score=72,
    ),
)

add(
    "simulate_improved_scenario",
    "scenario{} in simulate.py.",
    row(
        sleep_hours=7.5, steps=8000, exercise_minutes=35,
        resting_heart_rate=68, study_minutes=110,
        screen_time_minutes=180, previous_score=72,
    ),
)

add(
    "predict_py_example",
    "__main__ example in predict.py.",
    row(
        sleep_hours=7.2, steps=7500, exercise_minutes=30,
        resting_heart_rate=68, study_minutes=100,
        screen_time_minutes=200, previous_score=76,
    ),
)

# 5c. Observed training-range corners ------------------------------------

add(
    "all_features_at_observed_min",
    "Lower corner of TRAINING_RANGE.",
    [training_range[f][0] for f in feature_columns],
)

add(
    "all_features_at_observed_max",
    "Upper corner of TRAINING_RANGE.",
    [training_range[f][1] for f in feature_columns],
)

add(
    "best_case_in_range",
    "Each feature pushed to its score-maximising in-range end.",
    row(
        sleep_hours=10.0, steps=14286, exercise_minutes=91.2,
        resting_heart_rate=95.8, study_minutes=262.7,
        screen_time_minutes=30.0, previous_score=100.0,
    ),
)

add(
    "worst_case_in_range",
    "Each feature pushed to its score-minimising in-range end.",
    row(
        sleep_hours=4.0, steps=1000, exercise_minutes=0.0,
        resting_heart_rate=45.0, study_minutes=0.0,
        screen_time_minutes=531.7, previous_score=38.2,
    ),
)

# 5d. Clamp rails --------------------------------------------------------

add(
    "clamp_high_rail",
    "raw > 100; expected_clamped must be exactly 100.0.",
    row(
        sleep_hours=24.0, steps=100000, exercise_minutes=600.0,
        resting_heart_rate=200.0, study_minutes=1440.0,
        screen_time_minutes=0.0, previous_score=100.0,
    ),
)

add(
    "clamp_low_rail",
    "raw < 0; expected_clamped must be exactly 0.0.",
    row(
        sleep_hours=0.0, steps=0, exercise_minutes=0.0,
        resting_heart_rate=30.0, study_minutes=0.0,
        screen_time_minutes=5000.0, previous_score=0.0,
    ),
)

add(
    "just_below_high_rail",
    "raw slightly under 100; clamp must NOT trigger.",
    row(
        sleep_hours=10.0, steps=14286, exercise_minutes=91.2,
        resting_heart_rate=95.8, study_minutes=262.7,
        screen_time_minutes=30.0, previous_score=97.0,
    ),
)

# 5e. Float-precision awkwardness ---------------------------------------

add(
    "high_precision_decimals",
    "Many significant digits; catches Float vs Double in Swift.",
    row(
        sleep_hours=7.123456789, steps=7333.987654321,
        exercise_minutes=28.87654321, resting_heart_rate=66.54321,
        study_minutes=97.13579, screen_time_minutes=231.97531,
        previous_score=77.24680,
    ),
)

add(
    "all_zeros",
    "Degenerate all-zero input; large negative z values.",
    [0.0] * len(feature_columns),
)

add(
    "negative_inputs",
    "Physically impossible negatives; must not crash, must clamp.",
    row(
        sleep_hours=-5.0, steps=-1000, exercise_minutes=-30.0,
        resting_heart_rate=-10.0, study_minutes=-60.0,
        screen_time_minutes=-100.0, previous_score=-20.0,
    ),
)

# 5f. Real holdout rows --------------------------------------------------

for idx in range(0, 5):
    values = [float(v) for v in X_test.values[idx]]
    add(
        f"holdout_row_{idx}",
        (
            f"Real holdout observation (actual assessment_score="
            f"{float(y_test.values[idx])})."
        ),
        values,
    )


# -----------------------------------------------------
# 6. Verify every golden case against sklearn itself
# -----------------------------------------------------

frame = pd.DataFrame(
    [g["inputs"] for g in golden],
    columns=feature_columns,
)

sk = model.predict(frame)

worst = 0.0
for i, g in enumerate(golden):
    worst = max(worst, abs(sk[i] - g["expected_raw"]))

if worst > 1e-9:
    raise SystemExit(f"ABORT: golden drift {worst:.3e}")

print(f"Golden self-check OK across {len(golden)} profiles "
      f"(max drift {worst:.3e})")

# Structural assertions on the anchor cases
assert golden[0]["expected_raw"] == intercept, "at_training_mean != intercept"
assert abs(golden[1]["expected_raw"] - (intercept + coef.sum())) < 1e-9
assert abs(golden[2]["expected_raw"] - (intercept - coef.sum())) < 1e-9
assert golden[10]["expected_clamped"] == 100.0
assert golden[11]["expected_clamped"] == 0.0
print("Structural anchor assertions OK")


golden_file = EXPORT_DIR / "golden_profiles.json"
golden_file.write_text(
    json.dumps(
        {
            "schema_version": 1,
            "tolerance": 1e-6,
            "feature_order": feature_columns,
            "prediction_contract": (
                "z=(x-mean)/scale ; raw=dot(coef,z)+intercept ; "
                "clamped=min(100,max(0,raw))"
            ),
            "profiles": golden,
        },
        indent=2,
    ),
    encoding="utf-8",
)

print(f"Wrote {golden_file}")
print(f"\n{len(golden)} golden profiles exported.")
