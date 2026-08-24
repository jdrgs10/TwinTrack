import pandas as pd
from pathlib import Path

# Find the dataset file
project_root = Path(__file__).resolve().parents[1]
data_file = project_root / "data" / "synthetic_students.csv"

# Load the dataset
df = pd.read_csv(data_file)

print("=== DATASET SHAPE ===")
print(df.shape)

print("\n=== COLUMNS ===")
print(df.columns.tolist())

print("\n=== FIRST 5 ROWS ===")
print(df.head())

print("\n=== MISSING VALUES ===")
print(df.isnull().sum())

print("\n=== SUMMARY STATISTICS ===")
print(df.describe())

print("\n=== CORRELATION WITH ASSESSMENT SCORE ===")
print(
    df.corr(numeric_only=True)["assessment_score"]
    .sort_values(ascending=False)
)