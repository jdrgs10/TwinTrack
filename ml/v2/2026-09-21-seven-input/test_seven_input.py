"""Synthetic-only numerical and preservation regressions."""
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from pandas.testing import assert_frame_equal

import generator as g
import train as t
import evaluate as e


def test_deterministic_generator():
    a,_,_=g.generate(3001,500);b,_,_=g.generate(3001,500)
    assert_frame_equal(a,b)


def test_all_scenarios_finite_bounded_time_feasible():
    for scenario in g.SCENARIOS:
        frame,_,_=g.generate(3002,1000,scenario)
        assert np.isfinite(frame.to_numpy()).all()
        assert frame[g.TARGET].between(0,100).all()
        assert frame.apply(lambda row:t.eligible(row,g.FEATURES),axis=1).all()


def test_dependence_and_activity_overlap_not_deterministic():
    frame,_,_=g.generate(3003,5000)
    c=frame.corr()
    assert .2<c.loc["steps","exercise_minutes"]<.85
    assert c.loc["screen_time_minutes","study_minutes"]<-.1
    assert c.loc["screen_time_minutes","sleep_hours"]<-.2


def test_prespecified_nonlinear_target_not_unlimited_benefit():
    anchor=pd.DataFrame([g.CONFIG["reference"]])
    def delta(f,a,b):
        left=anchor.copy();right=anchor.copy();left[f]=a;right[f]=b
        return float((g.expected_score(right)-g.expected_score(left)).iloc[0])
    assert abs(delta("sleep_hours",9,10))<1e-10
    assert delta("study_minutes",60,90)>delta("study_minutes",240,270)>0
    assert abs(delta("exercise_minutes",90,120))<1e-10
    assert abs(delta("screen_time_minutes",30,60))<1e-10
    assert delta("screen_time_minutes",240,300)<0


def test_rhr_assumption_worlds_share_observed_inputs():
    central,_,_=g.generate(3004,500)
    for scenario in ["rhr_null","rhr_negative","rhr_positive"]:
        frame,_,_=g.generate(3004,500,scenario)
        assert_frame_equal(central[g.FEATURES],frame[g.FEATURES])
        assert not np.array_equal(central[g.TARGET],frame[g.TARGET])


def test_missingness_never_fabricates_values():
    frame,fitness,_=g.generate(3005,1000);masked=g.apply_missingness(frame,fitness,3006)
    assert masked[g.FEATURES].isna().sum().sum()>0
    for f in g.FEATURES:
        ix=masked[f].notna()
        np.testing.assert_array_equal(masked.loc[ix,f],frame.loc[ix,f])
    np.testing.assert_array_equal(masked[g.TARGET],frame[g.TARGET])


def test_training_only_scaling_and_unrounded_export():
    frame,_,_=g.generate(3007,500)
    train=frame.iloc[:350];holdout=frame.iloc[350:]
    model,_=t.fit(train,g.FEATURES,3007);params=t.export(model,g.FEATURES,len(train))
    np.testing.assert_allclose(model["standardscaler"].mean_,train[g.FEATURES].mean())
    np.testing.assert_allclose(model["standardscaler"].scale_,train[g.FEATURES].std(ddof=0))
    np.testing.assert_allclose(t.predict(params,holdout),model.predict(holdout[g.FEATURES]),atol=1e-10)


def test_numeric_contract_rejects_invalid_and_time_infeasible():
    for f in g.FEATURES:
        for bad in [None,np.nan,np.inf,-np.inf,g.CONFIG["bounds"][f][0]-1,g.CONFIG["bounds"][f][1]+1]:
            assert not t.eligible({**g.CONFIG["reference"],f:bad},g.FEATURES)
    assert not t.eligible({f:b[1] for f,b in g.CONFIG["bounds"].items()},g.FEATURES)


def test_final_pool_excludes_all_holdouts():
    data=pd.read_csv(g.HERE/"results/synthetic_v2.csv")
    assert len(data)==60000
    assert not data.duplicated(["synthetic_seed","synthetic_row"]).any()
    train=data[data.split=="train"]
    assert len(train)==45000
    p=json.loads((g.HERE/"results/new_ridge_seven_parameters.json").read_text())
    np.testing.assert_allclose(p["mean"],train[g.FEATURES].mean(),atol=1e-10)
    assert p["features"]==g.FEATURES
    assert not p["deployment_approved"]


def test_model_artifact_and_parameter_json_agree():
    data=pd.read_csv(g.HERE/"results/synthetic_final.csv")
    p=json.loads((g.HERE/"results/new_ridge_seven_parameters.json").read_text())
    model=joblib.load(g.HERE/"results/seven_input_model.joblib")
    np.testing.assert_allclose(t.predict(p,data),model.predict(data[g.FEATURES]),atol=1e-10)
    raw=data[g.FEATURES].to_numpy()@np.array(p["coefficients_raw"])+p["intercept_raw"]
    np.testing.assert_allclose(t.predict(p,data),raw,atol=1e-10)


def test_all_candidates_use_common_evaluation_rows():
    metrics=pd.read_csv(g.HERE/"results/comparison_metrics.csv")
    assert (metrics.n==g.CONFIG["final_rows"]).all()
    assert len(metrics)==(len(g.SCENARIOS)+1)*8*2
    assert (metrics.groupby(["scenario","output"]).model.nunique()==8).all()


def test_prior_artifacts_and_result_hashes_unchanged():
    results=g.HERE/"results"
    assert e.protected()==json.loads((results/"protected_sha256.json").read_text())
    for name,sha in json.loads((results/"artifact_sha256.json").read_text()).items():
        assert e.digest(results/name)==sha,name


def test_v1_golden_parity_preserved():
    parity=json.loads((g.HERE/"results/v1_parity.json").read_text())
    assert parity["total"]==parity["passed"]==21
    assert parity["max_error"]<parity["tolerance"]


def test_seed_stability_includes_opposite_rhr_assumptions():
    coefs=pd.read_csv(g.HERE/"results/multi_seed_coefficients.csv")
    for scenario in ["central","rhr_null","rhr_negative","rhr_positive"]:
        rows=coefs[(coefs.scenario==scenario)&(coefs.model=="new_ridge_seven")]
        assert rows.seed.nunique()==10
        assert len(rows)==70
