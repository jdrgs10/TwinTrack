import pandas as pd
import joblib
from pathlib import Path

from sklearn.model_selection import train_test_split, KFold, cross_validate
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor


# -----------------------------
# 1. Locate project files
# -----------------------------

project_root = Path(__file__).resolve().parents[1]
data_file = project_root / "data" / "synthetic_students.csv"
models_dir = project_root / "models"

models_dir.mkdir(parents=True, exist_ok=True)


# -----------------------------
# 2. Load the dataset
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
# 3. Create the same 80/20 split
# -----------------------------
#
# IMPORTANT:
# The 20% holdout is deliberately NOT used by this model-comparison
# script.
#
# Model selection happens using cross-validation on the 80% training
# portion only.
#
# The untouched holdout is reserved for the final tuned model in
# tune.py.
# -----------------------------

X_train, _, y_train, _ = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
)


# -----------------------------
# 4. Define candidate models
# -----------------------------

ridge_pipeline = Pipeline([
    ("scaler", StandardScaler()),
    ("ridge", Ridge(alpha=1.0)),
])

models = {
    "Standardized Ridge Regression": ridge_pipeline,

    "Random Forest": RandomForestRegressor(
        n_estimators=200,
        random_state=42,
    ),

    "Gradient Boosting": GradientBoostingRegressor(
        random_state=42,
    ),
}


# -----------------------------
# 5. Define cross-validation
# -----------------------------

cv = KFold(
    n_splits=5,
    shuffle=True,
    random_state=42,
)

scoring = {
    "mae": "neg_mean_absolute_error",
    "rmse": "neg_root_mean_squared_error",
    "r2": "r2",
}


# -----------------------------
# 6. Compare models using only
#    the training data
# -----------------------------

results = {}

print("=== MODEL COMPARISON ===")
print("Selection uses 5-fold CV on the 80% training split only.")
print("The 20% final holdout is not used here.")

for name, model in models.items():

    scores = cross_validate(
        model,
        X_train,
        y_train,
        cv=cv,
        scoring=scoring,
        n_jobs=-1,
    )

    mean_mae = -scores["test_mae"].mean()
    mean_rmse = -scores["test_rmse"].mean()
    mean_r2 = scores["test_r2"].mean()

    results[name] = {
        "cv_mae": mean_mae,
        "cv_rmse": mean_rmse,
        "cv_r2": mean_r2,
    }

    print(f"\n{name}")
    print(f"CV MAE:  {mean_mae:.2f}")
    print(f"CV RMSE: {mean_rmse:.2f}")
    print(f"CV R²:   {mean_r2:.3f}")


# -----------------------------
# 7. Select the best model using
#    TRAINING CV MAE only
# -----------------------------

best_name = min(
    results,
    key=lambda name: results[name]["cv_mae"],
)

best_model = models[best_name]

print("\n=== BEST MODEL BY TRAINING CV ===")
print(best_name)

print("\n=== BEST MODEL CV METRICS ===")
print(f"CV MAE:  {results[best_name]['cv_mae']:.2f}")
print(f"CV RMSE: {results[best_name]['cv_rmse']:.2f}")
print(f"CV R²:   {results[best_name]['cv_r2']:.3f}")


# -----------------------------
# 8. Fit the selected comparison
#    model on the full 80% train set
# -----------------------------

best_model.fit(
    X_train,
    y_train,
)


# -----------------------------
# 9. Save ONLY the comparison
#    artifact
# -----------------------------
#
# IMPORTANT:
# This script does NOT write twintrack_model.joblib.
#
# tune.py remains the sole producer of the production
# TwinTrack model.
# -----------------------------

comparison_file = models_dir / "model_comparison.joblib"

joblib.dump(
    {
        "model": best_model,
        "features": feature_columns,
        "model_name": best_name,
        "selection_method": (
            "5-fold cross-validation on the 80% training split"
        ),
        "selection_metric": "mean cross-validation MAE",
        "cv_metrics": results,
        "production_model": False,
    },
    comparison_file,
)

print(
    f"\nSaved model-comparison artifact to:\n{comparison_file}"
)

print(
    "\nProduction model unchanged."
    "\nml/models/twintrack_model.joblib is still owned by tune.py."
)