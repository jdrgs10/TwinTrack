"""Train-only scaling/CV; explicit numeric and local-date eligibility contract."""
import importlib.util
from datetime import date,timedelta
import numpy as np
import pandas as pd
from generator import CONFIG,FEATURES,SIX,PREVIOUS

spec=importlib.util.spec_from_file_location('final_previous_train',PREVIOUS/'train.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
fit=base.fit
predict=base.predict


def export(model,features,training_rows):
    p=base.export(model,features,training_rows)
    p['task']={
        'target':'experimental percentage estimate for next individually graded same-subject quiz/test/exam',
        'horizon_local_days':[1,7], 'maximum_prior_age_local_days':90,
        'sleep':'accessible asleep union yesterday noon to min(now,today noon)',
        'steps':'previous completed local calendar day total',
        'exercise_minutes':'previous completed local calendar day Apple Exercise total',
        'resting_heart_rate':'latest finite positive sample within previous72 elapsed hours, timestamp retained',
        'study_minutes':'previous completed local calendar day outside-class study for selected subject, including academic screen use',
        'screen_time_minutes':'previous completed local calendar day recreational non-study active screen time, simultaneous devices counted once',
        'previous_score':'most recent prior individual assessment in SAME subject, 1–90 local days old, earned/max*100',
        'horizon_effect':'not learned; constant mean relationship across permitted horizons assumed',
        'real_world_accuracy':'UNVERIFIED'}
    p['units']={f:('hours' if f=='sleep_hours' else 'count' if f=='steps' else 'bpm' if f=='resting_heart_rate' else 'percentage points' if f=='previous_score' else 'minutes') for f in features}
    p['metadata_gate']='dated yesterday reports, selected/previous/study subject identity, next assessment 1–7 days, latest prior 1–90 days, valid percent scale; retain current HealthKit freshness'
    p['what_if']='override same captured source-period totals; no live-state writes or causal grade claim'
    p['deployment_approved']=False
    return p


def eligible(values,features):
    if not all(values.get(f) is not None and np.isfinite(values[f]) and CONFIG['bounds'][f][0]<=values[f]<=CONFIG['bounds'][f][1] for f in features):return False
    daily=['study_minutes','screen_time_minutes','exercise_minutes']
    return not set(daily).issubset(features) or sum(values[f] for f in daily)<=1440


def metadata_eligible(meta,values,cutoff):
    """Local calendar dates supplied by app; no additional model features or identifiers."""
    try:
        manual=date.fromisoformat(meta['manual_day'])
        target=date.fromisoformat(meta['target_date'])
        previous=date.fromisoformat(meta['previous_date'])
        if date.fromisoformat(meta['cutoff_date'])!=cutoff:return False
        subject=meta['target_subject'].strip()
        if not subject or meta['study_subject']!=subject or meta['previous_subject']!=subject:return False
        if manual!=cutoff-timedelta(days=1) or not 1<=(target-cutoff).days<=7 or not 1<=(cutoff-previous).days<=90:return False
        if meta['assessment_type'] not in ['individual_quiz','individual_test','individual_exam']:return False
        if not meta['target_is_next'] or not meta['previous_is_latest']:return False
        earned,maximum=float(meta['previous_points']),float(meta['previous_max_points'])
        if not np.isfinite(earned) or not np.isfinite(maximum) or maximum<=0 or not 0<=earned<=maximum:return False
        return abs(values['previous_score']-100*earned/maximum)<=1e-9
    except (KeyError,ValueError,TypeError,AttributeError):return False


def checked_predict(params,values):
    # Numerical helper only. Production eligibility must ALSO call metadata/freshness gates.
    if not eligible(values,params['features']):raise ValueError('Missing/nonfinite/out-of-support input')
    raw=float(predict(params,pd.DataFrame([values]))[0])
    return raw,float(np.clip(raw,0,100))
