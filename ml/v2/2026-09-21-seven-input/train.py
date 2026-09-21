"""Training-only CV and full-precision export; no coefficient editing."""
import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.model_selection import GridSearchCV,KFold
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

from generator import CONFIG,FEATURES,SIX,TARGET


def fit(frame, features, seed):
    search = GridSearchCV(make_pipeline(StandardScaler(),Ridge()),
        {"ridge__alpha":CONFIG["alpha_grid"]}, scoring="neg_mean_absolute_error",
        cv=KFold(CONFIG["cv_folds"],shuffle=True,random_state=seed),n_jobs=1)
    search.fit(frame[features],frame[TARGET])
    return search.best_estimator_,float(-search.best_score_)


def export(model, features, training_rows):
    s,r = model["standardscaler"],model["ridge"]
    return {"schema_version":2,"model_version":CONFIG["version"],"synthetic_only":True,
        "deployment_approved":False,"features":features,"mean":s.mean_.tolist(),"scale":s.scale_.tolist(),
        "coefficients_standardized":r.coef_.tolist(),"intercept_standardized":float(r.intercept_),
        "coefficients_raw":(r.coef_/s.scale_).tolist(),"intercept_raw":float(r.intercept_-np.dot(r.coef_/s.scale_,s.mean_)),
        "alpha":float(r.alpha),"training_rows":training_rows,"training_selection":"all ten predeclared training splits pooled; no holdout rows",
        "training_seeds":CONFIG["seeds"],"pooled_cv_seed":CONFIG["pooled_cv_seed"],
        "output_clamp":[0,100],"bounds":{f:CONFIG["bounds"][f] for f in features},
        "units":{f:("hours/day" if f=="sleep_hours" else "steps/day" if f=="steps" else "bpm" if f=="resting_heart_rate" else "percentage points" if f=="previous_score" else "minutes/day") for f in features},
        "task":{"population":"UAE Grade12; same subject/comparable assessment","horizon_local_days":7,
            "habit_window_completed_local_days":28,"minimum_observed_days":21,"maximum_prior_score_age_days":90},
        "missing_policy":"abstain on missing required input; never substitute zero",
        "metadata_gate":"subject/date/day-coverage checks required before app integration; numeric helper cannot validate these",
        "input_transforms":"none except StandardScaler; nonlinear functions belong only to synthetic target generation"}


def predict(params, frame):
    x=frame[params["features"]].to_numpy(dtype=float)
    return ((x-np.array(params["mean"]))/np.array(params["scale"]))@np.array(params["coefficients_standardized"])+params["intercept_standardized"]


def eligible(values, features):
    for f in features:
        v=values.get(f)
        if v is None or not np.isfinite(v) or not CONFIG["bounds"][f][0]<=v<=CONFIG["bounds"][f][1]:
            return False
    if set(SIX).issubset(features):
        t=CONFIG["generator"]["time"]
        used=60*values["sleep_hours"]+sum(values[f] for f in ["study_minutes","screen_time_minutes","exercise_minutes"])
        if used>t["minutes_per_day"]-t["school_minutes_daily_average"]-t["other_reserved_minutes"]+1e-9:
            return False
    return True


def checked_predict(params, values):
    if not eligible(values,params["features"]):
        raise ValueError("Missing/nonfinite/out-of-support input or infeasible time budget")
    raw=float(predict(params,pd.DataFrame([values]))[0])
    return raw,float(np.clip(raw,0,100))
