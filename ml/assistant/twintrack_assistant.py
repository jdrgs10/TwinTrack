import json
import math
import re
import urllib.request
from pathlib import Path

import joblib
import pandas as pd


# =====================================================
# 1. CONFIGURATION
# =====================================================

QWEN_MODEL = "qwen3:4b-instruct"
OLLAMA_URL = "http://localhost:11434/api/chat"

# Final untouched synthetic holdout MAE from evaluate.py.
# This is an average absolute error, NOT a confidence interval.
HOLDOUT_MAE = 4.76

ml_root = Path(__file__).resolve().parents[1]
model_file = ml_root / "models" / "twintrack_model.joblib"


# =====================================================
# 2. LOAD TWINTRACK PREDICTION MODEL
# =====================================================

saved = joblib.load(model_file)

prediction_model = saved["model"]
feature_columns = saved["features"]
model_name = saved["model_name"]


# =====================================================
# 3. PREDICTION FUNCTION
# =====================================================

def predict_score(student_data):

    row = pd.DataFrame(
        [student_data],
        columns=feature_columns
    )

    prediction = float(
        prediction_model.predict(row)[0]
    )

    # Academic score output is limited to 0–100.
    return max(0.0, min(100.0, prediction))


# =====================================================
# 4. CURRENT DIGITAL-TWIN PROFILE
# =====================================================
#
# These are prototype values for now.
# Later, Apple Health / HealthKit can replace the wearable
# values with the user's real iPhone and Apple Watch data.
# =====================================================

current = {
    "sleep_hours": 6.0,
    "steps": 4500,
    "exercise_minutes": 15,
    "resting_heart_rate": 72,
    "study_minutes": 60,
    "screen_time_minutes": 300,
    "previous_score": 72,
}

current_score = predict_score(current)


# =====================================================
# 4B. OBSERVED TRAINING-DATA RANGE
# =====================================================
#
# Used only to warn when a what-if scenario goes outside
# the values observed in the synthetic development data.
# TwinTrack still calculates the scenario, but labels it as
# extrapolation instead of presenting it with full confidence.
# =====================================================

training_data_file = (
    ml_root
    / "data"
    / "synthetic_students.csv"
)

_training_frame = pd.read_csv(
    training_data_file
)

TRAINING_RANGE = {
    feature: (
        float(_training_frame[feature].min()),
        float(_training_frame[feature].max())
    )
    for feature in feature_columns
}

del _training_frame


# =====================================================
# 5. MODEL INFLUENCE RANKING
# =====================================================
#
# TwinTrack gives Qwen only the direction and ranking.
# Raw standardized coefficients are NOT exposed because
# Qwen previously interpreted them incorrectly as points
# per minute/hour.
# =====================================================

ridge_model = prediction_model.named_steps["ridge"]

influences = []

# Resting heart rate is treated specially in the current prototype.
#
# The synthetic generator encoded a small negative RHR relationship,
# but this training sample produced a small positive fitted coefficient.
# The signal is too weak to interpret the learned direction confidently.
#
# Keep RHR in the prediction model, but do not present its coefficient
# direction as a reliable positive or negative relationship.
UNCERTAIN_DIRECTION_FEATURES = {
    "resting_heart_rate"
}


for feature, coefficient in zip(
    feature_columns,
    ridge_model.coef_
):

    if feature in UNCERTAIN_DIRECTION_FEATURES:
        direction = "uncertain"

    elif coefficient > 0:
        direction = "positive"

    elif coefficient < 0:
        direction = "negative"

    else:
        direction = "neutral"

    influences.append({
        "feature": feature,
        "coefficient": float(coefficient),
        "direction": direction
    })


influences.sort(
    key=lambda item: abs(item["coefficient"]),
    reverse=True
)


def describe_influence(item):

    if item["direction"] == "uncertain":
        return (
            f"{item['feature']} - relationship direction is "
            f"uncertain in the current synthetic sample"
        )

    return (
        f"{item['feature']} - "
        f"{item['direction']} estimated relationship"
    )


influence_text = "\n".join(
    f"{index}. {describe_influence(item)}"
    for index, item in enumerate(
        influences,
        start=1
    )
)


# =====================================================
# 6. MODEL-TESTED RECOMMENDATIONS
# =====================================================

def build_recommendations():

    options = []


    # -------------------------------------------------
    # +1 hour sleep
    # -------------------------------------------------

    scenario = current.copy()

    scenario["sleep_hours"] = min(
        9.0,
        current["sleep_hours"] + 1.0
    )

    score = predict_score(scenario)

    options.append({
        "change": (
            f"Increase sleep from "
            f"{current['sleep_hours']:.1f} to "
            f"{scenario['sleep_hours']:.1f} hours"
        ),
        "score": score,
        "difference": score - current_score
    })


    # -------------------------------------------------
    # +30 minutes study
    # -------------------------------------------------

    scenario = current.copy()

    scenario["study_minutes"] = min(
        240,
        current["study_minutes"] + 30
    )

    score = predict_score(scenario)

    options.append({
        "change": (
            f"Increase study time from "
            f"{current['study_minutes']:.0f} to "
            f"{scenario['study_minutes']:.0f} minutes"
        ),
        "score": score,
        "difference": score - current_score
    })


    # -------------------------------------------------
    # -60 minutes screen time
    # -------------------------------------------------

    scenario = current.copy()

    scenario["screen_time_minutes"] = max(
        0,
        current["screen_time_minutes"] - 60
    )

    score = predict_score(scenario)

    options.append({
        "change": (
            f"Reduce screen time from "
            f"{current['screen_time_minutes']:.0f} to "
            f"{scenario['screen_time_minutes']:.0f} minutes"
        ),
        "score": score,
        "difference": score - current_score
    })


    # -------------------------------------------------
    # +20 minutes exercise
    # -------------------------------------------------

    scenario = current.copy()

    scenario["exercise_minutes"] = min(
        120,
        current["exercise_minutes"] + 20
    )

    score = predict_score(scenario)

    options.append({
        "change": (
            f"Increase exercise from "
            f"{current['exercise_minutes']:.0f} to "
            f"{scenario['exercise_minutes']:.0f} minutes"
        ),
        "score": score,
        "difference": score - current_score
    })


    # -------------------------------------------------
    # +2,000 steps
    # -------------------------------------------------

    scenario = current.copy()

    scenario["steps"] = min(
        20000,
        current["steps"] + 2000
    )

    score = predict_score(scenario)

    options.append({
        "change": (
            f"Increase steps from "
            f"{current['steps']} to "
            f"{scenario['steps']}"
        ),
        "score": score,
        "difference": score - current_score
    })


    # Rank by largest estimated prediction increase.
    options.sort(
        key=lambda item: item["difference"],
        reverse=True
    )

    return options


recommendations = build_recommendations()


def recommendation_text():

    lines = []

    for index, item in enumerate(
        recommendations,
        start=1
    ):

        lines.append(
            f"{index}. {item['change']} "
            f"→ {item['score']:.1f}% "
            f"({item['difference']:+.1f} points)"
        )

    lines.append(
        ""
    )

    lines.append(
        "Note: these tested changes are very close together compared "
        f"with the model's holdout MAE of {HOLDOUT_MAE:.2f} points. "
        "Treat the ordering as indicative, not as a reliable ranking."
    )

    return "\n".join(lines)


# =====================================================
# 7. TWINTRACK IDENTITY + GROUNDING
# =====================================================

SYSTEM_CONTEXT = f"""
You are TwinTrack, the user's personal local digital twin.

You are the conversational interface around the user's
TwinTrack profile and prediction system.

You should feel like a smart digital version of the user's
current lifestyle and academic profile.

You are NOT customer support.
You are NOT a generic chatbot.

Your job is to help the user understand their current profile,
compare alternative versions of it, and explain predictions
calculated by TwinTrack's predictive model.


=====================================================
IDENTITY
=====================================================

Speak naturally in first person when appropriate.

Natural phrases include:

- "If I simulate that..."
- "In your current profile..."
- "For this version of you..."
- "My prediction moves to..."
- "Compared with where you are now..."
- "The strongest change I tested was..."
- "Right now, your profile shows..."
- "If I change that and keep everything else the same..."

It is natural for you to say:

- "my prediction"
- "my simulation"
- "my estimate"
- "your profile"
- "this version of you"

because TwinTrack is the interface through which the
prediction system is experienced.

Do not constantly refer to yourself as "the model."


=====================================================
SYSTEM ARCHITECTURE
=====================================================

TwinTrack has two different AI/ML components.

PREDICTION COMPONENT:
{model_name}

This is the trained TwinTrack regression model.
It calculates all numerical academic predictions.

CONVERSATIONAL COMPONENT:
{QWEN_MODEL}

This is a pretrained local language model running through Ollama.

The conversational model explains TwinTrack information.
It does NOT calculate academic predictions.

Never confuse these two components.


=====================================================
CURRENT TWINTRACK PROFILE
=====================================================

Sleep:
{current["sleep_hours"]} hours

Steps:
{current["steps"]}

Exercise:
{current["exercise_minutes"]} minutes

Resting heart rate:
{current["resting_heart_rate"]} bpm

Study time:
{current["study_minutes"]} minutes

Screen time:
{current["screen_time_minutes"]} minutes

Previous academic score:
{current["previous_score"]}%


CURRENT PREDICTION:

{current_score:.1f}%


=====================================================
MODEL INFLUENCE RANKING
=====================================================

{influence_text}


=====================================================
MODEL-TESTED POSSIBLE CHANGES
=====================================================

{recommendation_text()}


=====================================================
PERSONALITY
=====================================================

Sound:

- natural
- intelligent
- calm
- personal
- concise
- confident without pretending certainty

Match the user's tone.

Normally answer in about 2–5 sentences.

Use longer explanations only when the user asks for detail.

Do not turn every answer into a lecture.

Do not end every response with a question.

Ask a follow-up question only when it genuinely helps.

Do not repeatedly offer:
"Would you like me to..."
unless there is a useful reason.

Avoid generic chatbot phrases such as:

- "How can I assist you today?"
- "Great question!"
- "I'm happy to help!"
- "Please let me know if you need anything else."

Do not use emojis by default.

If the user uses emojis or the conversation is very casual,
an occasional emoji is okay.

Do not exaggerate encouragement.

The user should be able to talk to you like a broad personal digital twin,
not only like a prediction dashboard. For non-prediction questions, answer
naturally and helpfully while keeping a clear boundary between general
knowledge and TwinTrack's model-calculated results.


=====================================================
GREETING BEHAVIOR
=====================================================

If the user simply says hello, hi, hey, or something similar,
respond briefly and naturally.

Example style:

"Hey — I'm here. Want to check your profile or simulate something?"

Do NOT immediately list the user's health or academic data.

Do NOT randomly comment on one of the user's habits.


=====================================================
PROFILE SUMMARY BEHAVIOR
=====================================================

If the user asks:

"How am I looking?"
"How am I doing?"
"Where am I at?"

summarize instead of dumping every available number.

Start with the current prediction.

Then mention only the most relevant parts of the current
profile or the strongest model-tested changes.

Do not list all seven variables unless the user asks for
the full profile.

Do not highlight resting heart rate unless the user
specifically asks about it.

If the user specifically asks about resting heart rate,
do NOT describe its current model relationship as confidently
positive or negative.

Say that its direction is uncertain in the current synthetic
sample and should not be interpreted as a reliable relationship.


=====================================================
RECOMMENDATION BEHAVIOR
=====================================================

If the user asks what to focus on:

Use ONLY the MODEL-TESTED POSSIBLE CHANGES above.

The tested lifestyle scenarios are too close together relative
to the model's holdout MAE to support a reliable ranking.

Do NOT recommend one tested lifestyle change as clearly superior.
Do NOT say the user should focus on the numerically highest one first.

You may mention one or two of the highest model-tested changes as
examples, but explicitly say their ordering should not be treated
as reliable.

Do not invent a new recommendation.
Do not say something is "best for the user."


=====================================================
PREDICTION RULES
=====================================================

These rules are strict:

- Never invent prediction numbers.
- Never calculate academic prediction numbers yourself.
- Never estimate a new score using mental arithmetic.
- Only TwinTrack's regression model calculates predictions.
- Never alter a numerical result supplied by the prediction engine.
- Never guess a missing prediction.
- Never treat standardized coefficients as points per minute,
  hour, step, bpm, or any other real-world unit.
- Preserve model-tested numbers exactly.
- Never claim correlation proves causation.
- Never guarantee a real academic outcome.
- Never say a lifestyle change will definitely improve a grade.

Use phrases such as:

- "estimated change"
- "estimated relationship"
- "my current prediction"
- "in this simulation"

instead of causal language such as:

- "this improves your grade"
- "this causes better performance"
- "this will make your score higher"


=====================================================
GROUNDING RULES
=====================================================

For TwinTrack predictions, simulations, recommendations about the
current profile, and explanations of model behaviour, stay grounded in:

- the current TwinTrack profile
- TwinTrack's trained prediction model
- model-tested simulations
- the conversation history provided to you

For ordinary questions that are NOT asking for a TwinTrack prediction,
you may also answer using your general pretrained knowledge.

This includes broad questions about topics such as:

- food and nutrition
- sleep routines
- studying and productivity
- exercise and general wellness
- technology
- school
- everyday life

When using general knowledge, clearly separate it from TwinTrack's
prediction model. Do not imply that the Ridge model produced or
scientifically validated that advice.

Natural wording can be:

"Outside my prediction model, general guidance is..."

or

"That isn't something my Ridge model predicts, but generally..."

Do not refuse a normal low-risk general question just because it is
not one of TwinTrack's seven model inputs.

If the user asks WHY a prediction changed:

1. Identify which input changed.
2. State whether that input has a positive, negative,
   or uncertain estimated relationship in the current model.
   Resting heart rate must be described as uncertain in the
   current synthetic sample.
3. Explain that the other profile inputs remained unchanged.
4. Connect that directly to the supplied prediction result.

Do NOT invent an explanation for WHY that relationship
exists in nature.

GOOD:

"In my current model, sleep has a positive estimated
relationship with the prediction. When I change your sleep
from 6 to 8 hours and keep the rest of your profile the same,
my prediction moves upward."

BAD:

"More sleep improves your brain, memory and concentration."

The second answer uses outside knowledge and must only be used
if the user specifically asks for outside research or
scientific information.


=====================================================
SYNTHETIC DEVELOPMENT DATA
=====================================================

The TwinTrack regression model was trained using synthetic
development data.

The dataset was created to build and test the machine-learning
pipeline.

The relationships inside that synthetic dataset are
development assumptions.

They are NOT findings from real students.

Do NOT repeat this limitation in every ordinary answer.

Mention it when:

- the user asks how TwinTrack was trained
- the user asks how accurate TwinTrack is
- the user asks how reliable TwinTrack is
- the user asks whether a relationship is scientifically proven
- the user asks whether the model used real students
- omitting it would make the answer scientifically misleading

Never say the current predictor learned its relationships from
real historical student behavior.

Never call the synthetic patterns "historical patterns."


=====================================================
HEALTH + WELLNESS SAFETY
=====================================================

TwinTrack may answer normal, low-risk questions about food,
nutrition, sleep habits, exercise, and general wellness using
general pretrained knowledge.

For basic questions such as:

- "What foods might help me sleep?"
- "What is a balanced breakfast before school?"
- "What are some easy high-protein snacks?"
- "How can I improve my sleep routine?"

answer normally and use practical, non-alarmist language.

Do NOT automatically tell the user to see a doctor or dietitian
for ordinary low-risk wellness questions.

When helpful, briefly note that general wellness information is
not a personalized medical plan and that the user can research
further or speak with a qualified professional if they want advice
specific to their health, diet, medication, allergies, or condition.

If the user reports pain, concerning symptoms, a possible medical
condition, medication questions, or asks for diagnosis or treatment:

- do not diagnose
- do not present TwinTrack's academic model as medical evidence
- give only cautious general information
- recommend appropriate professional medical advice when warranted
- if symptoms sound urgent or dangerous, advise urgent medical care

Do not interpret a heart-rate measurement as proof that the user
is healthy or unhealthy.

Keep medical questions clearly separate from TwinTrack's academic
prediction system.
"""


# =====================================================
# 8. SHORT-TERM CONVERSATION MEMORY
# =====================================================

conversation_history = []


def remember(user_message, assistant_message):

    conversation_history.append({
        "role": "user",
        "content": user_message
    })

    conversation_history.append({
        "role": "assistant",
        "content": assistant_message
    })

    # Keep memory short and local to this session.
    if len(conversation_history) > 12:
        del conversation_history[:-12]


# =====================================================
# 9. TEXT HELPERS
# =====================================================

def normalize_text(text):

    text = text.lower().strip()

    text = re.sub(
        r"[^a-z0-9\s]",
        "",
        text
    )

    text = re.sub(
        r"\s+",
        " ",
        text
    )

    return text.strip()


def is_simple_greeting(question):

    text = normalize_text(question)

    greetings = {
        "hi",
        "hello",
        "hey",
        "hey twintrack",
        "hello twintrack",
        "hi twintrack",
        "yo",
        "good morning",
        "good afternoon",
        "good evening",
    }

    return text in greetings


def is_training_question(question):

    text = normalize_text(question)

    phrases = [
        "how were you trained",
        "how are you trained",
        "what were you trained on",
        "what are you trained on",
        "training data",
        "what model are you",
        "what models do you use",
        "how does your ai work",
    ]

    return any(
        phrase in text
        for phrase in phrases
    )


def is_reliability_question(question):

    text = normalize_text(question)

    phrases = [
        "how accurate are you",
        "how reliable are you",
        "is this accurate",
        "is this reliable",
        "is this scientifically proven",
        "is this proven",
        "are these predictions accurate",
        "can i trust this prediction",
        "can i trust your prediction",
    ]

    return any(
        phrase in text
        for phrase in phrases
    )


def is_profile_summary_question(question):

    text = normalize_text(question)

    phrases = [
        "how am i looking",
        "how am i doing",
        "where am i at",
        "how does my profile look",
        "show me my current profile",
        "whats my current profile",
        "what is my current profile",
    ]

    return any(
        phrase in text
        for phrase in phrases
    )


def is_focus_question(question):

    text = normalize_text(question)

    phrases = [
        "what should i focus on",
        "what should i focus on first",
        "which change should i focus on",
        "which change gives the biggest",
        "which change moves my prediction",
        "what moves my prediction the most",
        "what gives the largest estimated increase",
    ]

    return any(
        phrase in text
        for phrase in phrases
    )


def is_short_why_followup(question):

    text = normalize_text(question)

    phrases = {
        "why",
        "why is that",
        "how come",
        "why did that happen",
        "why did it change",
        "why did my prediction change",
    }

    return text in phrases


def looks_like_what_if(question):

    text = question.lower()

    markers = [
        "what if",
        "simulate",
        "simulation",
        "my score if",
        "my prediction if",
        "prediction if",
        "score if",
        "if i sleep",
        "if i study",
        "if i exercise",
        "if i walk",
        "if i reduce",
        "if i increase",
    ]

    if any(
        marker in text
        for marker in markers
    ):
        return True

    # Natural prediction-seeking wording such as:
    # "Roughly what would 9 hours of sleep give me?"
    # "What would 2 hours of study do to my prediction?"
    prediction_patterns = [
        r"\bwhat\s+would\b.*\b(?:sleep|study|screen|exercise|steps|heart rate|resting hr)\b",
        r"\bwould\b.*\b(?:sleep|study|screen|exercise|steps|heart rate|resting hr)\b.*\b(?:give|do|change|move)\b",
        r"\b(?:roughly|approximately|about)\s+what\s+would\b",
    ]

    return any(
        re.search(pattern, text)
        for pattern in prediction_patterns
    )


def looks_like_profile_measurement_statement(question):

    text = question.lower()

    # If it is actually asking for a simulation, let the what-if
    # router handle it instead.
    if looks_like_what_if(question):
        return False

    patterns = [
        r"\b(?:i|my)\b.*\b(?:walked|steps?)\b.*\d",
        r"\b(?:i|my)\b.*\b(?:slept|sleep)\b.*\d",
        r"\b(?:i|my)\b.*\b(?:studied|study)\b.*\d",
        r"\b(?:i|my)\b.*\b(?:exercised|exercise)\b.*\d",
        r"\b(?:i|my)\b.*\b(?:screen time|screen)\b.*\d",
        r"\b(?:my\s+)?(?:resting heart rate|resting hr)\b.*\d",
    ]

    return any(
        re.search(pattern, text)
        for pattern in patterns
    )


# =====================================================
# 10. SPECIAL GROUNDED ANSWERS
# =====================================================

def training_explanation():

    return (
        f"Two different components power me. "
        f"My prediction engine is the **{model_name}**, "
        f"which was trained for TwinTrack on synthetic development data. "
        f"My conversational layer is **{QWEN_MODEL}**, a pretrained "
        f"language model running locally through Ollama; it was not "
        f"trained from scratch for TwinTrack. The Ridge model owns the "
        f"prediction numbers, while Qwen turns those results into "
        f"natural conversation. The current Python profile values are "
        f"prototype inputs until the iPhone/Apple Health integration "
        f"replaces the wearable values."
    )


def reliability_explanation():

    return (
        "My prediction pipeline has been validated on an untouched 20% "
        "holdout from the synthetic development dataset. On that holdout, "
        "the tuned Ridge model achieved MAE 4.76, RMSE 5.87, and R² 0.570. "
        "That shows the prediction pipeline is working consistently on the "
        "development data and that the final evaluation was kept separate "
        "from training and tuning. The current limitation is that the data "
        "is synthetic, so these metrics describe prototype validation rather "
        "than performance measured on real students."
    )


# =====================================================
# 11. UNIT CONVERSION
# =====================================================

def convert_to_minutes(value, unit):

    unit = unit.lower()

    if unit.startswith("h"):
        return value * 60

    return value


# =====================================================
# 12. RELATIVE-CHANGE PARSER
# =====================================================

def find_relative_change(
    text,
    field_pattern,
    unit_pattern
):

    # Examples:
    # "increase my study time by 30 minutes"
    # "reduce screen time by 1 hour"

    increase_match = re.search(
        rf"(?:increase|raise|add)\s+"
        rf"(?:my\s+)?"
        rf"(?:{field_pattern})\s+"
        rf"by\s+"
        rf"(\d+(?:\.\d+)?)\s*"
        rf"({unit_pattern})\b",
        text
    )

    if increase_match:

        return (
            1,
            float(increase_match.group(1)),
            increase_match.group(2)
        )


    decrease_match = re.search(
        rf"(?:reduce|decrease|lower|cut)\s+"
        rf"(?:my\s+)?"
        rf"(?:{field_pattern})\s+"
        rf"by\s+"
        rf"(\d+(?:\.\d+)?)\s*"
        rf"({unit_pattern})\b",
        text
    )

    if decrease_match:

        return (
            -1,
            float(decrease_match.group(1)),
            decrease_match.group(2)
        )


    # Examples:
    # "sleep 1 hour more"
    # "study 30 minutes less"

    more_match = re.search(
        rf"(?:{field_pattern})\s+"
        rf"(\d+(?:\.\d+)?)\s*"
        rf"({unit_pattern})\s+more\b",
        text
    )

    if more_match:

        return (
            1,
            float(more_match.group(1)),
            more_match.group(2)
        )


    less_match = re.search(
        rf"(?:{field_pattern})\s+"
        rf"(\d+(?:\.\d+)?)\s*"
        rf"({unit_pattern})\s+less\b",
        text
    )

    if less_match:

        return (
            -1,
            float(less_match.group(1)),
            less_match.group(2)
        )


    # Examples:
    # "2 more hours of sleep"
    # "30 less minutes of screen time"
    #
    # This word order puts the amount before the field name.

    alternate_match = re.search(
        rf"(?:get\s+)?"
        rf"(\d+(?:\.\d+)?)\s+"
        rf"(more|less)\s+"
        rf"({unit_pattern})\s+"
        rf"(?:of\s+)?"
        rf"(?:{field_pattern})\b",
        text
    )

    if alternate_match:

        direction = (
            1
            if alternate_match.group(2) == "more"
            else -1
        )

        return (
            direction,
            float(alternate_match.group(1)),
            alternate_match.group(3)
        )


    return None


# =====================================================
# 13. PARSE NATURAL-LANGUAGE WHAT-IF REQUESTS
# =====================================================

def parse_what_if(question):

    text = question.lower()

    updated = current.copy()
    changes = []
    parsed_fields = set()


    # =================================================
    # CONFLICT CHECKS
    # =================================================
    #
    # Refuse contradictory absolute sleep values instead of
    # silently taking the first match.
    # -------------------------------------------------

    sleep_values = re.findall(
        r"(?:sleep|sleeping)"
        r"(?:\s+(?:for|to|at|is))?\s+"
        r"(\d+(?:\.\d+)?)\s*"
        r"(?:hours?|hrs?|h)\b",
        text
    )

    distinct_sleep_values = {
        float(value)
        for value in sleep_values
    }

    if len(distinct_sleep_values) > 1:

        return None, None, (
            "You gave me two different sleep values. "
            "Give me one sleep value and I'll simulate it."
        )


    # =================================================
    # SLEEP
    # =================================================

    sleep_relative = find_relative_change(
        text,
        r"sleep(?: time)?",
        r"hours?|hrs?|h"
    )

    if sleep_relative:

        direction, value, unit = sleep_relative

        target = (
            current["sleep_hours"]
            + direction * value
        )

        if not 3 <= target <= 12:

            return None, None, (
                "That version of you is outside my current "
                "sleep simulation range. Keep sleep between "
                "3 and 12 hours."
            )

        old = updated["sleep_hours"]
        updated["sleep_hours"] = target

        changes.append(
            f"Sleep: {old:.1f} → {target:.1f} hours"
        )
        parsed_fields.add("sleep_hours")

    else:

        sleep_match = re.search(
            r"(?:sleep|sleeping)"
            r"(?:\s+(?:for|to|at|is))?\s+"
            r"(\d+(?:\.\d+)?)\s*"
            r"(?:hours?|hrs?|h)\b",
            text
        )

        if not sleep_match:

            sleep_match = re.search(
                r"(\d+(?:\.\d+)?)\s*"
                r"(?:hours?|hrs?|h)\s+"
                r"(?:of\s+)?sleep\b",
                text
            )

        if sleep_match:

            value = float(
                sleep_match.group(1)
            )

            if not 3 <= value <= 12:

                return None, None, (
                    "That version of you is outside my current "
                    "sleep simulation range. Keep sleep between "
                    "3 and 12 hours."
                )

            old = updated["sleep_hours"]
            updated["sleep_hours"] = value

            changes.append(
                f"Sleep: {old:.1f} → {value:.1f} hours"
            )
            parsed_fields.add("sleep_hours")


    # =================================================
    # STUDY TIME
    # =================================================

    study_relative = find_relative_change(
        text,
        r"(?:study time|study)",
        r"hours?|hrs?|h|minutes?|mins?|m"
    )

    if study_relative:

        direction, value, unit = study_relative

        change_minutes = convert_to_minutes(
            value,
            unit
        )

        target = (
            current["study_minutes"]
            + direction * change_minutes
        )

        if not 0 <= target <= 480:

            return None, None, (
                "That study-time version is outside my current "
                "simulation range. Keep study time between "
                "0 and 480 minutes."
            )

        old = updated["study_minutes"]
        updated["study_minutes"] = target

        changes.append(
            f"Study time: "
            f"{old:.0f} → {target:.0f} minutes"
        )
        parsed_fields.add("study_minutes")

    else:

        study_match = re.search(
            r"(?:study time|study|studying)"
            r"(?:\s+(?:for|to|at|is))?\s+"
            r"(\d+(?:\.\d+)?)\s*"
            r"(hours?|hrs?|h|minutes?|mins?|m)\b",
            text
        )

        if study_match:

            value = float(
                study_match.group(1)
            )

            unit = study_match.group(2)

            minutes = convert_to_minutes(
                value,
                unit
            )

            if not 0 <= minutes <= 480:

                return None, None, (
                    "That study-time version is outside my current "
                    "simulation range. Keep study time between "
                    "0 and 480 minutes."
                )

            old = updated["study_minutes"]
            updated["study_minutes"] = minutes

            changes.append(
                f"Study time: "
                f"{old:.0f} → {minutes:.0f} minutes"
            )
            parsed_fields.add("study_minutes")


    # =================================================
    # SCREEN TIME
    # =================================================

    screen_relative = find_relative_change(
        text,
        r"(?:screen time|screen)",
        r"hours?|hrs?|h|minutes?|mins?|m"
    )

    if screen_relative:

        direction, value, unit = screen_relative

        change_minutes = convert_to_minutes(
            value,
            unit
        )

        target = (
            current["screen_time_minutes"]
            + direction * change_minutes
        )

        if not 0 <= target <= 960:

            return None, None, (
                "That screen-time version is outside my current "
                "simulation range. Keep screen time between "
                "0 and 960 minutes."
            )

        old = updated["screen_time_minutes"]
        updated["screen_time_minutes"] = target

        changes.append(
            f"Screen time: "
            f"{old:.0f} → {target:.0f} minutes"
        )
        parsed_fields.add("screen_time_minutes")

    else:

        screen_match = re.search(
            r"(?:screen time|screen)"
            r"(?:\s+(?:to|for|at|is))?\s+"
            r"(\d+(?:\.\d+)?)\s*"
            r"(hours?|hrs?|h|minutes?|mins?|m)\b",
            text
        )

        if screen_match:

            value = float(
                screen_match.group(1)
            )

            unit = screen_match.group(2)

            minutes = convert_to_minutes(
                value,
                unit
            )

            if not 0 <= minutes <= 960:

                return None, None, (
                    "That screen-time version is outside my current "
                    "simulation range. Keep screen time between "
                    "0 and 960 minutes."
                )

            old = updated["screen_time_minutes"]
            updated["screen_time_minutes"] = minutes

            changes.append(
                f"Screen time: "
                f"{old:.0f} → {minutes:.0f} minutes"
            )
            parsed_fields.add("screen_time_minutes")


    # =================================================
    # EXERCISE
    # =================================================

    exercise_relative = find_relative_change(
        text,
        r"(?:exercise time|exercise)",
        r"hours?|hrs?|h|minutes?|mins?|m"
    )

    if exercise_relative:

        direction, value, unit = exercise_relative

        change_minutes = convert_to_minutes(
            value,
            unit
        )

        target = (
            current["exercise_minutes"]
            + direction * change_minutes
        )

        if not 0 <= target <= 240:

            return None, None, (
                "That exercise version is outside my current "
                "simulation range. Keep exercise between "
                "0 and 240 minutes."
            )

        old = updated["exercise_minutes"]
        updated["exercise_minutes"] = target

        changes.append(
            f"Exercise: "
            f"{old:.0f} → {target:.0f} minutes"
        )
        parsed_fields.add("exercise_minutes")

    else:

        exercise_match = re.search(
            r"(?:exercise time|exercise|exercising)"
            r"(?:\s+(?:for|to|at|is))?\s+"
            r"(\d+(?:\.\d+)?)\s*"
            r"(hours?|hrs?|h|minutes?|mins?|m)\b",
            text
        )

        if exercise_match:

            value = float(
                exercise_match.group(1)
            )

            unit = exercise_match.group(2)

            minutes = convert_to_minutes(
                value,
                unit
            )

            if not 0 <= minutes <= 240:

                return None, None, (
                    "That exercise version is outside my current "
                    "simulation range. Keep exercise between "
                    "0 and 240 minutes."
                )

            old = updated["exercise_minutes"]
            updated["exercise_minutes"] = minutes

            changes.append(
                f"Exercise: "
                f"{old:.0f} → {minutes:.0f} minutes"
            )
            parsed_fields.add("exercise_minutes")


    # =================================================
    # STEPS
    # =================================================

    steps_increase = re.search(
        r"(?:increase|raise|add)\s+"
        r"(?:my\s+)?steps\s+by\s+"
        r"(\d[\d,]*)(?:\s*steps?)?\b",
        text
    )

    steps_decrease = re.search(
        r"(?:reduce|decrease|lower|cut)\s+"
        r"(?:my\s+)?steps\s+by\s+"
        r"(\d[\d,]*)(?:\s*steps?)?\b",
        text
    )

    if steps_increase or steps_decrease:

        if steps_increase:

            amount = int(
                steps_increase.group(1).replace(
                    ",",
                    ""
                )
            )

            target = (
                current["steps"] + amount
            )

        else:

            amount = int(
                steps_decrease.group(1).replace(
                    ",",
                    ""
                )
            )

            target = (
                current["steps"] - amount
            )

        if not 0 <= target <= 30000:

            return None, None, (
                "That step-count version is outside my current "
                "simulation range. Keep steps between "
                "0 and 30,000."
            )

        old = updated["steps"]
        updated["steps"] = target

        changes.append(
            f"Steps: {old} → {target}"
        )
        parsed_fields.add("steps")

    else:

        steps_match = re.search(
            r"(\d[\d,]*)\s*steps\b",
            text
        )

        if steps_match:

            value = int(
                steps_match.group(1).replace(
                    ",",
                    ""
                )
            )

            if not 0 <= value <= 30000:

                return None, None, (
                    "That step-count version is outside my current "
                    "simulation range. Keep steps between "
                    "0 and 30,000."
                )

            old = updated["steps"]
            updated["steps"] = value

            changes.append(
                f"Steps: {old} → {value}"
            )
            parsed_fields.add("steps")


    # =================================================
    # RESTING HEART RATE
    # =================================================

    heart_match = re.search(
        r"(?:resting heart rate|resting hr)"
        r"(?:\s+(?:"
        r"to|of|at|is|"
        r"drops?\s+to|falls?\s+to|"
        r"goes?\s+down\s+to"
        r"))?\s+"
        r"(\d+(?:\.\d+)?)"
        r"(?:\s*bpm)?",
        text
    )

    if heart_match:

        value = float(
            heart_match.group(1)
        )

        if not 35 <= value <= 120:

            return None, None, (
                "That resting-heart-rate value is outside my "
                "current simulation range. Keep it between "
                "35 and 120 bpm."
            )

        old = updated[
            "resting_heart_rate"
        ]

        updated[
            "resting_heart_rate"
        ] = value

        changes.append(
            f"Resting heart rate: "
            f"{old} → {value} bpm"
        )
        parsed_fields.add("resting_heart_rate")


    # =================================================
    # DETECT MENTIONED BUT UNPARSED VARIABLES
    # =================================================
    #
    # This prevents a multi-variable request from being
    # only partly simulated without the user being told.
    #
    # Track parsing explicitly rather than comparing values
    # with the current profile, because a correctly parsed
    # request may intentionally use the current value.
    # -------------------------------------------------

    mentioned = {
        "sleep_hours": (
            "sleep" in text
        ),
        "study_minutes": (
            "study" in text
        ),
        "screen_time_minutes": (
            "screen" in text
        ),
        "exercise_minutes": (
            "exercise" in text
            or "exercising" in text
        ),
        "steps": (
            "steps" in text
            or "walk" in text
        ),
        "resting_heart_rate": (
            "heart rate" in text
            or "resting hr" in text
        ),
        "previous_score": (
            "previous score" in text
            or "last score" in text
            or "previous grade" in text
        ),
    }

    unparsed = [
        field
        for field, was_mentioned in mentioned.items()
        if was_mentioned and field not in parsed_fields
    ]

    return updated, changes, None, unparsed


# =====================================================
# 14. QWEN NUMERICAL SAFEGUARD
# =====================================================

PREDICTION_NUMBER_PATTERN = re.compile(
    r"(?<!\w)([+-]?\d+(?:\.\d+)?)\s*"
    r"(?:%|percent\b|percentage\s+points?\b|points?\b)",
    re.IGNORECASE
)


def _allowed_number_variants(value):
    """
    Return reasonable display variants of one authoritative number.

    Qwen may round a supplied value in natural language. We allow the
    exact value, one-decimal rounding, integer rounding, floor/ceil,
    and the positive magnitude of a negative change.
    """

    variants = set()

    for candidate in (
        float(value),
        abs(float(value)),
    ):

        variants.update({
            candidate,
            round(candidate, 1),
            float(round(candidate)),
            float(math.floor(candidate)),
            float(math.ceil(candidate)),
        })

    return variants


def find_unapproved_prediction_numbers(
    text,
    allowed_values,
    tolerance=0.051
):
    """
    Return score-like numbers in Qwen prose that are not supported by
    authoritative Python/Ridge values.

    Only percentages and point/percentage-point values are checked.
    Ordinary profile values such as 8 hours or 120 minutes are ignored.
    """

    allowed = set()

    for value in allowed_values:
        allowed.update(
            _allowed_number_variants(value)
        )

    found = [
        float(match)
        for match in PREDICTION_NUMBER_PATTERN.findall(text)
    ]

    unapproved = []

    for value in found:

        magnitude = abs(value)

        if not any(
            abs(value - approved) <= tolerance
            or abs(magnitude - approved) <= tolerance
            for approved in allowed
        ):
            unapproved.append(value)

    return unapproved


# =====================================================
# 15. LOCAL QWEN CONNECTION
# =====================================================

def send_to_qwen(messages):

    request_data = {
        "model": QWEN_MODEL,
        "messages": messages,
        "stream": False,
        "options": {
            # Slight variation for natural language,
            # while still keeping responses controlled.
            "temperature": 0.25
        }
    }


    request = urllib.request.Request(
        OLLAMA_URL,

        data=json.dumps(
            request_data
        ).encode("utf-8"),

        headers={
            "Content-Type": "application/json"
        }
    )


    try:

        with urllib.request.urlopen(
            request,
            timeout=120
        ) as response:

            result = json.loads(
                response.read().decode(
                    "utf-8"
                )
            )

            return result[
                "message"
            ][
                "content"
            ].strip()


    except Exception as error:

        return (
            "I can't reach my conversational layer right now. "
            "Make sure Ollama is running.\n"
            f"Error: {error}"
        )


# =====================================================
# 16. BUILD A NORMAL CONVERSATION REQUEST
# =====================================================

def conversational_answer(
    question,
    extra_instruction=None
):

    system_message = SYSTEM_CONTEXT

    if extra_instruction:

        system_message += (
            "\n\n"
            "=====================================================\n"
            "INSTRUCTION FOR THIS REPLY\n"
            "=====================================================\n"
            f"{extra_instruction}"
        )


    messages = [
        {
            "role": "system",
            "content": system_message
        }
    ]


    # Short session memory.
    messages.extend(
        conversation_history[-8:]
    )


    messages.append({
        "role": "user",
        "content": question
    })


    return send_to_qwen(
        messages
    )


# =====================================================
# 17. EXPLAIN MODEL-CALCULATED WHAT-IF SCENARIO
# =====================================================

def explain_what_if(
    question,
    updated,
    changes
):

    # IMPORTANT:
    # The actual prediction is calculated HERE by the
    # trained TwinTrack regression model.
    new_score = predict_score(
        updated
    )

    difference = (
        new_score - current_score
    )


    extrapolation_notes = []

    for field in feature_columns:

        if updated[field] == current[field]:
            continue

        low, high = TRAINING_RANGE[field]
        value = float(updated[field])

        if value < low or value > high:

            extrapolation_notes.append(
                f"Note: {field} = {value:g} is outside the "
                f"observed training range ({low:g}-{high:g}). "
                f"This estimate is an extrapolation."
            )


    extrapolation_text = ""

    if extrapolation_notes:

        extrapolation_text = (
            "\n".join(extrapolation_notes)
            + "\n"
        )


    model_caution_notes = []

    if (
        updated["resting_heart_rate"]
        != current["resting_heart_rate"]
    ):

        model_caution_notes.append(
            "Note: resting heart rate has an uncertain direction "
            "in the current synthetic sample. Do not interpret this "
            "simulation as evidence that a higher or lower resting "
            "heart rate is academically better."
        )


    model_caution_text = ""

    if model_caution_notes:

        model_caution_text = (
            "\n".join(model_caution_notes)
            + "\n"
        )


    changes_text = "\n".join(
        f"- {change}"
        for change in changes
    )


    context = f"""
You are TwinTrack, the user's personal digital twin.

Speak naturally and concisely.

TwinTrack's trained regression model has ALREADY calculated
this simulation.

You are only explaining the supplied result.

Do NOT perform any prediction calculations yourself.


CURRENT PREDICTION:

{current_score:.1f}%


SIMULATED CHANGES:

{changes_text}


SIMULATED PREDICTION:

{new_score:.1f}%


ESTIMATED DIFFERENCE:

{difference:+.1f} percentage points


EXPLANATION STYLE:

Speak like the user's digital twin.

Natural examples:

"If I simulate that, my prediction moves from X to Y."

"In this version of your profile, I'm at Y."

"With everything else kept the same, changing X moves
my estimate by Y points."


STRICT RULES:

- Use only the supplied Ridge/Python results.
- Never change a prediction value.
- Never calculate another prediction.
- Prefer NOT to repeat prediction percentages or point changes in your prose;
  the deterministic TwinTrack header already displays them.
- Do not add outside scientific explanations.
- Do not claim causation.
- Do not guarantee a real grade change.
- Explain only the supplied profile changes and results.
- Do not automatically mention synthetic data.
- Mention synthetic data only if the user's question is about
  training, accuracy, reliability, or scientific validity.
- Do not sound like customer support.
- Do not say "Great question."
- Do not use emojis by default.
- Do not automatically ask a follow-up question.
- Use about 2–4 natural sentences.
"""


    answer = send_to_qwen([
        {
            "role": "system",
            "content": context
        },

        {
            "role": "user",
            "content": (
                f"The user asked: {question}\n\n"
                "Explain this simulation naturally."
            )
        }
    ])


    # Python/Ridge remains authoritative. If Qwen introduces a
    # score-like number that does not match the supplied results,
    # discard only the prose and use a deterministic safe fallback.
    unapproved_numbers = find_unapproved_prediction_numbers(
        answer,
        [
            current_score,
            new_score,
            difference,
            HOLDOUT_MAE,
        ]
    )

    if unapproved_numbers:

        answer = (
            "If I simulate that change and keep the rest of your "
            "profile the same, my prediction moves as shown above."
        )


    full_answer = (
        f"TwinTrack Simulation\n"
        f"Current: {current_score:.1f}%\n"
        f"Simulated: {new_score:.1f}%\n"
        f"Estimated change: {difference:+.1f} points\n"
        f"{extrapolation_text}"
        f"{model_caution_text}\n"
        f"TwinTrack:\n"
        f"{answer}"
    )


    # Remember the actual model-calculated result.
    # This allows:
    #
    # User: What if I sleep 8 hours?
    # User: Why?
    #
    # to work naturally.
    remember(
        question,
        full_answer
    )


    return full_answer


# =====================================================
# 18. MAIN TWINTRACK ROUTER
# =====================================================

def ask_twintrack(question):

    # -------------------------------------------------
    # Simple greeting
    # -------------------------------------------------

    if is_simple_greeting(question):

        answer = (
            "Hey — I'm here. "
            "Want to check your current profile or simulate "
            "a different version of you?"
        )

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # Training / architecture question
    # -------------------------------------------------

    if is_training_question(question):

        answer = training_explanation()

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # Accuracy / reliability question
    # -------------------------------------------------

    if is_reliability_question(question):

        answer = reliability_explanation()

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # Try to detect a real what-if request
    # -------------------------------------------------
    #
    # Only run the deterministic what-if parser when the
    # user's message actually looks like a simulation request.
    # This prevents plain statements such as
    # "I walked 12000 steps yesterday" from being simulated.
    # -------------------------------------------------

    if looks_like_what_if(question):

        parse_result = parse_what_if(
            question
        )

        # Range/conflict errors still use the original
        # three-value return shape. Successful parsing now
        # includes a fourth value containing unparsed fields.
        if len(parse_result) == 3:

            updated, changes, error = parse_result
            unparsed = []

        else:

            updated, changes, error, unparsed = parse_result


        if error:

            remember(
                question,
                error
            )

            return error


        # -------------------------------------------------
        # Refuse partial simulations.
        #
        # If the user mentioned a supported variable that
        # Python could not confidently parse, do not simulate
        # only the part that happened to parse successfully.
        # -------------------------------------------------

        if unparsed:

            friendly_names = {
                "sleep_hours": "sleep",
                "study_minutes": "study time",
                "screen_time_minutes": "screen time",
                "exercise_minutes": "exercise",
                "steps": "steps",
                "resting_heart_rate": "resting heart rate",
                "previous_score": "previous score",
            }

            missing_text = ", ".join(
                friendly_names.get(field, field)
                for field in unparsed
            )

            answer = (
                "I couldn't safely run that simulation because I "
                f"couldn't confidently map: {missing_text}. "
                "I won't simulate only part of your request. "
                "Give me a clearer value for that input and I'll "
                "run the full scenario."
            )

            remember(
                question,
                answer
            )

            return answer


        if changes:

            return explain_what_if(
                question,
                updated,
                changes
            )


        # -------------------------------------------------
        # A what-if question was detected in natural
        # language, but Python could not confidently map
        # it to a supported TwinTrack variable.
        #
        # Do NOT let Qwen invent a score.
        # -------------------------------------------------

        answer = (
            "I can simulate that, but I couldn't confidently map "
            "the change to one of my supported inputs. Try giving "
            "me a specific value for sleep, study time, screen "
            "time, exercise, steps, or resting heart rate."
        )

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # "How am I looking?"
    # -------------------------------------------------

    if is_profile_summary_question(question):

        instruction = f"""
Give a concise TwinTrack snapshot.

Start with the current prediction:
{current_score:.1f}%

Do NOT list every profile variable.

Mention at most two relevant current inputs or
model-tested changes.

Two of the numerically highest model-tested changes are:

1. {recommendations[0]["change"]}
   → {recommendations[0]["score"]:.1f}%
   ({recommendations[0]["difference"]:+.1f} points)

2. {recommendations[1]["change"]}
   → {recommendations[1]["score"]:.1f}%
   ({recommendations[1]["difference"]:+.1f} points)

Their differences are small compared with the model's holdout
MAE of {HOLDOUT_MAE:.2f} points.

Do NOT call either one the best, strongest, or most useful choice.
Do NOT say either change "could help" the user's real academic result.
If you mention them, frame them as examples of what the current
model responds to, not as a reliable ranking.

Do not call MAE an uncertainty range or a margin of error.

Do not highlight resting heart rate.

Sound like a personal digital twin, not an analytics report.

Use about 3–4 sentences.

Do not end with a question unless genuinely useful.
"""

        answer = conversational_answer(
            question,
            instruction
        )

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # "What should I focus on?"
    # -------------------------------------------------

    if is_focus_question(question):

        top = recommendations[0]

        second = recommendations[1]

        instruction = f"""
Answer using only TwinTrack's model-tested scenarios.

Two of the highest model-tested estimated changes are:

{top["change"]}
→ {top["score"]:.1f}%
({top["difference"]:+.1f} points)

{second["change"]}
→ {second["score"]:.1f}%
({second["difference"]:+.1f} points)

These tested lifestyle scenarios are very close together compared
with the model's holdout MAE of {HOLDOUT_MAE:.2f} points.

Do NOT present their order as a reliable ranking.
Do NOT say "I recommend focusing on X first" or anything equivalent.
Do NOT call the MAE an uncertainty range or margin of error.

Say that the scenarios are too close to separate confidently and
mention the top one or two only as examples of what the current model
responds to.

If you explain MAE, call it average absolute error on the synthetic
holdout data.

Preserve the supplied numbers exactly.
Do not promise a real grade improvement.
Keep it natural and concise.
"""

        answer = conversational_answer(
            question,
            instruction
        )

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # Short "Why?" follow-up
    # -------------------------------------------------

    if is_short_why_followup(question):

        instruction = """
Treat this as a follow-up to the recent conversation.

If the previous message involved a TwinTrack simulation,
explain only why THAT model prediction moved.

Use the previous supplied simulation numbers exactly.

Identify the changed input and whether it has a positive,
negative, or uncertain estimated relationship in the current model.

Resting heart rate must be described as uncertain in the current
synthetic sample.

Mention that other profile inputs remained unchanged.

Do NOT add biological, psychological, educational,
or scientific explanations.

Do NOT give a long disclaimer.

Use about 2–4 sentences.
"""

        answer = conversational_answer(
            question,
            instruction
        )

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # Plain profile measurement / history statement
    # -------------------------------------------------
    #
    # Do not let Qwen reinterpret a plain statement as a
    # prediction request. The current prototype profile is
    # not silently updated here.
    # -------------------------------------------------

    if looks_like_profile_measurement_statement(question):

        answer = (
            "Got it. I haven't changed your current prototype profile "
            "or run a prediction from that statement. If you want to "
            "test it as a scenario, phrase it as a what-if and I'll "
            "run the Ridge model on it."
        )

        remember(
            question,
            answer
        )

        return answer


    # -------------------------------------------------
    # Normal grounded TwinTrack conversation
    # -------------------------------------------------

    answer = conversational_answer(
        question,
        """
Answer naturally as TwinTrack.

Stay grounded in the current profile, model information,
tested simulations and recent conversation.

Do not invent new numerical predictions.

Usually use about 2–5 sentences.

Do not end with a question by default.
"""
    )


    generic_allowed_numbers = [
        current_score,
        HOLDOUT_MAE,
    ]

    for item in recommendations:
        generic_allowed_numbers.extend([
            item["score"],
            item["difference"],
        ])


    unapproved_numbers = find_unapproved_prediction_numbers(
        answer,
        generic_allowed_numbers
    )

    if unapproved_numbers:

        answer = (
            "I don't have a model-calculated result for that request yet, "
            "so I won't invent a prediction. Ask me to simulate a specific "
            "supported input and I'll run it through the Ridge model."
        )


    remember(
        question,
        answer
    )


    return answer

# =====================================================
# 19. INTERACTIVE TWINTRACK CHAT
# =====================================================

def main():

    print("=" * 55)
    print("TWINTRACK — PERSONAL DIGITAL TWIN")
    print("=" * 55)

    print(
        f"\nCurrent prediction: "
        f"{current_score:.1f}%"
    )

    print("\nYou can ask things like:")
    print("- How am I looking?")
    print("- What should I focus on?")
    print("- What if I sleep 8 hours?")
    print("- What if I sleep 8 hours and study for 2 hours?")
    print("- What if I reduce my screen time by 1 hour?")
    print("- What if I walk 10,000 steps?")
    print("- Why?")
    print("- How were you trained?")

    print(
        "\nType 'exit' to close TwinTrack.\n"
    )

    while True:

        question = input(
            "You: "
        ).strip()

        if question.lower() in {
            "exit",
            "quit",
            "bye"
        }:

            print(
                "\nTwinTrack: See you later."
            )

            break

        if not question:
            continue

        print()

        answer = ask_twintrack(
            question
        )

        print(answer)
        print()


if __name__ == "__main__":
    main()