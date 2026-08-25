# TwinTrack AI

TwinTrack is a personal digital twin that connects lifestyle, wearable, and academic data with machine-learning predictions and what-if simulations.

The goal is to help a user explore how different versions of their current profile affect TwinTrack's estimated academic score.

## Current Prototype

The current Windows/Python prototype includes:

- A trained Ridge Regression prediction model
- Lifestyle and academic profile inputs
- What-if simulations
- Model-tested recommendations
- A local conversational digital-twin layer using Qwen3 4B through Ollama
- Input validation and extrapolation warnings
- Automated regression testing

## Inputs

TwinTrack currently uses seven inputs:

- Sleep hours
- Steps
- Exercise minutes
- Resting heart rate
- Study minutes
- Screen time minutes
- Previous academic score

The current Python prototype uses a hardcoded example profile.

Future versions will replace supported wearable values with real Apple Health / HealthKit data from an iPhone and Apple Watch.

## Prediction Output

TwinTrack predicts an estimated academic assessment score from 0 to 100.

For example:

```text
Current profile: 62.8%
9 hours of sleep: 65.4%
Estimated change: +2.7 points