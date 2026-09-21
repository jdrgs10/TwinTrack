"""Versioned dated previous-day reports; only seven numerical Ridge features."""
import copy
import importlib.util
import json
from datetime import date,timedelta
from pathlib import Path
import numpy as np

HERE=Path(__file__).resolve().parent
ALIGNED=HERE.parent/'2026-09-21-aligned'
PREVIOUS=HERE.parent/'2026-09-21-seven-input'
spec=importlib.util.spec_from_file_location('final_aligned_source',ALIGNED/'generator.py')
aligned=importlib.util.module_from_spec(spec);spec.loader.exec_module(aligned)
CONFIG=copy.deepcopy(aligned.CONFIG)
CONFIG.update(json.loads((HERE/'config.json').read_text()))
FEATURES=aligned.FEATURES
SIX=aligned.SIX
TARGET=aligned.TARGET
SCENARIOS=aligned.SCENARIOS
expected_score=aligned.expected_score
apply_missingness=aligned.apply_missingness


def generate(seed,n,scenario='central'):
    frame,fitness,meta=aligned.generate(seed,n,scenario)
    # Source-day reports, excluding overlap; latent usual-profile target stays unchanged.
    # Previous-day sleep is a simulator variable, NOT the differently windowed Ridge sleep.
    budget=(CONFIG['contract']['previous_day_minutes']-CONFIG['snapshot']['previous_day_reserved_minutes']
            -60*frame.synthetic_previous_day_sleep_hours-frame.exercise_minutes).clip(lower=0)
    totals=frame.study_minutes+frame.screen_time_minutes
    factor=np.minimum(1,budget/totals.replace(0,1))
    changed=factor<1
    for f in ['study_minutes','screen_time_minutes']:
        frame[f]=np.floor(frame[f]*factor)
    cutoff=date.fromisoformat(CONFIG['contract']['reference_date'])
    rng=np.random.default_rng(seed+200000)
    frame['cutoff_date']=cutoff.isoformat()
    frame['manual_day']=(cutoff-timedelta(days=1)).isoformat()
    frame['study_subject']=CONFIG['contract']['subject_key']
    frame['target_subject']=CONFIG['contract']['subject_key']
    frame['previous_subject']=CONFIG['contract']['subject_key']
    frame['target_date']=[(cutoff+timedelta(days=int(v))).isoformat() for v in rng.integers(1,8,n)]
    frame['previous_date']=[(cutoff-timedelta(days=int(v))).isoformat() for v in rng.integers(1,91,n)]
    frame['assessment_type']='individual_test'
    frame['target_is_next']=True
    frame['previous_is_latest']=True
    frame['previous_max_points']=100.0
    frame['previous_points']=frame.previous_score
    meta.update(observation_contract='dated_previous_day_manual_and_existing_health_windows',
                target_contract='next_same_subject_individual_assessment_1_to_7_days',
                manual_time_budget_adjusted_fraction=float(changed.mean()),
                horizon_effect='not estimated; no direct day-to-assessment effect assumed')
    return frame,fitness,meta
