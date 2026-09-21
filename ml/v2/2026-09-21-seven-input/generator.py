"""Explicitly synthetic window summaries; all numeric assumptions in config.json."""
import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.special import ndtr
from scipy.stats import beta

HERE = Path(__file__).resolve().parent
CONFIG = json.loads((HERE / "config.json").read_text())
FEATURES = list(CONFIG["bounds"])
SIX = [f for f in FEATURES if f != "resting_heart_rate"]
TARGET = "assessment_score"
SCENARIOS = ["central", "null_habits", "double_habits", "rhr_null", "rhr_negative",
             "rhr_positive", "opposite_sleep", "low_noise", "high_noise", "linear",
             "shifted_caps", "population_shift", "previous_low", "previous_high",
             "strong_activity_coupling", "measurement_double"]


def constrain_time(frame):
    t = CONFIG["generator"]["time"]
    cols = ["study_minutes", "screen_time_minutes", "exercise_minutes"]
    budget = t["minutes_per_day"] - t["school_minutes_daily_average"] - t["other_reserved_minutes"] - 60 * frame.sleep_hours
    scale = np.minimum(1, budget / frame[cols].sum(axis=1).replace(0, 1))
    frame[cols] = frame[cols].mul(scale, axis=0)
    return frame


def transformed(frame, scenario):
    """Hypothetical target functions, never transforms applied to fitted Ridge inputs."""
    result = frame.copy()
    if scenario == "linear":
        return result
    p = CONFIG["stress"]["shifted_nonlinear"] if scenario == "shifted_caps" else CONFIG["generator"]["nonlinear"]
    result["sleep_hours"] = result.sleep_hours.clip(upper=p["sleep_cap"])
    result["study_minutes"] = p["study_multiplier"] * np.log1p(result.study_minutes / p["study_scale"])
    result["exercise_minutes"] = result.exercise_minutes.clip(upper=p["exercise_cap"])
    result["screen_time_minutes"] = (result.screen_time_minutes - p["screen_neutral_minutes"]).clip(lower=0)
    return result


def expected_score(latent, scenario="central"):
    g, s = CONFIG["generator"], CONFIG["stress"]
    effects = dict(g["target"]["habit_coefficients"])
    if scenario == "null_habits":
        effects = {f: 0 for f in effects}
    if scenario == "double_habits":
        effects = {f: v * s["double_effect_multiplier"] for f, v in effects.items()}
    if scenario in ["rhr_null", "rhr_negative", "rhr_positive"]:
        effects["resting_heart_rate"] = s["rhr_slopes"][["rhr_null", "rhr_negative", "rhr_positive"].index(scenario)]
    if scenario == "opposite_sleep":
        effects["sleep_hours"] *= -1
    previous = g["target"]["previous_slope"]
    if scenario in ["previous_low", "previous_high"]:
        previous = s["previous_slopes"][scenario == "previous_high"]
    z = transformed(latent, scenario)
    reference = transformed(pd.DataFrame([CONFIG["reference"]]), scenario).iloc[0]
    signal = g["target"]["mean"] + previous * (latent.previous_score - CONFIG["reference"]["previous_score"])
    for f, coefficient in effects.items():
        signal += coefficient * (z[f] - reference[f])
    return signal


def generate(seed, n, scenario="central"):
    if scenario not in SCENARIOS:
        raise ValueError(scenario)
    rng = np.random.default_rng(seed)
    g, s = CONFIG["generator"], CONFIG["stress"]
    engagement, fitness, screens = rng.normal(size=(3, n))
    p = g["sleep"]
    sleep = p["mean"] + p["screen_loading"]*screens + p["engagement_loading"]*engagement + rng.normal(0,p["noise_sd"],n)
    p = g["study"]
    study = np.exp(np.log(p["median"]) + p["engagement_loading"]*engagement + p["screen_loading"]*screens + rng.normal(0,p["log_noise_sd"],n))
    study[rng.random(n) < p["zero_probability"]] = 0
    p = g["screen"]
    screen = np.exp(np.log(p["median"]) + p["preference_loading"]*screens + p["engagement_loading"]*engagement + rng.normal(0,p["log_noise_sd"],n))
    p = g["exercise"]
    exercise = rng.gamma(p["gamma_shape"],p["gamma_scale"],n)*np.exp(p["fitness_loading"]*fitness)
    exercise[rng.random(n) < p["zero_probability"]] = 0
    p = g["previous"]
    z = p["engagement_loading"]*engagement + np.sqrt(1-p["engagement_loading"]**2)*rng.normal(size=n)
    shape = s["shifted_previous_beta"] if scenario == "population_shift" else [p["beta_a"],p["beta_b"]]
    previous = 100*beta.ppf(ndtr(z),*shape)
    if scenario == "population_shift":
        sleep += s["shifted_sleep_hours"]
        screen += s["shifted_screen_minutes"]
    latent = pd.DataFrame(dict(sleep_hours=sleep,study_minutes=study,screen_time_minutes=screen,exercise_minutes=exercise,previous_score=previous))
    for f in latent:
        latent[f] = latent[f].clip(*CONFIG["bounds"][f])
    latent = constrain_time(latent)
    p = g["steps"]
    coupling, incidental, log_sd = p["per_exercise_minute"],p["incidental_median"],p["incidental_log_sd"]
    if scenario == "strong_activity_coupling":
        coupling, incidental, log_sd = 70,2000,.35  # previous frozen V2 generator, documented stress only
    latent["steps"] = p["base"] + coupling*latent.exercise_minutes + rng.lognormal(np.log(incidental),log_sd,n)
    p = g["rhr"]
    latent["resting_heart_rate"] = p["mean"]+p["fitness_loading"]*fitness+p["sleep_deficit_loading"]*(CONFIG["reference"]["sleep_hours"]-latent.sleep_hours)+rng.normal(0,p["noise_sd"],n)
    for f in FEATURES:
        latent[f] = latent[f].clip(*CONFIG["bounds"][f])
    observed = latent[FEATURES].copy()
    multiplier = s["measurement_multiplier"] if scenario == "measurement_double" else 1
    for f in FEATURES:
        observed[f] = (observed[f]+rng.normal(0,g["measurement_sd"][f]*multiplier,n)).clip(*CONFIG["bounds"][f])
    observed = constrain_time(observed)
    noise = s[scenario+"_sd"] if scenario in ["low_noise","high_noise"] else g["target"]["outcome_noise_sd"]
    raw = expected_score(latent,scenario)+rng.normal(0,noise,n)
    observed[TARGET] = raw.clip(0,100)
    return observed,fitness,{"seed":seed,"scenario":scenario,"rows":n,"target_clipped_fraction":float(((raw<0)|(raw>100)).mean())}


def apply_missingness(frame, fitness, seed):
    rng = np.random.default_rng(seed)
    rates = CONFIG["generator"]["missingness"]
    masked = frame.copy()
    shared = rng.random(len(frame)) < rates["shared_wearable_failure_probability"]
    for f in FEATURES:
        p = np.full(len(frame),rates[f],dtype=float)
        p += (frame.screen_time_minutes>rates["high_screen_threshold"])*rates["high_screen_added_probability"]
        if f == "resting_heart_rate":
            p += (fitness<0)*rates["low_fitness_added_rhr_probability"]
        missing = rng.random(len(frame))<p
        if f in FEATURES[:4]:
            missing |= shared
        masked.loc[missing,f] = np.nan
    return masked
