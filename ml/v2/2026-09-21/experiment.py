"""Offline, synthetic-only V2 experiment. Never writes outside --output.

Run from this directory with the pinned requirements. See PROTOCOL.md before use.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import platform
import subprocess
import warnings
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import scipy
import sklearn
from scipy.special import ndtr
from scipy.stats import beta
from sklearn.dummy import DummyRegressor
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GridSearchCV, KFold, train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CONFIG = json.loads((HERE / "config.json").read_text())
FEATURES = list(CONFIG["bounds"])
SIX = [f for f in FEATURES if f != "resting_heart_rate"]
TARGET = "assessment_score"
SCENARIOS = ["central", "null_habits", "double_habits", "opposite_sleep", "low_noise",
             "high_noise", "rhr_negative", "rhr_positive", "saturation", "population_shift"]


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def protected_hashes():
    paths = subprocess.check_output(["git", "ls-files", "-z", "ml", "ios"], cwd=ROOT).decode().split("\0")
    return {p: digest(ROOT / p) for p in paths if p and not p.startswith("ml/v2/")
            and "/xcuserdata/" not in p and (ROOT / p).is_file()}


def constrain_time(frame):
    """Mutually exclusive primary activities; steps overlap activity, not extra time."""
    time = CONFIG["generator"]["time"]
    cols = ["study_minutes", "screen_time_minutes", "exercise_minutes"]
    available = time["minutes_per_day"] - time["school_minutes_daily_average"] - time["other_reserved_minutes"] - 60 * frame.sleep_hours
    total = frame[cols].sum(axis=1)
    scale = np.minimum(1, available / total.replace(0, 1))
    frame[cols] = frame[cols].mul(scale, axis=0)
    return frame


def generate(seed, n, scenario="central"):
    """One independent synthetic window-summary row per student; no real records."""
    if scenario not in SCENARIOS:
        raise ValueError(scenario)
    rng = np.random.default_rng(seed)
    g, stress, ref = CONFIG["generator"], CONFIG["stress"], CONFIG["reference"]
    engagement, fitness, screens = rng.normal(size=(3, n))
    s = g["sleep"]
    sleep = s["mean"] + s["screen_loading"] * screens + s["engagement_loading"] * engagement + rng.normal(0, s["noise_sd"], n)
    s = g["study"]
    study = np.exp(np.log(s["median"]) + s["engagement_loading"] * engagement + s["screen_loading"] * screens + rng.normal(0, s["log_noise_sd"], n))
    study[rng.random(n) < s["zero_probability"]] = 0
    s = g["screen"]
    screen = np.exp(np.log(s["median"]) + s["preference_loading"] * screens + s["engagement_loading"] * engagement + rng.normal(0, s["log_noise_sd"], n))
    s = g["exercise"]
    exercise = rng.gamma(s["gamma_shape"], s["gamma_scale"], n) * np.exp(s["fitness_loading"] * fitness)
    exercise[rng.random(n) < s["zero_probability"]] = 0
    s = g["previous"]
    z_previous = s["engagement_loading"] * engagement + np.sqrt(1 - s["engagement_loading"] ** 2) * rng.normal(size=n)
    shape = stress["shifted_previous_beta"] if scenario == "population_shift" else [s["beta_a"], s["beta_b"]]
    previous = 100 * beta.ppf(ndtr(z_previous), *shape)
    if scenario == "population_shift":
        sleep += stress["shifted_sleep_hours"]
        screen += stress["shifted_screen_minutes"]
    latent = pd.DataFrame({"sleep_hours": sleep, "study_minutes": study,
                           "screen_time_minutes": screen, "exercise_minutes": exercise,
                           "previous_score": previous})
    for f in latent:
        latent[f] = latent[f].clip(*CONFIG["bounds"][f])
    latent = constrain_time(latent)
    s = g["steps"]
    latent["steps"] = s["base"] + s["per_exercise_minute"] * latent.exercise_minutes + rng.lognormal(np.log(s["incidental_median"]), s["incidental_log_sd"], n)
    s = g["rhr"]
    latent["resting_heart_rate"] = s["mean"] + s["fitness_loading"] * fitness + s["sleep_deficit_loading"] * (ref["sleep_hours"] - latent.sleep_hours) + rng.normal(0, s["noise_sd"], n)
    for f in FEATURES:
        latent[f] = latent[f].clip(*CONFIG["bounds"][f])
    observed = latent[FEATURES].copy()
    for f in FEATURES:
        observed[f] = (observed[f] + rng.normal(0, g["measurement_sd"][f], n)).clip(*CONFIG["bounds"][f])
    observed = constrain_time(observed)
    effects = dict(g["target"]["habit_coefficients"])
    if scenario == "null_habits":
        effects = {f: 0 for f in effects}
    if scenario == "double_habits":
        effects = {f: v * stress["double_effect_multiplier"] for f, v in effects.items()}
    if scenario == "opposite_sleep":
        effects["sleep_hours"] *= -1
    if scenario in ["rhr_negative", "rhr_positive"]:
        effects["resting_heart_rate"] = stress["rhr_slopes"][scenario == "rhr_positive"]
    causal_inputs = latent.copy()  # simulated structural inputs, NOT human causal evidence
    if scenario == "saturation":
        for f, cap in stress["saturation_caps"].items():
            causal_inputs[f] = causal_inputs[f].clip(upper=cap)
    signal = g["target"]["mean"] + g["target"]["previous_slope"] * (latent.previous_score - ref["previous_score"])
    for f, coefficient in effects.items():
        signal += coefficient * (causal_inputs[f] - ref[f])
    noise_sd = g["target"]["outcome_noise_sd"]
    if scenario in ["low_noise", "high_noise"]:
        noise_sd = stress[scenario + "_sd"]
    y_raw = signal + rng.normal(0, noise_sd, n)
    observed[TARGET] = y_raw.clip(0, 100)
    meta = {"target_clip_fraction": float(np.mean((y_raw < 0) | (y_raw > 100))),
            "rows": n, "seed": seed, "scenario": scenario}
    return observed, fitness, meta


def apply_missingness(frame, fitness, seed):
    rng = np.random.default_rng(seed)
    rates = CONFIG["generator"]["missingness"]
    masked = frame.copy()
    shared = rng.random(len(frame)) < rates["shared_wearable_failure_probability"]
    for f in FEATURES:
        p = np.full(len(frame), rates[f], dtype=float)
        p += (frame.screen_time_minutes > rates["high_screen_threshold"]) * rates["high_screen_added_probability"]
        if f == "resting_heart_rate":
            p += (fitness < 0) * rates["low_fitness_added_rhr_probability"]
        missing = rng.random(len(frame)) < p
        if f in FEATURES[:4]:
            missing |= shared
        masked.loc[missing, f] = np.nan
    return masked


def fit_ridge(frame, features, seed):
    cv = KFold(CONFIG["cv_folds"], shuffle=True, random_state=seed)
    pipeline = make_pipeline(StandardScaler(), Ridge())
    search = GridSearchCV(pipeline, {"ridge__alpha": CONFIG["alpha_grid"]},
                          scoring="neg_mean_absolute_error", cv=cv, n_jobs=1)
    search.fit(frame[features], frame[TARGET])
    return search.best_estimator_, float(search.best_params_["ridge__alpha"]), float(-search.best_score_)


def export_ridge(model, features, seed):
    scaler, ridge = model["standardscaler"], model["ridge"]
    return {"schema_version": 2, "model_version": CONFIG["version"],
            "synthetic_only": True, "deployment_approved": False,
            "features": features, "mean": scaler.mean_.tolist(), "scale": scaler.scale_.tolist(),
            "coefficients_standardized": ridge.coef_.tolist(), "intercept_standardized": float(ridge.intercept_),
            "coefficients_raw": (ridge.coef_ / scaler.scale_).tolist(),
            "intercept_raw": float(ridge.intercept_ - np.dot(ridge.coef_ / scaler.scale_, scaler.mean_)),
            "alpha": float(ridge.alpha), "training_seed": seed,
            "output_clamp": [0, 100], "bounds": {f: CONFIG["bounds"][f] for f in features},
            "task": "Grade12_same_subject_test_7_days_after_28_day_window_v2",
            "missing_policy": "abstain; never replace missing inputs with zero"}


def predict_export(params, frame):
    x = frame[params["features"]].to_numpy(dtype=float)
    return ((x - np.array(params["mean"])) / np.array(params["scale"])) @ np.array(params["coefficients_standardized"]) + params["intercept_standardized"]


def checked_predict(params, values):
    """Research export contract; bounds are engineering support limits, not medical advice."""
    for f in params["features"]:
        v = values.get(f)
        if v is None or not np.isfinite(v) or not params["bounds"][f][0] <= v <= params["bounds"][f][1]:
            raise ValueError("Missing, nonfinite, or out-of-support input: " + f)
    if set(SIX).issubset(params["features"]):
        t = CONFIG["generator"]["time"]
        used = 60 * values["sleep_hours"] + sum(values[f] for f in ["study_minutes", "screen_time_minutes", "exercise_minutes"])
        if used > t["minutes_per_day"] - t["school_minutes_daily_average"] - t["other_reserved_minutes"] + 1e-9:
            raise ValueError("Infeasible time-use combination")
    raw = predict_export(params, pd.DataFrame([values]))[0]
    return float(raw), float(np.clip(raw, 0, 100))


def metrics(y, pred):
    y, pred = np.asarray(y), np.asarray(pred)
    slope, intercept = (np.polyfit(pred, y, 1) if np.std(pred) > 1e-10 else [np.nan, np.nan])
    return {"n": len(y), "mae": float(mean_absolute_error(y, pred)),
            "rmse": float(np.sqrt(mean_squared_error(y, pred))), "r2": float(r2_score(y, pred)),
            "bias_pred_minus_actual": float(np.mean(pred - y)),
            "calibration_slope": float(slope), "calibration_intercept": float(intercept)}


def json_safe(value):
    # Calibration is undefined for mean-only prediction, represented honestly as null.
    return {k: (None if isinstance(v, float) and not np.isfinite(v) else v) for k, v in value.items()}


def audit_v1(output):
    df = pd.read_csv(ROOT / "ml/data/synthetic_students.csv")
    params = json.loads((ROOT / "ml/frozen_export/twintrack_model_params.json").read_text())
    assert params["feature_order"] == FEATURES
    with warnings.catch_warnings(record=True) as captured:
        warnings.simplefilter("always")
        saved = joblib.load(ROOT / "ml/models/twintrack_model.joblib")
        frozen = joblib.load(ROOT / "ml/frozen_export/twintrack_model.joblib")
    model = saved["model"]
    train, test = train_test_split(df, test_size=.2, random_state=42)
    pred = model.predict(test[FEATURES])
    formula = ((test[FEATURES].to_numpy() - params["scaler"]["mean"]) / params["scaler"]["scale"]) @ np.array(params["ridge"]["coef"]) + params["ridge"]["intercept"]
    regenerated = {}
    # Execute only the pure generation prefix in memory, before any path/output code.
    source = (ROOT / "ml/src/generate_data.py").read_text().split("# Find the ml/data folder")[0]
    exec(compile(source, "V1_GENERATION_IN_MEMORY", "exec"), regenerated)
    assert np.max(np.abs(df.to_numpy() - regenerated["df"].to_numpy())) < 1e-12
    audit = {"artifact_version_warnings": sorted(set(str(w.message) for w in captured)),
             "rows": len(df), "split_train": len(train), "split_test": len(test),
             "pipeline": str(model), "alpha": saved["best_alpha"], "features": saved["features"],
             "artifact_json_prediction_max_error": float(np.max(np.abs(pred - formula))),
             "frozen_copy_prediction_max_error": float(np.max(np.abs(pred - frozen["model"].predict(test[FEATURES])))),
             "generator_csv_numeric_match": True,
             "scaler_training_mean_max_error": float(np.max(np.abs(model["scaler"].mean_ - train[FEATURES].mean().values))),
             "scaler_training_sd_max_error": float(np.max(np.abs(model["scaler"].scale_ - train[FEATURES].std(ddof=0).values))),
             "raw": metrics(test[TARGET], pred), "clamped": metrics(test[TARGET], np.clip(pred, 0, 100)),
             "clip_fraction": float(np.mean(pred != np.clip(pred, 0, 100))),
             "saved_metrics": saved["test_metrics"], "summary": df.describe().to_dict(),
             "correlations": df.corr().to_dict(), "raw_coefficients": dict(zip(FEATURES, (model["ridge"].coef_ / model["scaler"].scale_).tolist()))}
    for key, estimator, fs in [("mean_baseline", DummyRegressor(), FEATURES),
                                ("previous_ols_baseline", LinearRegression(), ["previous_score"])]:
        estimator.fit(train[fs], train[TARGET])
        audit[key] = metrics(test[TARGET], estimator.predict(test[fs]))
    # Reproduce tuning without executing scripts that write production artifacts.
    grid = [.01, .1, .5, 1, 2, 5, 10, 20, 50, 100]
    search = GridSearchCV(make_pipeline(StandardScaler(), Ridge()), {"ridge__alpha": grid},
                          scoring="neg_mean_absolute_error", cv=KFold(5, shuffle=True, random_state=42), n_jobs=1)
    search.fit(train[FEATURES], train[TARGET])
    audit["retuned_in_memory_alpha"] = search.best_params_["ridge__alpha"]
    audit["retuned_cv_mae"] = float(-search.best_score_)
    audit["refit_coefficient_max_error"] = float(np.max(np.abs(search.best_estimator_["ridge"].coef_ - model["ridge"].coef_)))
    gold = json.loads((ROOT / "ml/frozen_export/golden_profiles.json").read_text())
    errors = []
    for p in gold["profiles"]:
        x = np.array([p["inputs"][f] for f in FEATURES])
        raw = float(np.dot((x - params["scaler"]["mean"]) / params["scaler"]["scale"], params["ridge"]["coef"]) + params["ridge"]["intercept"])
        errors.append(max(abs(raw - p["expected_raw"]), abs(np.clip(raw, 0, 100) - p["expected_clamped"])))
    audit["golden"] = {"total": len(errors), "pass": sum(int(e <= gold["tolerance"]) for e in errors), "max_error": float(max(errors)), "tolerance": gold["tolerance"], "scope": "Python frozen artifact/JSON; no new Swift run"}
    dump(output / "v1_audit.json", {k: json_safe(v) if isinstance(v, dict) and k.endswith("baseline") else v for k, v in audit.items()})
    return model


def bootstrap_difference(y, a, b):
    rng = np.random.default_rng(CONFIG["bootstrap_seed"])
    difference = np.abs(a - y) - np.abs(b - y)
    boot = [np.mean(difference[rng.integers(0, len(y), len(y))]) for _ in range(CONFIG["bootstrap_replicates"])]
    return {"mae_difference_first_minus_second": float(difference.mean()),
            "ci_95": np.quantile(boot, [.025, .975]).tolist(), "replicates": len(boot), "unit": "independent synthetic row"}


def run(output):
    output = output.resolve()
    # A rerun must choose a new output path, preserving previous artifacts/results.
    if output.exists():
        raise FileExistsError("Choose a new --output directory; existing experiment results are immutable")
    output.mkdir(parents=True)
    before = protected_hashes()
    dump(output / "protected_v1_ios_sha256.json", before)
    dump(output / "environment.json", {"python": platform.python_version(), "numpy": np.__version__,
         "pandas": pd.__version__, "scipy": scipy.__version__, "sklearn": sklearn.__version__, "joblib": joblib.__version__,
         "config_sha256": digest(HERE / "config.json"), "protocol_sha256": digest(HERE / "PROTOCOL.md"),
         "script_sha256": digest(__file__)})
    v1 = audit_v1(output)
    rows, coeffs, artifacts, models, selections = [], [], {}, {}, []
    first_seed = CONFIG["development_seeds"][0]
    feature_sets = {"previous_only": ["previous_score"], "ridge_six": SIX, "ridge_seven": FEATURES}
    for seed in CONFIG["development_seeds"]:
        data, _, meta = generate(seed, CONFIG["development_rows"])
        train, holdout = train_test_split(data, test_size=CONFIG["holdout_fraction"], random_state=seed)
        candidates = {"v1_frozen": (v1, FEATURES), "mean_only": (DummyRegressor().fit(train[FEATURES], train[TARGET]), FEATURES)}
        for name, fs in feature_sets.items():
            model, alpha, cv_mae = fit_ridge(train, fs, seed)
            params = export_ridge(model, fs, seed)
            assert np.max(np.abs(predict_export(params, holdout) - model.predict(holdout[fs]))) < 1e-10
            candidates[name] = (model, fs)
            selections.append({"seed": seed, "model": name, "alpha": alpha, "cv_mae": cv_mae})
            for f, z, raw in zip(fs, params["coefficients_standardized"], params["coefficients_raw"]):
                coeffs.append({"seed": seed, "model": name, "feature": f, "standardized": z, "points_per_unit": raw})
            if seed == first_seed:
                artifacts[name] = params
        for name, (model, fs) in candidates.items():
            p = model.predict(holdout[fs])
            for kind, predictions in [("raw", p), ("clamped", np.clip(p, 0, 100))]:
                rows.append({"split": "development_holdout", "seed": seed, "scenario": "central", "model": name, "output": kind, **metrics(holdout[TARGET], predictions)})
        if seed == first_seed:
            models = candidates
            data["split"] = np.where(data.index.isin(train.index), "train", "development_holdout")
            data.to_csv(output / "synthetic_development.csv", index_label="synthetic_row", float_format="%.17g")
            dump(output / "synthetic_summary.json", {"development": meta, "statistics": data[FEATURES+[TARGET]].describe().to_dict(), "correlations": data[FEATURES+[TARGET]].corr().to_dict()})
            dump(output / "split_indices.json", {"train": train.index.tolist(), "holdout": holdout.index.tolist()})
    predictions, calibration, coverage, extremes, tests = {}, [], [], [], []
    for scenario in SCENARIOS:
        data, fitness, meta = generate(CONFIG["final_seed"], CONFIG["final_rows"], scenario)
        for name, (model, fs) in models.items():
            p = model.predict(data[fs])
            predictions[(scenario, name)] = p
            for kind, pp in [("raw", p), ("clamped", np.clip(p, 0, 100))]:
                rows.append({"split": "independent_synthetic_test", "seed": CONFIG["final_seed"], "scenario": scenario, "model": name, "output": kind, **metrics(data[TARGET], pp)})
            if scenario == "central":
                # Rank bins only for descriptive calibration, never fitting a correction.
                bins = pd.qcut(pd.Series(p).rank(method="first"), 10, labels=False)
                for bin_id in range(10):
                    ix = np.asarray(bins == bin_id)
                    calibration.append({"model": name, "bin": bin_id+1, "n": int(ix.sum()), "prediction_mean": float(p[ix].mean()), "actual_mean": float(data[TARGET][ix].mean()), "bias": float((p[ix] - data[TARGET][ix]).mean())})
        tests.append(meta)
        if scenario == "central":
            final = data.copy()
            masked = apply_missingness(data, fitness, CONFIG["final_seed"]+1)
            data.to_csv(output / "synthetic_final_test.csv", index_label="synthetic_row", float_format="%.17g")
            masked.to_csv(output / "synthetic_missingness_test.csv", index_label="synthetic_row", float_format="%.17g")
            for name, (model, fs) in models.items():
                needed = [] if name == "mean_only" else fs
                for cohort in ["common_seven", "model_eligible"]:
                    eligible = masked[FEATURES if cohort == "common_seven" else needed].notna().all(axis=1)
                    p = model.predict(data.loc[eligible, fs])
                    coverage.append({"model": name, "cohort": cohort, "coverage": float(eligible.mean()), **metrics(data.loc[eligible, TARGET], p)})
            common_six = masked[SIX].notna().all(axis=1)
            for name in ["previous_only", "ridge_six"]:
                model, fs = models[name]
                coverage.append({"model": name, "cohort": "common_six", "coverage": float(common_six.mean()), **metrics(data.loc[common_six, TARGET], model.predict(data.loc[common_six, fs]))})
    differences = {}
    for a, b in [("ridge_six", "previous_only"), ("ridge_seven", "previous_only"), ("ridge_seven", "ridge_six")]:
        differences[a+"_minus_"+b] = bootstrap_difference(final[TARGET].values, predictions[("central", a)], predictions[("central", b)])
    for name, params in artifacts.items():
        dump(output / (name + "_candidate.json"), params)
        for bits in itertools.product([0, 1], repeat=len(FEATURES)):
            values = {f: CONFIG["bounds"][f][b] for f, b in zip(FEATURES, bits)}
            raw = float(predict_export(params, pd.DataFrame([values]))[0])
            try:
                checked_predict(params, values)
                permitted = True
            except ValueError:
                permitted = False
            extremes.append({"model": name, "corner": "".join(map(str, bits)), "permitted": permitted, "raw_prediction": raw, "clamped_prediction": float(np.clip(raw, 0, 100)), **values})
        golden = []
        anchor = dict(CONFIG["reference"])
        for f in params["features"]:
            for value in CONFIG["bounds"][f]:
                profile = {**anchor, f: value}
                try:
                    raw, clamped = checked_predict(params, profile)
                    golden.append({"profile": profile, "expected_raw": raw, "expected_clamped": clamped})
                except ValueError:
                    golden.append({"profile": profile, "expected": "reject_infeasible_time"})
        dump(output / (name + "_export_checks.json"), {"scope": "Python export checks; not Swift parity", "profiles": golden})
    pd.DataFrame(rows).to_csv(output / "metrics.csv", index=False)
    coefficient_table = pd.DataFrame(coeffs)
    coefficient_table.to_csv(output / "coefficients.csv", index=False)
    stability = coefficient_table.groupby(["model", "feature"])["points_per_unit"].agg(["mean", "std", "min", "max"])
    stability["positive_fraction"] = coefficient_table.groupby(["model", "feature"])["points_per_unit"].apply(lambda s: (s > 0).mean())
    stability.to_csv(output / "coefficient_stability.csv")
    pd.DataFrame(selections).to_csv(output / "training_cv.csv", index=False)
    pd.DataFrame(calibration).to_csv(output / "calibration.csv", index=False)
    pd.DataFrame(coverage).to_csv(output / "missingness_coverage.csv", index=False)
    pd.DataFrame(extremes).to_csv(output / "extreme_cases.csv", index=False)
    dump(output / "paired_mae_intervals.json", differences)
    dump(output / "scenario_definitions_and_clipping.json", tests)
    # Apply the predeclared gate; do not move thresholds after seeing results.
    table = pd.DataFrame(rows)
    dev = table[(table.split == "development_holdout") & (table.output == "raw")]
    gates = {}
    for candidate, baseline in [("ridge_six", "previous_only"), ("ridge_seven", "previous_only"), ("ridge_seven", "ridge_six")]:
        a = dev[dev.model == candidate].set_index("seed")
        b = dev[dev.model == baseline].set_index("seed")
        pair = differences[candidate+"_minus_"+baseline]
        wins = int(((a.mae < b.mae) & (a.rmse < b.rmse)).sum())
        gates[candidate+"_vs_"+baseline] = {"seeds_both_metrics_better": wins, "minimum_gain": CONFIG["required_gain"],
            "numerical_gate_pass": bool(pair["mae_difference_first_minus_second"] <= -CONFIG["required_gain"] and pair["ci_95"][1] < 0 and wins >= 4)}
    recommendation = "ridge_six" if gates["ridge_six_vs_previous_only"]["numerical_gate_pass"] else "previous_only"
    dump(output / "selection.json", {"numerical_gates": gates, "provisional_candidate": recommendation,
         "rhr_evidence_gate": "NOT MET: compatible prior-attainment-adjusted UAE/Grade12 RHR evidence not established",
         "deployment_approved": False, "interpretation": "synthetic candidate only; real validation and new input-window contract required"})
    assert protected_hashes() == before, "Protected V1/iOS file changed"
    dump(output / "preservation_check.json", {"protected_files": len(before), "all_sha256_unchanged": True})
    manifest = {str(p.relative_to(output)): digest(p) for p in sorted(output.iterdir()) if p.is_file()}
    dump(output / "artifact_sha256.json", manifest)
    print(json.dumps({"output": str(output), "provisional_candidate": recommendation, "gates": gates, "protected_files_unchanged": len(before)}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=HERE / "results")
    run(parser.parse_args().output)
