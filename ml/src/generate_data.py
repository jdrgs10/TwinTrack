import numpy as np
import pandas as pd
from pathlib import Path

# Makes the random data reproducible.
# This means we get the same dataset each time while developing.
rng = np.random.default_rng(42)

# Number of synthetic student observations
N_ROWS = 1000

# Generate realistic-looking lifestyle inputs
sleep_hours = np.clip(rng.normal(7.0, 1.2, N_ROWS), 4.0, 10.0)
steps = np.clip(rng.normal(7000, 2500, N_ROWS), 1000, 18000)
exercise_minutes = np.clip(rng.normal(30, 20, N_ROWS), 0, 120)
resting_heart_rate = np.clip(rng.normal(68, 9, N_ROWS), 45, 100)
study_minutes = np.clip(rng.normal(90, 50, N_ROWS), 0, 300)
screen_time_minutes = np.clip(rng.normal(240, 90, N_ROWS), 30, 600)
previous_score = np.clip(rng.normal(75, 12, N_ROWS), 30, 100)

# Create a synthetic target.
# IMPORTANT:
# This is only for development/testing.
# These weights are not claims about real students.
noise = rng.normal(0, 6, N_ROWS)

assessment_score = (
    18
    + 0.9 * sleep_hours
    + 0.00025 * steps
    + 0.025 * exercise_minutes
    - 0.035 * (resting_heart_rate - 65)
    + 0.035 * study_minutes
    - 0.012 * screen_time_minutes
    + 0.55 * previous_score
    + noise
)

assessment_score = np.clip(assessment_score, 0, 100)

# Put everything into a table
df = pd.DataFrame(
    {
        "sleep_hours": sleep_hours.round(2),
        "steps": steps.round().astype(int),
        "exercise_minutes": exercise_minutes.round(1),
        "resting_heart_rate": resting_heart_rate.round(1),
        "study_minutes": study_minutes.round(1),
        "screen_time_minutes": screen_time_minutes.round(1),
        "previous_score": previous_score.round(1),
        "assessment_score": assessment_score.round(1),
    }
)

# Find the ml/data folder
project_root = Path(__file__).resolve().parents[1]
data_dir = project_root / "data"
data_dir.mkdir(parents=True, exist_ok=True)

output_file = data_dir / "synthetic_students.csv"

# Save the dataset
df.to_csv(output_file, index=False)

print(f"Created {len(df)} synthetic observations.")
print(f"Saved dataset to: {output_file}")
print()
print(df.head())