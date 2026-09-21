"""Reuse frozen training machinery with explicit current-app observation metadata."""
import importlib.util
import numpy as np
import pandas as pd
from generator import CONFIG,FEATURES,SIX,TARGET,PREVIOUS

spec=importlib.util.spec_from_file_location("aligned_previous_train",PREVIOUS/"train.py")
previous_train=importlib.util.module_from_spec(spec);spec.loader.exec_module(previous_train)
fit=previous_train.fit
predict=previous_train.predict


def export(model,features,training_rows):
    p=previous_train.export(model,features,training_rows)
    p["task"]={"population":"Grade12 educational prototype; transfer validity unknown","target":"current-profile score on 0–100 scale; not a validated forecast","prediction_horizon":None,
        "sleep":"union asleep hours yesterday local noon to min(refresh,today noon)","steps":"previous completed local calendar day sum","exercise_minutes":"previous completed local calendar day sum",
        "resting_heart_rate":"latest valid positive finite sample startDate in inclusive last72 elapsed hours; timestamp retained",
        "study_minutes":"latest saved user-entered minutes; reporting period/date unknown",
        "screen_time_minutes":"latest saved user-entered minutes; reporting period/date/content unknown",
        "previous_score":"latest saved 0–100 user score; date/subject/comparability unknown"}
    p["units"]={f:("hours in captured sleep window" if f=="sleep_hours" else "count in previous day" if f=="steps" else "bpm" if f=="resting_heart_rate" else "0–100 score points" if f=="previous_score" else "minutes") for f in features}
    p["metadata_gate"]="existing health-window freshness and RHR timestamp checks; no invented 28-day coverage or manual-entry date"
    p["what_if_time_constraint"]="Different source periods; do not sum all inputs into one fictitious 24-hour day"
    return p


def eligible(values,features):
    return all(values.get(f) is not None and np.isfinite(values[f]) and CONFIG["bounds"][f][0]<=values[f]<=CONFIG["bounds"][f][1] for f in features)


def checked_predict(params,values):
    if not eligible(values,params["features"]): raise ValueError("Missing/nonfinite/out-of-support input")
    raw=float(predict(params,pd.DataFrame([values]))[0])
    return raw,float(np.clip(raw,0,100))
