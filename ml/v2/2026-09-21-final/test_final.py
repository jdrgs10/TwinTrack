import copy
import json
from datetime import date,timedelta
import numpy as np
import pandas as pd
import pytest
import generator as g
import train as t
import evaluate as e


def example():
    frame,_,_=g.generate(5101,10)
    row=frame.iloc[0].to_dict()
    return row,date.fromisoformat(row['cutoff_date'])


def test_predeclared_seven_features_and_no_target_metadata_as_predictors():
    assert g.FEATURES==['sleep_hours','steps','exercise_minutes','resting_heart_rate','study_minutes','screen_time_minutes','previous_score']
    assert len(g.FEATURES)==7


def test_dated_generation_reproducible_and_all_scenarios_eligible():
    a,_,_=g.generate(5102,100);b,_,_=g.generate(5102,100)
    pd.testing.assert_frame_equal(a,b)
    cutoff=date(2026,9,21)
    for scenario in g.SCENARIOS:
        frame,_,_=g.generate(5103,100,scenario)
        assert frame.apply(lambda row:t.eligible(row,g.FEATURES) and t.metadata_eligible(row,row,cutoff),axis=1).all()
        used=60*frame.synthetic_previous_day_sleep_hours+frame.exercise_minutes+frame.study_minutes+frame.screen_time_minutes
        assert (used<=1440-g.CONFIG['snapshot']['previous_day_reserved_minutes']+1e-9).all()


@pytest.mark.parametrize('days,valid',[(0,False),(1,True),(7,True),(8,False),(-1,False)])
def test_target_horizon(days,valid):
    row,cutoff=example();row['target_date']=(cutoff+timedelta(days=days)).isoformat()
    assert t.metadata_eligible(row,row,cutoff)==valid


@pytest.mark.parametrize('days,valid',[(0,False),(1,True),(90,True),(91,False),(-1,False)])
def test_prior_age(days,valid):
    row,cutoff=example();row['previous_date']=(cutoff-timedelta(days=days)).isoformat()
    assert t.metadata_eligible(row,row,cutoff)==valid


def test_subject_metadata_missing_legacy_and_not_next_are_rejected():
    row,cutoff=example()
    for key,value in [('previous_subject','different'),('study_subject','different'),('target_subject',''),('assessment_type','group_project'),('target_is_next',False),('previous_is_latest',False),('previous_date','')]:
        assert not t.metadata_eligible({**row,key:value},row,cutoff)
    for key in ['manual_day','study_subject','previous_date','target_date']:
        legacy=copy.copy(row);del legacy[key]
        assert not t.metadata_eligible(legacy,row,cutoff)


def test_manual_day_and_cutoff_expire_without_relabelling():
    row,cutoff=example()
    assert not t.metadata_eligible(row,row,cutoff+timedelta(days=1))
    assert not t.metadata_eligible({**row,'manual_day':cutoff.isoformat()},row,cutoff)


def test_previous_score_normalization_and_bad_denominators():
    row,cutoff=example();row['previous_score']=80;row['previous_points']=40;row['previous_max_points']=50
    assert t.metadata_eligible(row,row,cutoff)
    for maximum in [0,-1,np.nan,np.inf]:assert not t.metadata_eligible({**row,'previous_max_points':maximum},row,cutoff)
    assert not t.metadata_eligible({**row,'previous_points':60},row,cutoff)


def test_unchanged_latent_signal_and_only_manual_observations_rebalanced():
    old,_,_=g.aligned.generate(5104,300);new,_,_=g.generate(5104,300)
    for f in g.FEATURES[:4]+['previous_score',g.TARGET]:np.testing.assert_array_equal(old[f],new[f])
    assert (new.study_minutes<=old.study_minutes).all() and (new.screen_time_minutes<=old.screen_time_minutes).all()


def test_missing_and_zero_distinct_and_bounds_reject_not_clip():
    values=copy.copy(g.CONFIG['reference'])
    for f in g.FEATURES:
        for bad in [None,np.nan,np.inf,g.CONFIG['bounds'][f][1]+1,-1]:assert not t.eligible({**values,f:bad},g.FEATURES)
    assert t.eligible({**values,'steps':0,'exercise_minutes':0,'study_minutes':0,'screen_time_minutes':0},g.FEATURES)
    assert not t.eligible({**values,'resting_heart_rate':0},g.FEATURES)


def test_results_export_pool_metadata_and_preservation():
    import joblib
    folder=g.HERE/'results';params=json.loads((folder/'new_ridge_seven_parameters.json').read_text())
    data=pd.read_csv(folder/'synthetic_v2.csv');pool=data[data.split=='train']
    assert len(pool)==45000 and len(data)==60000
    assert params['features']==g.FEATURES and params['task']['horizon_local_days']==[1,7]
    np.testing.assert_allclose(params['mean'],pool[g.FEATURES].mean(),atol=1e-10)
    frame=pd.read_csv(folder/'synthetic_final.csv')
    model=joblib.load(folder/'seven_input_model.joblib')
    np.testing.assert_allclose(t.predict(params,frame),model.predict(frame[g.FEATURES]),atol=1e-10)
    np.testing.assert_allclose(t.predict(params,frame),frame[g.FEATURES].to_numpy()@params['coefficients_raw']+params['intercept_raw'],atol=1e-10)
    assert e.protected()==json.loads((folder/'protected_sha256.json').read_text())
    for name,sha in json.loads((folder/'artifact_sha256.json').read_text()).items():assert e.runner.digest(folder/name)==sha
    assert json.loads((folder/'v1_parity.json').read_text())['passed']==21


def test_results_what_if_changes_same_total_and_remains_read_only():
    p=json.loads((g.HERE/'results/new_ridge_seven_parameters.json').read_text());base=copy.copy(g.CONFIG['reference'])
    for f in g.FEATURES:
        changed={**base,f:base[f]+g.CONFIG['what_if_steps'][f]}
        raw0,_=t.checked_predict(p,base);raw1,_=t.checked_predict(p,changed)
        assert abs((raw1-raw0)-p['coefficients_raw'][g.FEATURES.index(f)]*g.CONFIG['what_if_steps'][f])<1e-10
    assert base==g.CONFIG['reference']


def test_results_all_models_common_rows_and_every_seed_included():
    folder=g.HERE/'results';m=pd.read_csv(folder/'comparison_metrics.csv')
    assert len(m)==20*10*2 and (m.n==4000).all()
    assert (m.groupby(['scenario','output']).model.nunique()==10).all()
    c=pd.read_csv(folder/'multi_seed_coefficients.csv')
    for scenario in ['central','rhr_null','rhr_negative','rhr_positive']:
        rows=c[(c.scenario==scenario)&(c.model=='new_ridge_seven')]
        assert set(rows.seed)==set(g.CONFIG['seeds']) and len(rows)==70
