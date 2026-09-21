import json
from datetime import date,datetime,timedelta,timezone
from pathlib import Path
from zoneinfo import ZoneInfo

import numpy as np
import pandas as pd

import generator as g
import train as t
import evaluate as e
import rhr_trend as r


def history():
    end=date(2026,9,20)
    values={end-timedelta(days=i):70+(i%7)-3 for i in range(33)}
    for i in range(5): values[end-timedelta(days=i)]=70
    return end,values


def test_source_windows_and_partial_sleep_change_observations_not_target():
    early,_,_=g.generate(4101,300,"sleep_early");complete,_,_=g.generate(4101,300,"sleep_complete")
    assert (early.sleep_hours<=complete.sleep_hours).all()
    assert (early.sleep_hours<complete.sleep_hours).any()
    np.testing.assert_array_equal(early[g.TARGET],complete[g.TARGET])
    assert early.synthetic_rhr_age_hours.between(0,72).all()


def test_generation_is_reproducible_and_all_scenarios_bounded():
    a,_,_=g.generate(4102,300);b,_,_=g.generate(4102,300)
    pd.testing.assert_frame_equal(a,b)
    for scenario in g.SCENARIOS:
        frame,_,_=g.generate(4102,300,scenario)
        assert frame[g.FEATURES+[g.TARGET]].notna().all().all()
        assert frame.apply(lambda row:t.eligible(row,g.FEATURES),axis=1).all()
        assert (frame.study_minutes%1==0).all()
        assert (frame.steps%1==0).all()


def test_missing_is_not_zero_but_real_zero_activity_is_supported():
    frame,fitness,_=g.generate(4103,1000)
    assert (frame.steps==0).any() and (frame.exercise_minutes==0).any()
    masked=g.apply_missingness(frame,fitness,4104)
    assert masked[g.FEATURES].isna().any().any()
    assert not t.eligible({**g.CONFIG['reference'],'steps':None},g.FEATURES)
    assert t.eligible({**g.CONFIG['reference'],'steps':0,'exercise_minutes':0},g.FEATURES)


def test_snapshot_periods_are_not_summed_as_one_day():
    values={f:b[1] for f,b in g.CONFIG['bounds'].items()}
    assert t.eligible(values,g.FEATURES)
    for f in g.FEATURES:
        for bad in [np.nan,np.inf,-1,g.CONFIG['bounds'][f][1]+1]:
            assert not t.eligible({**values,f:bad},g.FEATURES)


def test_no_false_persistence_from_single_outlier():
    end,v=history();v[end]=100
    assert r.compare(v,end)['state']=='Noticeably different from recent baseline'


def test_persistent_same_side_and_recovery_requires_two_calendar_days():
    end,v=history()
    for i in [1,2,3]:v[end-timedelta(days=i)]=100
    assert r.compare(v,end)['state']=='Persistently different from recent baseline'
    v[end-timedelta(days=1)]=70
    assert r.compare(v,end)['state']=='Within recent usual range'


def test_persistent_lower_is_nondiagnostic():
    end,v=history()
    for i in [0,1,2]:v[end-timedelta(days=i)]=40
    result=r.compare(v,end)
    assert result['direction']=='lower'
    assert result['state']=='Persistently different from recent baseline'
    assert 'emergency' not in str(result).lower()


def test_missing_day_never_carried_forward():
    end,v=history();del v[end]
    assert r.compare(v,end)['state']=='Not enough recent data'
    end,v=history();del v[end-timedelta(days=1)];del v[end-timedelta(days=2)]
    assert r.compare(v,end)['state']=='Not enough recent data'


def test_insufficient_and_zero_variance_baseline():
    end,v=history()
    for i in range(5,13):del v[end-timedelta(days=i)]
    assert r.compare(v,end)['state']=='Not enough recent data'
    end,v=history();v={d:70 for d in v};v[end]=90
    assert r.compare(v,end)['state']=='Not enough recent data'


def test_recent_outliers_are_excluded_from_baseline():
    end,v=history();before=r.compare(v,end)
    for i in range(5):v[end-timedelta(days=i)]=100
    after=r.compare(v,end)
    assert before['baseline_median']==after['baseline_median']
    assert before['robust_scale']==after['robust_scale']


def test_mixed_direction_not_persistent_same_side():
    end,v=history();v[end]=100;v[end-timedelta(days=1)]=40
    assert r.compare(v,end)['direction']=='varied'
    assert r.compare(v,end)['state']=='Noticeably different from recent baseline'


def test_one_sample_and_repeated_refresh_are_one_day():
    zone=ZoneInfo('Asia/Dubai');now=datetime(2026,9,21,12,tzinfo=zone);sample=(now-timedelta(days=1),70)
    days=r.daily_readings([sample]*30,now,zone)
    assert len(days)==1
    assert r.assess([sample]*30,now,zone)['state']=='Not enough recent data'


def test_daily_latest_revisions_invalid_samples_and_today_excluded():
    zone=ZoneInfo('Asia/Dubai');now=datetime(2026,9,21,12,tzinfo=zone)
    earlier=now-timedelta(days=1,hours=3);later=now-timedelta(days=1)
    samples=[(earlier,65),(later,72),(later,73),(later+timedelta(hours=1),np.nan),(now,110)]
    assert list(r.daily_readings(samples,now,zone).values())==[73]


def test_calendar_bucketing_across_dst():
    zone=ZoneInfo('America/New_York');now=datetime(2026,11,2,12,tzinfo=zone)
    # Both repeated 01:30 timestamps belong to ONE local day; later UTC sample wins.
    samples=[(datetime(2026,11,1,5,30,tzinfo=timezone.utc),66),(datetime(2026,11,1,6,30,tzinfo=timezone.utc),68)]
    assert r.daily_readings(samples,now,zone)=={date(2026,11,1):68}
    local_samples=[(stamp.astimezone(zone),bpm) for stamp,bpm in reversed(samples)]
    assert r.daily_readings(local_samples,now,zone)=={date(2026,11,1):68}


def test_weekly_coverage_cannot_be_replaced_by_total_count():
    end,v=history()
    for i in range(26,30): del v[end-timedelta(days=i)]
    assert sum((end-d).days>=5 for d in v)==24
    assert r.compare(v,end)['reason']=='baseline coverage too concentrated'


def test_exact_range_boundary_is_inside_and_one_missing_recent_day_allowed():
    end,v=history();base=r.compare(v,end)
    v[end]=base['upper'];v[end-timedelta(days=1)]=base['lower']
    del v[end-timedelta(days=3)]
    assert r.compare(v,end)['state']=='Within recent usual range'


def test_flags_expire_and_timezone_changes_rebucket_timestamps():
    end,v=history();v[end]=100
    for step in range(1,6):v[end+timedelta(days=step)]=70
    assert r.compare(v,end+timedelta(days=5))['state']=='Within recent usual range'
    now=datetime(2026,9,21,12,tzinfo=timezone.utc)
    sample=(datetime(2026,9,20,23,tzinfo=timezone.utc),70)
    assert len(r.daily_readings([sample],now,ZoneInfo('UTC')))==1
    assert r.daily_readings([sample],now,ZoneInfo('Asia/Dubai'))=={}


def test_export_roundtrip_raw_formula_and_common_evaluation_rows():
    import joblib
    folder=g.HERE/'results';data=pd.read_csv(folder/'synthetic_final.csv')
    p=json.loads((folder/'new_ridge_seven_parameters.json').read_text())
    model=joblib.load(folder/'seven_input_model.joblib')
    np.testing.assert_allclose(t.predict(p,data),model.predict(data[g.FEATURES]),atol=1e-10)
    np.testing.assert_allclose(t.predict(p,data),data[g.FEATURES].to_numpy()@p['coefficients_raw']+p['intercept_raw'],atol=1e-10)
    metrics=pd.read_csv(folder/'comparison_metrics.csv')
    assert (metrics.n==4000).all()
    assert len(metrics)==(len(g.SCENARIOS)+1)*9*2
    assert (metrics.groupby(['scenario','output']).model.nunique()==9).all()
    assert all(t.checked_predict(p,g.CONFIG['reference']))


def test_missingness_preserves_every_observed_value_and_all_seeds_are_retained():
    frame,fitness,_=g.generate(4110,500);masked=g.apply_missingness(frame,fitness,4111)
    for f in g.FEATURES:
        valid=masked[f].notna();np.testing.assert_array_equal(masked.loc[valid,f],frame.loc[valid,f])
    coefs=pd.read_csv(g.HERE/'results/multi_seed_coefficients.csv')
    for scenario in ['central','rhr_null','rhr_negative','rhr_positive']:
        rows=coefs[(coefs.scenario==scenario)&(coefs.model=='new_ridge_seven')]
        assert set(rows.seed)==set(g.CONFIG['seeds']) and len(rows)==70


def test_result_artifacts_and_all_previous_work_preserved():
    folder=g.HERE/'results'
    assert e.protected()==json.loads((folder/'protected_sha256.json').read_text())
    for name,sha in json.loads((folder/'artifact_sha256.json').read_text()).items():
        assert e.previous.digest(folder/name)==sha
    p=json.loads((folder/'new_ridge_seven_parameters.json').read_text())
    assert p['features']==g.FEATURES and p['task']['prediction_horizon'] is None
    assert p['task']['study_minutes'].endswith('reporting period/date unknown')
    data=pd.read_csv(folder/'synthetic_v2.csv');train=data[data.split=='train']
    assert len(train)==45000 and len(data)==60000
    np.testing.assert_allclose(p['mean'],train[g.FEATURES].mean(),atol=1e-10)
    assert json.loads((folder/'v1_parity.json').read_text())['passed']==21
