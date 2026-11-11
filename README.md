TwinTrack AI

TwinTrack AI is an iOS and iPadOS application that brings student health, daily habits, and academic information together in one place.

The goal is to help students understand their routines, explore different scenarios, and make more informed decisions about their wellbeing and academic habits.

Rather than focusing only on grades, TwinTrack encourages students to consider the bigger picture: sleep, physical activity, study time, and other daily behaviors.

The Problem

Students often focus heavily on academic performance while overlooking their health and daily routines.

Information about sleep, exercise, study habits, and academic results is usually spread across different applications or recorded separately.

This makes it difficult for students to understand their overall routines or explore how changes in their habits might relate to academic performance.

Our Solution

TwinTrack AI combines health and academic information into a personal digital profile.

The application provides:

* Apple Health integration: Access supported health measurements through HealthKit.
* Academic habit tracking: Record study time, recreational screen time, and previous assessment scores.
* Machine-learning estimates: Generate experimental academic assessment estimates using Ridge Regression.
* What-If simulations: Change selected inputs and compare the model’s estimated results.
* On-device AI assistant: Ask questions about studying, wellbeing, and available application information.
* Cross-device workflow: Collect health information through an Apple Watch and iPhone, then review synchronized Apple Health information on a compatible iPad.

TwinTrack is designed to support student awareness and reflection, not replace academic advice or guarantee improved grades.

Application Features

1. Home Dashboard

The Home screen brings relevant health and academic information together, allowing students to review their recorded habits and experimental assessment estimates.

2. TwinTrack AI Assistant

The conversational assistant uses Apple’s Foundation Models framework on supported devices.

It can answer general questions about studying and wellbeing and explain available application information.

The conversational assistant is separate from the Ridge Regression model and does not calculate the numerical assessment estimate.

3. What-If Simulations

Students can modify selected profile values and recalculate the model’s estimate.

For example, they can explore how the model responds to changing sleep hours, exercise minutes, or study time.

These simulations show changes in the model’s output, not proven cause-and-effect relationships or guaranteed academic improvements.

4. Profile

The Profile section provides access to the student’s personal information and relevant settings.

Model Inputs

TwinTrack uses seven numerical inputs:

Input	Source
Sleep hours	Apple Health
Daily steps	Apple Health
Exercise minutes	Apple Health
Resting heart rate	Apple Health
Study minutes	Manual entry
Recreational screen time	Manual entry
Previous assessment score	Manual entry

Apple Watch measurements can become available through Apple Health synchronization with the iPhone.

TwinTrack does not require a direct connection to the Apple Watch.

Machine Learning

TwinTrack uses Ridge Regression, a regularized linear regression algorithm.

The reference model was developed using Python and scikit-learn, with a corresponding numerical implementation in Swift.

The recorded Ridge V2 configuration uses an alpha value of 0.1.

Regularization helps control model complexity and reduce the risk of overfitting.

Prediction Output

The model generates an experimental academic assessment score estimate on a 0–100 scale.

An illustrative What-If comparison might look like this:

* Current estimated score: 62.8%
* Estimate after changing sleep to 9 hours: 65.4%
* Difference: approximately +2.6 percentage points

These example values are illustrative, not verified outputs from the current application.

Important Limitation

The model was trained using synthetic student profiles.

Although its numerical implementation has been tested, its accuracy for predicting real students’ academic results has not yet been established.

The estimates should therefore be treated as experimental outputs for exploration and reflection.

Technology Stack

Technology	Purpose
Swift	Native application development
SwiftUI	Application interface
Xcode	Development and testing
HealthKit	Apple Health integration
Python	Reference model development
scikit-learn	Ridge Regression training
Apple Foundation Models	On-device conversational AI
Git / GitHub	Version control

Testing and Verification

During recorded development testing, TwinTrack achieved:

* 534/534 automated test executions passed
* 176/176 Ridge V2 numerical parity checks passed
* Build + Analyze: Passed without reported warnings
* Physical iPhone testing performed
* Apple Health synchronization tested between personal iPhone and iPad devices

Numerical parity confirms that the Swift implementation produces results consistent with the reference model.

It does not demonstrate real-world prediction accuracy.

These figures describe a recorded development test run rather than an independently verified final release.

Privacy and Data Handling

TwinTrack is designed with an emphasis on privacy.

* Health information is accessed using Apple’s HealthKit permission system.
* The conversational assistant uses on-device AI on supported hardware.
* Conversation history is stored locally.
* The experimental numerical model runs on the device.

Health information access depends on user permissions and device availability.

Development History

TwinTrack began as a Windows/Python prototype featuring:

* Ridge Regression predictions
* Lifestyle and academic profile inputs
* What-If simulations
* Model-tested recommendations
* A local Qwen3 4B conversational layer using Ollama
* Input validation and extrapolation warnings
* Automated regression tests

The project subsequently evolved into a native Apple-platform application using Swift, SwiftUI, HealthKit, and Apple Foundation Models.

The original Python implementation remains relevant to the project’s machine-learning development and numerical verification.

Related Project: Weekly Planner

Alongside TwinTrack, our team also developed a Weekly Planner, a web-based tool designed to help students organize tasks, manage schedules, and plan their study time.

The two projects address complementary needs:

* TwinTrack AI: Helps students understand their health and academic habits.
* Weekly Planner: Helps students organize their responsibilities and put better routines into practice.

Together, they support a more balanced and organized approach to student life.

The Weekly Planner is a related project, not a claimed integrated feature of the current TwinTrack application.

Future Development

Planned improvements include:

1. Synchronizing manually entered academic information between devices.
2. Evaluating the machine-learning model using real student data collected with appropriate consent.
3. Improving model reliability and usefulness based on validation results.
4. Exploring optional teacher progress-sharing features with appropriate privacy controls.
5. Further improving the application interface and student experience.

Project Team

Graduation Project — Grade 12 CAI02

Team Members

* Mansoor Eissa
* Ahmed Tareq
* Mohamed Mabkhoot
* Ahmed Ibrahim

Supervisor: Mr. Abdullatif Faleh

Disclaimer

TwinTrack AI is an educational prototype.

Its academic estimates and What-If simulations are experimental and should not be interpreted as verified predictions, causal conclusions, or guarantees of academic improvement.

⸻

TwinTrack AI — Understand your habits. See the bigger picture. Make informed decisions.
