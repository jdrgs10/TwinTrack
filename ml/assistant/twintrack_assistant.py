import json
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

for feature, coefficient in zip(
    feature_columns,
    ridge_model.coef_
):

    if coefficient > 0:
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


influence_text = "\n".join(
    f"{index}. {item['feature']} - "
    f"{item['direction']} estimated relationship"
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


=====================================================
RECOMMENDATION BEHAVIOR
=====================================================

If the user asks what to focus on:

Use ONLY the MODEL-TESTED POSSIBLE CHANGES above.

Rank them according to the calculated estimated differences.

Do not invent a new recommendation.

Do not say something is "best for the user."

Instead say something like:

"Of the changes I've tested, this gives the largest
estimated increase in my current prediction."


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

By default, explain only information supported by:

- the current TwinTrack profile
- TwinTrack's trained prediction model
- model-tested simulations
- the conversation history provided to you

Do NOT add outside scientific explanations unless the
user explicitly asks for scientific research,
general knowledge, or outside evidence.

If the user asks WHY a prediction changed:

1. Identify which input changed.
2. State whether that input has a positive or negative
   estimated relationship in the current model.
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
HEALTH SAFETY
=====================================================

TwinTrack may use lifestyle and wearable measurements
as prediction inputs.

Do not diagnose medical conditions.

Do not recommend medical treatment.

Do not interpret a heart-rate measurement as proof that
the user is healthy or unhealthy.

If a user asks a genuine medical question, separate that
question from TwinTrack's academic prediction system.
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

    return any(
        marker in text
        for marker in markers
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
        "Right now, treat my predictions as prototype estimates rather "
        "than proven real-world accuracy. My regression model was tested "
        "on held-out synthetic development data, but the relationships "
        "inside that dataset were created for development rather than "
        "learned from real students. Real-world validation would require "
        "actual observations collected over time and evaluated separately."
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


    return None


# =====================================================
# 13. PARSE NATURAL-LANGUAGE WHAT-IF REQUESTS
# =====================================================

def parse_what_if(question):

    text = question.lower()

    updated = current.copy()
    changes = []


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

    else:

        sleep_match = re.search(
            r"(?:sleep|sleeping)"
            r"(?:\s+(?:for|to|at|is))?\s+"
            r"(\d+(?:\.\d+)?)\s*"
            r"(?:hours?|hrs?|h)\b",
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


    # =================================================
    # STEPS
    # =================================================

    steps_increase = re.search(
        r"(?:increase|raise|add)\s+"
        r"(?:my\s+)?steps\s+by\s+"
        r"(\d[\d,]*)\s*steps?\b",
        text
    )

    steps_decrease = re.search(
        r"(?:reduce|decrease|lower|cut)\s+"
        r"(?:my\s+)?steps\s+by\s+"
        r"(\d[\d,]*)\s*steps?\b",
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


    # =================================================
    # RESTING HEART RATE
    # =================================================

    heart_match = re.search(
        r"(?:resting heart rate|resting hr)"
        r"(?:\s+(?:to|of|at|is))?\s+"
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


    return updated, changes, None


# =====================================================
# 14. LOCAL QWEN CONNECTION
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
# 15. BUILD A NORMAL CONVERSATION REQUEST
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
# 16. EXPLAIN MODEL-CALCULATED WHAT-IF SCENARIO
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


USER REQUEST:

{question}


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

- Use the supplied numbers exactly.
- Never change a prediction value.
- Never calculate another prediction.
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
                "Explain this simulation naturally."
            )
        }
    ])


    full_answer = (
        f"TwinTrack Simulation\n"
        f"Current: {current_score:.1f}%\n"
        f"Simulated: {new_score:.1f}%\n"
        f"Estimated change: {difference:+.1f} points\n\n"
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
# 17. MAIN TWINTRACK ROUTER
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

    updated, changes, error = parse_what_if(
        question
    )


    if error:

        remember(
            question,
            error
        )

        return error


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

    if looks_like_what_if(question):

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

The two highest-ranked tested changes are:

1. {recommendations[0]["change"]}
   → {recommendations[0]["score"]:.1f}%
   ({recommendations[0]["difference"]:+.1f} points)

2. {recommendations[1]["change"]}
   → {recommendations[1]["score"]:.1f}%
   ({recommendations[1]["difference"]:+.1f} points)

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

The largest estimated increase is:

{top["change"]}
→ {top["score"]:.1f}%
({top["difference"]:+.1f} points)

The second-largest estimated increase is:

{second["change"]}
→ {second["score"]:.1f}%
({second["difference"]:+.1f} points)

Preserve these numbers exactly.

Say "largest estimated increase" rather than claiming that
this is objectively the best habit.

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

Identify the changed input and whether it has a positive
or negative estimated relationship in the current model.

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


    remember(
        question,
        answer
    )


    return answer


# =====================================================
# 18. INTERACTIVE TWINTRACK CHAT
# =====================================================

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