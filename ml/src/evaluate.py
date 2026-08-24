import pandas as pd
import joblib
import matplotlib.pyplot as plt
from pathlib import Path

from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# Paths
project_root = Path(__file__).resolve().parents[1]
data_file = project_root / "data" / "synthetic_students.csv"
model_file = project_root / "models" / "twintrack_model.joblib"
results_dir = project_root / "results"
results_dir.mkdir(parents=True, exist_ok=True)

# Load dataset
df = pd.read_csv(data_file)

# Load the saved trained model
saved = joblib.load(model_file)

model = saved["model"]
feature_columns = saved["features"]
model_name = saved["model_name"]

# Separate features and target
X = df[feature_columns]
y = df["assessment_score"]

# Re-create the same 80/20 split used during training
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42
)

# Predict the unseen test data
predictions = model.predict(X_test)

# Calculate evaluation metrics
mae = mean_absolute_error(y_test, predictions)
rmse = mean_squared_error(y_test, predictions) ** 0.5
r2 = r2_score(y_test, predictions)

print("=== TWINTRACK MODEL EVALUATION ===")
print(f"Model: {model_name}")
print(f"Test observations: {len(y_test)}")
print()
print(f"MAE:  {mae:.2f}")
print(f"RMSE: {rmse:.2f}")
print(f"R²:   {r2:.3f}")

# Create a table of actual vs predicted values
results = pd.DataFrame({
    "actual_score": y_test.values,
    "predicted_score": predictions
})

results["error"] = results["predicted_score"] - results["actual_score"]
results["absolute_error"] = results["error"].abs()

# Save detailed prediction results
results_file = results_dir / "prediction_results.csv"
results.to_csv(results_file, index=False)

print("\n=== SAMPLE PREDICTIONS ===")
print(results.head(10).round(2))

print("\n=== ERROR SUMMARY ===")
print(results["absolute_error"].describe().round(2))

# Create Actual vs Predicted graph
plt.figure(figsize=(8, 6))

plt.scatter(
    results["actual_score"],
    results["predicted_score"],
    alpha=0.7
)

minimum = min(
    results["actual_score"].min(),
    results["predicted_score"].min()
)

maximum = max(
    results["actual_score"].max(),
    results["predicted_score"].max()
)

# Perfect prediction reference line
plt.plot(
    [minimum, maximum],
    [minimum, maximum],
    linestyle="--"
)

plt.xlabel("Actual Assessment Score")
plt.ylabel("Predicted Assessment Score")
plt.title(f"TwinTrack AI - Actual vs Predicted ({model_name})")
plt.grid(alpha=0.25)
plt.tight_layout()

graph_file = results_dir / "actual_vs_predicted.png"
plt.savefig(graph_file, dpi=200)
plt.close()

print(f"\nSaved prediction results to: {results_file}")
print(f"Saved evaluation graph to: {graph_file}")