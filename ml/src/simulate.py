import pandas as pd
import joblib
from pathlib import Path

# Paths
project_root = Path(__file__).resolve().parents[1]
model_file = project_root / "models" / "twintrack_model.joblib"

# Load trained model
saved = joblib.load(model_file)

model = saved["model"]
feature_columns = saved["features"]
model_name = saved["model_name"]

print("=== TWINTRACK WHAT-IF SIMULATOR ===")
print(f"Model: {model_name}")

# Current student situation
current = {
    "sleep_hours": 6.0,
    "steps": 4500,
    "exercise_minutes": 15,
    "resting_heart_rate": 72,
    "study_minutes": 60,
    "screen_time_minutes": 300,
    "previous_score": 72,
}

# Simulated improved scenario
scenario = {
    "sleep_hours": 7.5,
    "steps": 8000,
    "exercise_minutes": 35,
    "resting_heart_rate": 68,
    "study_minutes": 110,
    "screen_time_minutes": 180,
    "previous_score": 72,
}

def predict_score(values):
    row = pd.DataFrame([values], columns=feature_columns)
    prediction = model.predict(row)[0]
    return max(0, min(100, prediction))

current_prediction = predict_score(current)
scenario_prediction = predict_score(scenario)
difference = scenario_prediction - current_prediction

print("\n=== CURRENT HABITS ===")
for key, value in current.items():
    print(f"{key}: {value}")

print(f"\nPredicted assessment score: {current_prediction:.1f}%")

print("\n=== WHAT-IF SCENARIO ===")
for key, value in scenario.items():
    print(f"{key}: {value}")

print(f"\nPredicted assessment score: {scenario_prediction:.1f}%")

print("\n=== ESTIMATED CHANGE ===")
print(f"{difference:+.1f} percentage points")

print(
    "\nImportant: This is a model-based estimate from synthetic development data. "
    "It does not prove that changing these habits will cause the predicted score change."
)