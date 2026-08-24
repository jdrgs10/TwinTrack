import pandas as pd
import joblib
from pathlib import Path

from sklearn.model_selection import train_test_split, GridSearchCV, KFold
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# -----------------------------
# 1. Paths
# -----------------------------

project_root = Path(__file__).resolve().parents[1]
data_file = project_root / "data" / "synthetic_students.csv"
models_dir = project_root / "models"
models_dir.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 2. Load dataset
# -----------------------------

df = pd.read_csv(data_file)

feature_columns = [
    "sleep_hours",
    "steps",
    "exercise_minutes",
    "resting_heart_rate",
    "study_minutes",
    "screen_time_minutes",
    "previous_score",
]

X = df[feature_columns]
y = df["assessment_score"]

# -----------------------------
# 3. Create TRUE hold-out test set
# -----------------------------

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42
)

print("=== DATA SPLIT ===")
print(f"Training observations: {len(X_train)}")
print(f"Untouched test observations: {len(X_test)}")

# -----------------------------
# 4. Model pipeline
# -----------------------------

pipeline = Pipeline([
    ("scaler", StandardScaler()),
    ("ridge", Ridge())
])

parameter_grid = {
    "ridge__alpha": [
        0.01,
        0.1,
        0.5,
        1.0,
        2.0,
        5.0,
        10.0,
        20.0,
        50.0,
        100.0
    ]
}

# -----------------------------
# 5. Tune ONLY using training data
# -----------------------------

cv = KFold(
    n_splits=5,
    shuffle=True,
    random_state=42
)

search = GridSearchCV(
    pipeline,
    parameter_grid,
    scoring="neg_mean_absolute_error",
    cv=cv,
    n_jobs=-1
)

print("\n=== TWINTRACK RIDGE TUNING ===")

search.fit(X_train, y_train)

best_model = search.best_estimator_
best_alpha = search.best_params_["ridge__alpha"]
cv_mae = -search.best_score_

print(f"Best alpha: {best_alpha}")
print(f"Training cross-validation MAE: {cv_mae:.2f}")

# -----------------------------
# 6. FINAL untouched test
# -----------------------------

predictions = best_model.predict(X_test)

test_mae = mean_absolute_error(y_test, predictions)
test_rmse = mean_squared_error(y_test, predictions) ** 0.5
test_r2 = r2_score(y_test, predictions)

print("\n=== FINAL HOLD-OUT TEST ===")
print(f"MAE:  {test_mae:.2f}")
print(f"RMSE: {test_rmse:.2f}")
print(f"R²:   {test_r2:.3f}")

# -----------------------------
# 7. Save model
# -----------------------------

model_file = models_dir / "twintrack_model.joblib"

joblib.dump(
    {
        "model": best_model,
        "features": feature_columns,
        "model_name": "Tuned Standardized Ridge Regression",
        "best_alpha": best_alpha,
        "cross_validated_mae": cv_mae,
        "test_metrics": {
            "mae": test_mae,
            "rmse": test_rmse,
            "r2": test_r2
        },
        "test_size": 0.20,
        "random_state": 42
    },
    model_file
)

print(f"\nSaved model to: {model_file}")