"""App-source snapshot simulation; no real health data, added Ridge features or prior edits."""
import copy
import importlib.util
import json
from pathlib import Path

import numpy as np
import pandas as pd

HERE=Path(__file__).resolve().parent
PREVIOUS=HERE.parent/"2026-09-21-seven-input"
OVERRIDES=json.loads((HERE/"config.json").read_text())
CONFIG=json.loads((PREVIOUS/"config.json").read_text())
CONFIG.update({k:v for k,v in OVERRIDES.items() if k!="inherits"})
FEATURES=list(CONFIG["bounds"])
SIX=[f for f in FEATURES if f!="resting_heart_rate"]
TARGET="assessment_score"
spec=importlib.util.spec_from_file_location("aligned_latent_generator",PREVIOUS/"generator.py")
latent_generator=importlib.util.module_from_spec(spec);spec.loader.exec_module(latent_generator)
LATENT_CONFIG=copy.deepcopy(latent_generator.CONFIG)
latent_generator.CONFIG=copy.deepcopy(LATENT_CONFIG)
latent_generator.CONFIG["generator"]["measurement_sd"]={f:0 for f in FEATURES}
SCENARIOS=latent_generator.SCENARIOS+["sleep_complete","sleep_early","source_variation_double"]


def expected_score(frame,scenario="central"):
    """Assumed latent-profile function, NOT an empirically validated snapshot effect."""
    return latent_generator.expected_score(frame,scenario if scenario in latent_generator.SCENARIOS else "central")


def generate(seed,n,scenario="central"):
    if scenario not in SCENARIOS: raise ValueError(scenario)
    base= scenario if scenario in latent_generator.SCENARIOS else "central"
    latent,fitness,meta=latent_generator.generate(seed,n,base)
    rng=np.random.default_rng(seed+CONFIG["snapshot"]["rng_seed_offset"])
    s=CONFIG["snapshot"]
    factor=s["variation_stress_multiplier"] if scenario in ["source_variation_double","measurement_double"] else 1
    observed=latent.copy()
    # Local-hour axis: yesterday midnight=0, yesterday noon=12, today midnight=24.
    hour=rng.uniform(*s["refresh_hour_bounds"],n)
    if scenario=="sleep_complete": hour[:]=12
    if scenario=="sleep_early": hour[:]=2
    start=np.clip(rng.normal(s["sleep_start_mean"],s["sleep_start_sd"],n),*s["sleep_start_bounds"])
    duration=np.clip(latent.sleep_hours+rng.normal(0,s["sleep_day_sd"]*factor,n),*s["sleep_duration_bounds"])
    observed["sleep_hours"]=np.maximum(0,np.minimum(start+duration,24+np.minimum(hour,12))-np.maximum(start,12))
    # One accessible synthetic overnight episode; missed/no-asleep nights handled by missingness, never fake zero.
    assert (observed.sleep_hours>0).all()
    activity=rng.normal(0,s["activity_log_sd"]*factor,n)
    exercise=latent.exercise_minutes*np.exp(activity)
    exercise[rng.random(n)<s["exercise_zero_probability"]]=0
    previous_sleep=np.clip(latent.sleep_hours+rng.normal(0,s["sleep_day_sd"]*factor,n),0,12)
    exercise=np.minimum(exercise,1440-s["previous_day_reserved_minutes"]-60*previous_sleep)
    observed["exercise_minutes"]=exercise
    steps=latent.steps+s["step_exercise_loading"]*(exercise-latent.exercise_minutes)+rng.normal(0,s["step_day_sd"]*factor,n)
    steps[rng.random(n)<s["steps_zero_probability"]]=0
    observed["steps"]=steps.round()
    age=rng.uniform(*s["rhr_age_hours_bounds"],n)
    observed["resting_heart_rate"]=latent.resting_heart_rate+rng.normal(0,s["rhr_day_sd"]*factor,n)+rng.normal(size=n)*age*s["rhr_age_drift_sd_per_hour"]*factor
    observed["study_minutes"]=(latent.study_minutes+rng.normal(0,s["study_report_sd"]*factor,n)).round()
    observed["screen_time_minutes"]=(latent.screen_time_minutes+rng.normal(0,s["screen_report_sd"]*factor,n)).round()
    observed["previous_score"]=latent.previous_score+rng.normal(0,s["score_report_sd"]*factor,n)
    for f in FEATURES: observed[f]=observed[f].clip(*CONFIG["bounds"][f])
    observed["synthetic_refresh_local_hour"]=hour
    observed["synthetic_rhr_age_hours"]=age
    observed["synthetic_sleep_uncut_hours"]=duration
    observed["synthetic_previous_day_sleep_hours"]=previous_sleep
    meta.update(scenario=scenario,observation_contract="app_source_snapshot",target_contract="educational_current_profile_score_no_validated_forecast_horizon")
    return observed,fitness,meta


def apply_missingness(frame,fitness,seed):
    return latent_generator.apply_missingness(frame,fitness,seed)
