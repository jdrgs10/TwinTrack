import pandas as pd
import numpy as np
import joblib
from pathlib import Path

from sklearn.model_selection import (
    train_test_split,
    KFold,
    cross_validate,
)


# -----------------------------
# 1. Locate files
# -----------------------------

project_root = Path(__file__).resolve().parents[1]

data_file = (
    project_root
    / "data"
    / "synthetic_students.csv"
)

model_file = (
    project_root
    / "models"
    / "twintrack_model.joblib"
)


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
# 3. Recreate the same 80/20 split
# -----------------------------
#
# IMPORTANT:
# Validation below uses ONLY the 80% training portion.
#
# The final 20% holdout remains excluded and is evaluated
# separately by evaluate.py.
# -----------------------------

X_train, _, y_train, _ = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
)


# -----------------------------
# 4. Create 5-fold CV
# -----------------------------

cv = KFold(
    n_splits=5,
    shuffle=True,
    random_state=42,
)


# -----------------------------
# 5. Cross-validate on training
#    data only
# -----------------------------
#
# The saved Ridge hyperparameter is fixed here.
#
# These numbers are useful as a training-CV diagnostic,
# but the final reportable performance still comes from
# the untouched holdout in evaluate.py.
# -----------------------------

scores = cross_validate(
    model,
    X_train,
    y_train,
    cv=cv,
    scoring={
        "mae": "neg_mean_absolute_error",
        "rmse": "neg_root_mean_squared_error",
        "r2": "r2",
    },
)

# sklearn returns loss metrics as negative values.
mae_scores = -scores["test_mae"]
rmse_scores = -scores["test_rmse"]
r2_scores = scores["test_r2"]


# -----------------------------
# 6. Show each fold
# -----------------------------

print("=== TWINTRACK TRAINING CROSS-VALIDATION ===")
print(f"Model: {model_name}")
print(f"Training observations used: {len(X_train)}")
print("Final 20% holdout excluded: YES")

for i, (mae, rmse, r2) in enumerate(
    zip(
        mae_scores,
        rmse_scores,
        r2_scores,
    ),
    start=1,
):
    print(
        f"Fold {i}: "
        f"MAE = {mae:.2f}, "
        f"RMSE = {rmse:.2f}, "
        f"R² = {r2:.3f}"
    )


# -----------------------------
# 7. Overall results
# -----------------------------

print("\n=== AVERAGE TRAINING-CV PERFORMANCE ===")

print(
    f"Average MAE: "
    f"{np.mean(mae_scores):.2f}"
)

print(
    f"MAE fold variation: "
    f"{np.std(mae_scores):.2f}"
)

print(
    f"Average RMSE: "
    f"{np.mean(rmse_scores):.2f}"
)

print(
    f"RMSE fold variation: "
    f"{np.std(rmse_scores):.2f}"
)

print(
    f"Average R²: "
    f"{np.mean(r2_scores):.3f}"
)

print(
    f"R² fold variation: "
    f"{np.std(r2_scores):.3f}"
)


# -----------------------------
# 8. Methodology reminder
# -----------------------------

print(
    "\nIMPORTANT:"
    "\nThese cross-validation results are a diagnostic "
    "on the 80% training portion."
    "\nThe final reportable model performance comes "
    "from the untouched 20% holdout in evaluate.py."
)