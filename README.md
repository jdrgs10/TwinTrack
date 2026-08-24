# TwinTrack
TwinTrack AI graduation project
# TwinTrack AI

TwinTrack is a personal digital twin that connects lifestyle data with academic performance predictions.

## Inputs
- Sleep hours
- Steps
- Exercise minutes
- Resting heart rate
- Study time
- Screen time
- Previous academic score

## Output
TwinTrack predicts an estimated assessment score from 0–100%.

## Machine Learning
The main predictive model is a **Standardized Ridge Regression model trained for TwinTrack**.

Three models were tested:
- Ridge Regression
- Random Forest
- Gradient Boosting

Ridge Regression performed best and was selected.

## Training and Evaluation
- 1,000 synthetic development observations
- 80% training data
- 20% untouched final test data
- 5-fold cross-validation
- Hyperparameter tuning performed only on the training set

Final test results:

- MAE: **4.76**
- RMSE: **5.87**
- R²: **0.570**

The synthetic dataset is used for prototype development and does not prove real-world causal relationships.

## What-If Simulation
TwinTrack can change lifestyle inputs and run the trained model again to compare predicted outcomes.

Example:

`Current profile → 62.8%`

`More sleep + more study time → 66.5%`

## Conversational Twin
TwinTrack also uses a **pretrained Qwen3 4B Instruct model running locally through Ollama**.

The Ridge model calculates all prediction numbers.

Qwen only explains predictions, recommendations, and simulations in natural language.

## Privacy
The AI runs locally and does not require ChatGPT or Claude APIs for predictions or conversation.

## Future Integration
The planned iPhone version will use Apple Health / HealthKit to provide data such as:

- Sleep
- Steps
- Exercise
- Resting heart rate

Study time, screen time, and academic results can initially be entered manually.

## Limitation
The current model is a development prototype trained on synthetic data. Real-world validation would require genuine observations collected over time.