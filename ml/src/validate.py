import pandas as pd
import numpy as np
import joblib
from pathlib import Path

from sklearn.model_selection import KFold, cross_validate

# -----------------------------
# 1. Locate files
# -----------------------------

project_root = Path(__file__).resolve().parents[1]
data_file = project_root / "data" / "synthetic_students.csv"
model_file = project_root / "models" / "twintrack_model.joblib"

# -----------------------------
# 2. Load data and model
# -----------------------------

df = pd.read_csv(data_file)

saved = joblib.load(model_file)

model = saved["model"]
feature_columns = saved["features"]
model_name = saved["model_name"]

X = df[feature_columns]
y = df["assessment_score"]

# -----------------------------
# 3. Create 5-fold cross-validation
# -----------------------------

cv = KFold(
    n_splits=5,
    shuffle=True,
    random_state=42
)

# -----------------------------
# 4. Evaluate model
# -----------------------------

scores = cross_validate(
    model,
    X,
    y,
    cv=cv,
    scoring={
        "mae": "neg_mean_absolute_error",
        "r2": "r2"
    }
)

# sklearn returns MAE as negative, so convert it back
mae_scores = -scores["test_mae"]
r2_scores = scores["test_r2"]

# -----------------------------
# 5. Show each fold
# -----------------------------

print("=== TWINTRACK CROSS-VALIDATION ===")
print(f"Model: {model_name}")

for i, (mae, r2) in enumerate(
    zip(mae_scores, r2_scores),
    start=1
):
    print(
        f"Fold {i}: "
        f"MAE = {mae:.2f}, "
        f"R² = {r2:.3f}"
    )

# -----------------------------
# 6. Overall results
# -----------------------------

print("\n=== AVERAGE PERFORMANCE ===")

print(f"Average MAE: {np.mean(mae_scores):.2f}")
print(f"MAE variation: ±{np.std(mae_scores):.2f}")

print(f"Average R²: {np.mean(r2_scores):.3f}")
print(f"R² variation: ±{np.std(r2_scores):.3f}")