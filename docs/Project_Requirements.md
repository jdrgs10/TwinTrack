# TwinTrack AI — Project Requirements

## Project

TwinTrack AI is a Grade 12 graduation project built as a native iPhone app using Swift and SwiftUI.

The app acts as a student digital twin by combining wearable and academic inputs to predict an assessment score and support deterministic What-If simulation.

## Final Navigation

The app must have exactly 3 tabs:

- Home
- TwinTrack AI
- Profile

Do not add extra tabs.

## Prediction Model

The numerical prediction engine is a frozen standardized Ridge Regression model.

The model uses exactly 7 inputs in this exact order:

1. `sleep_hours`
2. `steps`
3. `exercise_minutes`
4. `resting_heart_rate`
5. `study_minutes`
6. `screen_time_minutes`
7. `previous_score`

Do not add an eighth prediction input.

## Data Sources

### Apple Health / HealthKit

- Sleep Hours
- Steps
- Exercise Minutes
- Resting Heart Rate

### Manual

- Study Minutes
- Screen Time Minutes
- Previous Score

## Ridge Rules

All prediction and What-If numbers must come from the frozen Ridge model.

Prediction contract:

```text
z = (x - mean) / scale
raw = dot(coef, z) + intercept
clamped = min(100, max(0, raw))
