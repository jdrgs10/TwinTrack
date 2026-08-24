import pandas as pd
import joblib
from pathlib import Path

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

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
# 3. Split training/test data
# -----------------------------

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42
)

# -----------------------------
# 4. Define models
# -----------------------------

# Ridge needs scaling because its features use very different units.
ridge_pipeline = Pipeline([
    ("scaler", StandardScaler()),
    ("ridge", Ridge(alpha=1.0))
])

models = {
    "Standardized Ridge Regression": ridge_pipeline,

    "Random Forest": RandomForestRegressor(
        n_estimators=200,
        random_state=42
    ),

    "Gradient Boosting": GradientBoostingRegressor(
        random_state=42
    ),
}

# -----------------------------
# 5. Train and evaluate models
# -----------------------------

results = {}

print("=== MODEL TRAINING ===")

for name, model in models.items():

    model.fit(X_train, y_train)

    predictions = model.predict(X_test)

    mae = mean_absolute_error(y_test, predictions)
    rmse = mean_squared_error(y_test, predictions) ** 0.5
    r2 = r2_score(y_test, predictions)

    results[name] = {
        "model": model,
        "mae": mae,
        "rmse": rmse,
        "r2": r2,
    }

    print(f"\n{name}")
    print(f"MAE:  {mae:.2f}")
    print(f"RMSE: {rmse:.2f}")
    print(f"R²:   {r2:.3f}")

# -----------------------------
# 6. Select best model
# -----------------------------

best_name = min(
    results,
    key=lambda name: results[name]["mae"]
)

best_model = results[best_name]["model"]

print("\n=== BEST MODEL ===")
print(best_name)

print("\n=== BEST MODEL METRICS ===")
print(f"MAE:  {results[best_name]['mae']:.2f}")
print(f"RMSE: {results[best_name]['rmse']:.2f}")
print(f"R²:   {results[best_name]['r2']:.3f}")

# -----------------------------
# 7. Save the winning model
# -----------------------------

model_file = models_dir / "twintrack_model.joblib"

joblib.dump(
    {
        "model": best_model,
        "features": feature_columns,
        "model_name": best_name,
        "metrics": {
            "mae": results[best_name]["mae"],
            "rmse": results[best_name]["rmse"],
            "r2": results[best_name]["r2"],
        }
    },
    model_file
)

print(f"\nSaved model to: {model_file}")
