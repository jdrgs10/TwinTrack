import pandas as pd
import joblib
from pathlib import Path

# -----------------------------
# 1. Locate saved model
# -----------------------------

project_root = Path(__file__).resolve().parents[1]
model_file = project_root / "models" / "twintrack_model.joblib"

# -----------------------------
# 2. Load trained model
# -----------------------------

saved = joblib.load(model_file)

model = saved["model"]
feature_columns = saved["features"]
model_name = saved["model_name"]

# -----------------------------
# 3. Reusable prediction function
# -----------------------------

def predict_score(
    sleep_hours,
    steps,
    exercise_minutes,
    resting_heart_rate,
    study_minutes,
    screen_time_minutes,
    previous_score,
):
    student = pd.DataFrame(
        [{
            "sleep_hours": sleep_hours,
            "steps": steps,
            "exercise_minutes": exercise_minutes,
            "resting_heart_rate": resting_heart_rate,
            "study_minutes": study_minutes,
            "screen_time_minutes": screen_time_minutes,
            "previous_score": previous_score,
        }],
        columns=feature_columns
    )

    prediction = model.predict(student)[0]

    # Keep result inside a realistic percentage range
    prediction = max(0, min(100, prediction))

    return prediction


# -----------------------------
# 4. Example prediction
# -----------------------------

if __name__ == "__main__":

    print("=== TWINTRACK PREDICTION ===")
    print(f"Model: {model_name}")

    score = predict_score(
        sleep_hours=7.2,
        steps=7500,
        exercise_minutes=30,
        resting_heart_rate=68,
        study_minutes=100,
        screen_time_minutes=200,
        previous_score=76,
    )

    print(f"\nPredicted assessment score: {score:.1f}%")