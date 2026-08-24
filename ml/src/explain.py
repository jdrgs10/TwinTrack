import pandas as pd
import joblib
import matplotlib.pyplot as plt
from pathlib import Path

# Paths
project_root = Path(__file__).resolve().parents[1]
model_file = project_root / "models" / "twintrack_model.joblib"
results_dir = project_root / "results"
results_dir.mkdir(parents=True, exist_ok=True)

# Load saved model
saved = joblib.load(model_file)

pipeline = saved["model"]
feature_columns = saved["features"]
model_name = saved["model_name"]

print("=== TWINTRACK MODEL EXPLANATION ===")
print(f"Model: {model_name}")

# Get Ridge Regression from inside the pipeline
ridge_model = pipeline.named_steps["ridge"]

# Because the inputs were standardized before Ridge,
# these coefficients are now much more comparable.
coefficients = pd.DataFrame({
    "feature": feature_columns,
    "coefficient": ridge_model.coef_
})

coefficients["absolute_importance"] = coefficients["coefficient"].abs()

coefficients = coefficients.sort_values(
    "absolute_importance",
    ascending=False
)

print("\n=== STANDARDIZED COEFFICIENTS ===")
print(coefficients.round(4))

# Save results
csv_file = results_dir / "feature_coefficients.csv"
coefficients.to_csv(csv_file, index=False)

# Create graph
plot_data = coefficients.sort_values("coefficient")

plt.figure(figsize=(9, 6))

plt.barh(
    plot_data["feature"],
    plot_data["coefficient"]
)

plt.axvline(0, linewidth=1)

plt.xlabel("Standardized Ridge Coefficient")
plt.ylabel("Feature")
plt.title("TwinTrack AI - Feature Influence")
plt.tight_layout()

graph_file = results_dir / "feature_coefficients.png"

plt.savefig(
    graph_file,
    dpi=200
)

plt.close()

print(f"\nSaved coefficient data to: {csv_file}")
print(f"Saved graph to: {graph_file}")

print(
    "\nPositive values push predictions upward; "
    "negative values push predictions downward. "
    "Because the inputs were standardized before training, "
    "the coefficient magnitudes are more comparable."
)