from pathlib import Path

import joblib
import pandas as pd

from sklearn.dummy import DummyRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split


# =====================================================
# PATHS
# =====================================================

ML_ROOT = Path(__file__).resolve().parents[1]

DATA_FILE = ML_ROOT / "data" / "synthetic_students.csv"
MODEL_FILE = ML_ROOT / "models" / "twintrack_model.joblib"
RESULTS_DIR = ML_ROOT / "results"

RESULTS_DIR.mkdir(parents=True, exist_ok=True)


# =====================================================
# LOAD DATA
# =====================================================

df = pd.read_csv(DATA_FILE)

saved = joblib.load(MODEL_FILE)

feature_columns = saved["features"]
production_model = saved["model"]

target_column = "assessment_score"

X = df[feature_columns]
y = df[target_column]


# Use exactly the same 80/20 split as TwinTrack.
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
)


# =====================================================
# 1. MEAN-ONLY BASELINE
# =====================================================

dummy = DummyRegressor(strategy="mean")

dummy.fit(X_train, y_train)

dummy_predictions = dummy.predict(X_test)

dummy_mae = mean_absolute_error(
    y_test,
    dummy_predictions,
)

dummy_r2 = r2_score(
    y_test,
    dummy_predictions,
)


# =====================================================
# 2. PREVIOUS-SCORE-ONLY BASELINE
# =====================================================

previous_score_model = LinearRegression()

previous_score_model.fit(
    X_train[["previous_score"]],
    y_train,
)

previous_score_predictions = previous_score_model.predict(
    X_test[["previous_score"]]
)

previous_score_mae = mean_absolute_error(
    y_test,
    previous_score_predictions,
)

previous_score_r2 = r2_score(
    y_test,
    previous_score_predictions,
)


# =====================================================
# 3. FULL TWINTRACK RIDGE MODEL
# =====================================================

ridge_predictions = production_model.predict(X_test)

ridge_mae = mean_absolute_error(
    y_test,
    ridge_predictions,
)

ridge_r2 = r2_score(
    y_test,
    ridge_predictions,
)


# =====================================================
# RESULTS
# =====================================================

results = pd.DataFrame(
    [
        {
            "model": "Mean-only baseline",
            "MAE": dummy_mae,
            "R2": dummy_r2,
        },
        {
            "model": "Previous-score-only",
            "MAE": previous_score_mae,
            "R2": previous_score_r2,
        },
        {
            "model": "Full TwinTrack Ridge",
            "MAE": ridge_mae,
            "R2": ridge_r2,
        },
    ]
)

print("\nTwinTrack Baseline Comparison")
print("=" * 50)

print(
    results.to_string(
        index=False,
        formatters={
            "MAE": lambda value: f"{value:.2f}",
            "R2": lambda value: f"{value:.3f}",
        },
    )
)

output_file = RESULTS_DIR / "baseline_comparison.csv"

results.to_csv(
    output_file,
    index=False,
)

print(
    f"\nSaved baseline comparison to:\n{output_file}"
)

print(
    "\nImportant:"
    "\nThese results come from synthetic development data."
    "\nThey do not demonstrate real-world academic relationships."
)