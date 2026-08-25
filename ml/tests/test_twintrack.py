import importlib.util
from pathlib import Path

import pandas as pd
import pytest

from sklearn.metrics import (
    mean_absolute_error,
    mean_squared_error,
    r2_score,
)

from sklearn.model_selection import train_test_split


# =====================================================
# LOAD TWINTRACK ASSISTANT AS A MODULE
# =====================================================

ML_ROOT = Path(__file__).resolve().parents[1]

ASSISTANT_FILE = (
    ML_ROOT
    / "assistant"
    / "twintrack_assistant.py"
)

spec = importlib.util.spec_from_file_location(
    "twintrack_assistant",
    ASSISTANT_FILE
)

tt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tt)


# =====================================================
# HELPERS
# =====================================================

def parse_result(question):
    """
    Normalise parse_what_if's current mixed return shape:
    range/conflict errors may return 3 values, successful parsing
    returns 4 values including `unparsed`.
    """

    result = tt.parse_what_if(question)

    if len(result) == 3:
        updated, changes, error = result
        unparsed = []

    elif len(result) == 4:
        updated, changes, error, unparsed = result

    else:
        raise AssertionError(
            "Unexpected parse_what_if return format."
        )

    return updated, changes, error, unparsed


@pytest.fixture(autouse=True)
def reset_conversation():

    if hasattr(tt, "conversation_history"):
        tt.conversation_history.clear()

    yield

    if hasattr(tt, "conversation_history"):
        tt.conversation_history.clear()


@pytest.fixture
def mock_qwen(monkeypatch):

    monkeypatch.setattr(
        tt,
        "send_to_qwen",
        lambda messages: "MOCK QWEN RESPONSE"
    )


# =====================================================
# 1. EXISTING CORRECT PREDICTIONS
# =====================================================

def test_sleep_8_hours_prediction():

    updated, changes, error, unparsed = parse_result(
        "What if I sleep 8 hours?"
    )

    assert error is None
    assert not unparsed
    assert updated["sleep_hours"] == 8.0

    score = tt.predict_score(updated)

    assert score == pytest.approx(
        64.5,
        abs=0.08
    )


def test_sleep_8_and_study_2_hours_prediction():

    updated, changes, error, unparsed = parse_result(
        "What if I sleep 8 hours and study for 2 hours?"
    )

    assert error is None
    assert not unparsed
    assert updated["sleep_hours"] == 8.0
    assert updated["study_minutes"] == 120

    score = tt.predict_score(updated)

    assert score == pytest.approx(
        66.5,
        abs=0.08
    )


def test_reduce_screen_time_by_one_hour():

    updated, changes, error, unparsed = parse_result(
        "What if I reduce my screen time by 1 hour?"
    )

    assert error is None
    assert not unparsed
    assert updated["screen_time_minutes"] == 240


def test_walk_10000_steps():

    updated, changes, error, unparsed = parse_result(
        "What if I walk 10,000 steps?"
    )

    assert error is None
    assert not unparsed
    assert updated["steps"] == 10000


# =====================================================
# 2. PLAIN STATEMENTS SHOULD NOT SIMULATE
# =====================================================

def test_statement_about_steps_does_not_simulate(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "I walked 12000 steps yesterday"
    )

    assert "TwinTrack Simulation" not in answer


def test_statement_about_sleep_does_not_simulate(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "I slept 5 hours last night"
    )

    assert "TwinTrack Simulation" not in answer


# =====================================================
# 3. PARTIAL MULTI-VARIABLE REQUESTS
# =====================================================

def test_partial_sleep_and_vague_steps_is_refused(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "What if I sleep 8 hours and make my steps way higher?"
    )

    lower = answer.lower()

    assert "twintrack simulation" not in lower
    assert "steps" in lower
    assert "won't simulate only part" in lower


def test_partial_study_and_vague_rhr_is_refused(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "What if I study 2 hours and lower my resting heart rate a lot?"
    )

    lower = answer.lower()

    assert "twintrack simulation" not in lower
    assert "resting heart rate" in lower
    assert "won't simulate only part" in lower


def test_sleep_and_steps_natural_multi_request_fully_parses():

    updated, changes, error, unparsed = parse_result(
        "What if I sleep 8 hours and increase my steps by 2000?"
    )

    assert error is None
    assert not unparsed
    assert updated["sleep_hours"] == pytest.approx(8.0)
    assert updated["steps"] == 6500


def test_study_and_rhr_natural_multi_request_fully_parses():

    updated, changes, error, unparsed = parse_result(
        "What if I study 2 hours and my resting heart rate drops to 60?"
    )

    assert error is None
    assert not unparsed
    assert updated["study_minutes"] == pytest.approx(120)
    assert updated["resting_heart_rate"] == pytest.approx(60)


# =====================================================
# 4. CONFLICTING VALUES
# =====================================================

def test_conflicting_sleep_values_are_rejected():

    updated, changes, error, unparsed = parse_result(
        "What if I sleep 8 hours and sleep 5 hours?"
    )

    assert error is not None
    assert "two different sleep values" in error.lower()


# =====================================================
# 5. NATURAL PHRASING
# =====================================================

def test_natural_steps_increase():

    updated, changes, error, unparsed = parse_result(
        "What if I increase my steps by 2000?"
    )

    assert error is None
    assert not unparsed
    assert updated["steps"] == 6500


def test_two_more_hours_of_sleep():

    updated, changes, error, unparsed = parse_result(
        "What if I get 2 more hours of sleep?"
    )

    assert error is None
    assert not unparsed
    assert updated["sleep_hours"] == 8.0


def test_rhr_drops_to_60():

    updated, changes, error, unparsed = parse_result(
        "What if my resting heart rate drops to 60?"
    )

    assert error is None
    assert not unparsed
    assert updated["resting_heart_rate"] == 60


# =====================================================
# 6. EXTRAPOLATION WARNINGS
# =====================================================

def test_study_400_minutes_warns_extrapolation(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "What if I study 400 minutes?"
    )

    lower = answer.lower()

    assert "extrapolation" in lower
    assert "outside the observed training range" in lower


def test_sleep_3_hours_warns_extrapolation(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "What if I sleep 3 hours?"
    )

    lower = answer.lower()

    assert "extrapolation" in lower
    assert "outside the observed training range" in lower


def test_in_range_simulation_has_no_extrapolation_warning(
    mock_qwen
):

    answer = tt.ask_twintrack(
        "What if I sleep 8 hours?"
    )

    lower = answer.lower()

    assert "extrapolation" not in lower


def test_training_ranges_match_dataset():

    data_file = (
        ML_ROOT
        / "data"
        / "synthetic_students.csv"
    )

    df = pd.read_csv(data_file)

    for field, (low, high) in tt.TRAINING_RANGE.items():

        assert low == pytest.approx(
            float(df[field].min())
        )

        assert high == pytest.approx(
            float(df[field].max())
        )


# =====================================================
# 7. RESTING HEART RATE PRESENTATION
# =====================================================

def test_rhr_not_presented_as_confident_positive():

    item = next(
        item
        for item in tt.influences
        if item["feature"] == "resting_heart_rate"
    )

    assert item["direction"] == "uncertain"

    rhr_line = next(
        line
        for line in tt.influence_text.splitlines()
        if "resting_heart_rate" in line
    )

    assert "uncertain" in rhr_line.lower()


# =====================================================
# 8. QWEN NUMBER VERIFICATION
# =====================================================

def test_number_verifier_accepts_correct_values():

    bad = tt.find_unapproved_prediction_numbers(
        (
            "My prediction moves from 62.8% "
            "to 66.5%, an estimated +3.7 points."
        ),
        [62.8, 66.5, 3.7, 4.76]
    )

    assert bad == []


def test_number_verifier_rejects_fake_percentage():

    bad = tt.find_unapproved_prediction_numbers(
        "That would move you to 71.4%.",
        [62.8, 66.5, 3.7, 4.76]
    )

    assert 71.4 in bad


def test_number_verifier_rejects_wrong_difference():

    bad = tt.find_unapproved_prediction_numbers(
        (
            "My prediction moves from 62.8% "
            "to 66.5%, a change of 3.9 points."
        ),
        [62.8, 66.5, 3.7, 4.76]
    )

    assert 3.9 in bad


def test_number_verifier_accepts_negative_change():

    bad = tt.find_unapproved_prediction_numbers(
        (
            "My prediction moves from 62.8% "
            "to 61.0%, an estimated -1.8 points."
        ),
        [62.8, 61.0, -1.8, 4.76]
    )

    assert bad == []


def test_number_verifier_ignores_profile_units():

    bad = tt.find_unapproved_prediction_numbers(
        (
            "Moving sleep from 6 to 8 hours and study from "
            "60 to 120 minutes puts my supplied prediction at 66.5%."
        ),
        [62.8, 66.5, 3.7, 4.76]
    )

    assert bad == []


# =====================================================
# 9. PRODUCTION MODEL INTEGRITY
# =====================================================

def test_production_model_is_ridge_pipeline():

    model = tt.prediction_model

    assert hasattr(
        model,
        "named_steps"
    )

    assert "ridge" in model.named_steps


def test_best_alpha_is_10():

    assert tt.saved[
        "best_alpha"
    ] == pytest.approx(
        10.0
    )


def test_feature_order_is_correct():

    expected = [
        "sleep_hours",
        "steps",
        "exercise_minutes",
        "resting_heart_rate",
        "study_minutes",
        "screen_time_minutes",
        "previous_score",
    ]

    assert list(
        tt.feature_columns
    ) == expected


# =====================================================
# 10. HEADLINE MODEL METRICS
# =====================================================

def test_headline_holdout_metrics():

    data_file = (
        ML_ROOT
        / "data"
        / "synthetic_students.csv"
    )

    df = pd.read_csv(
        data_file
    )

    X = df[
        tt.feature_columns
    ]

    y = df[
        "assessment_score"
    ]

    _, X_test, _, y_test = train_test_split(
        X,
        y,
        test_size=0.20,
        random_state=42
    )

    predictions = tt.prediction_model.predict(
        X_test
    )

    mae = mean_absolute_error(
        y_test,
        predictions
    )

    rmse = mean_squared_error(
        y_test,
        predictions
    ) ** 0.5

    r2 = r2_score(
        y_test,
        predictions
    )

    assert mae == pytest.approx(
        4.76,
        abs=0.02
    )

    assert rmse == pytest.approx(
        5.87,
        abs=0.02
    )

    assert r2 == pytest.approx(
        0.570,
        abs=0.005
    )

# =====================================================
# 11. LIVE-CONVERSATION SAFETY REGRESSIONS
# =====================================================

def test_plain_steps_statement_never_reaches_qwen(monkeypatch):

    def fail_if_called(messages):
        raise AssertionError(
            "Plain measurement statement incorrectly reached Qwen."
        )

    monkeypatch.setattr(
        tt,
        "send_to_qwen",
        fail_if_called
    )

    answer = tt.ask_twintrack(
        "I walked 12000 steps yesterday"
    )

    lower = answer.lower()

    assert "twintrack simulation" not in lower
    assert "haven't changed" in lower
    assert "%" not in answer


def test_roughly_9_hours_sleep_routes_to_ridge(mock_qwen):

    updated, changes, error, unparsed = parse_result(
        "Roughly what would 9 hours of sleep give me?"
    )

    assert error is None
    assert not unparsed
    assert updated["sleep_hours"] == pytest.approx(9.0)

    expected_score = tt.predict_score(updated)

    answer = tt.ask_twintrack(
        "Roughly what would 9 hours of sleep give me?"
    )

    assert "TwinTrack Simulation" in answer
    assert f"Simulated: {expected_score:.1f}%" in answer


def test_rhr_simulation_contains_uncertainty_caution(mock_qwen):

    answer = tt.ask_twintrack(
        "What if my resting heart rate drops to 60?"
    )

    lower = answer.lower()

    assert "twintrack simulation" in lower
    assert "uncertain direction" in lower
    assert "do not interpret" in lower


def test_generic_qwen_invented_prediction_is_blocked(monkeypatch):

    monkeypatch.setattr(
        tt,
        "send_to_qwen",
        lambda messages: (
            "Based on that, your prediction would be 71.4%."
        )
    )

    answer = tt.ask_twintrack(
        "Tell me something interesting about my current profile."
    )

    assert "71.4%" not in answer
    assert "won't invent a prediction" in answer.lower()


def test_system_context_rejects_reliable_recommendation_ranking():

    context = tt.SYSTEM_CONTEXT.lower()

    assert "too close together" in context
    assert "reliable ranking" in context
    assert "rank them according to the calculated estimated differences" not in context