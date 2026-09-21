"""Verify approved artifact hashes, derive Swift constants and NEW Python golden fixtures."""
from pathlib import Path
import hashlib,json,itertools
import numpy as np
import pandas as pd
import joblib

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
SOURCE=HERE.parent/'2026-09-21-final/results'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for name,expected in json.loads((SOURCE/'artifact_sha256.json').read_text()).items():
    assert sha(SOURCE/name)==expected,name
p=json.loads((SOURCE/'new_ridge_seven_parameters.json').read_text())
assert p['model_version']=='2.0-final.1' and p['alpha']==.1 and len(p['features'])==7
assert p['features']==['sleep_hours','steps','exercise_minutes','resting_heart_rate','study_minutes','screen_time_minutes','previous_score']
assert p['output_clamp']==[0,100]
model=joblib.load(SOURCE/'seven_input_model.joblib')
profiles=[]
def add(name,values,allowed=True):
    frame=pd.DataFrame([values],columns=p['features'])
    expected=float(model.predict(frame)[0])
    manual=float(((frame.to_numpy()[0]-p['mean'])/p['scale'])@p['coefficients_standardized']+p['intercept_standardized'])
    assert abs(expected-manual)<1e-10
    profiles.append(dict(name=name,inputs=values,expected_raw=expected,expected_clamped=float(np.clip(expected,0,100)),allowed=allowed))
data=pd.read_csv(SOURCE/'synthetic_final.csv')
for i,row in data.head(25).iterrows():add(f'ordinary_{i}',{f:float(row[f]) for f in p['features']})
reference=json.loads((SOURCE/'resolved_config.json').read_text())['reference']
for f in p['features']:
    for v in p['bounds'][f]:add(f'{f}_boundary_{v}',{**reference,f:v})
for i,bits in enumerate(itertools.product([0,1],repeat=7)):
    add(f'corner_{i}',{f:p['bounds'][f][b] for f,b in zip(p['features'],bits)})
for f,delta in json.loads((SOURCE/'resolved_config.json').read_text())['increments'].items():
    add(f'what_if_{f}',{**reference,f:reference[f]+delta})
# Output-clamp mechanics only: these are deliberately ineligible production inputs.
add('arithmetic_clamp_low',{**reference,'previous_score':-1000},False)
add('arithmetic_clamp_high',{**reference,'previous_score':1000},False)
gold=dict(model_version=p['model_version'],parameter_sha256=sha(SOURCE/'new_ridge_seven_parameters.json'),tolerance=1e-6,feature_order=p['features'],profiles=profiles)
(HERE/'golden_v2_final_1.json').write_text(json.dumps(gold,indent=2,allow_nan=False)+'\n')
(HERE/'source_hashes.json').write_text(json.dumps({name:sha(SOURCE/name) for name in ['new_ridge_seven_parameters.json','seven_input_model.joblib','artifact_sha256.json']},indent=2)+'\n')
swift='''// Generated from approved 2.0-final.1 JSON; regenerate with ml/v2/2026-09-21-ios-parity/export_ios.py.
// SHA-256 of parameter JSON: '''+gold['parameter_sha256']+'''
enum TwinTrackModel {
    static let version = "2.0-final.1"
    static let name = "TwinTrack Ridge V2"
    static let provenance = "explicitRun.v2.2.0-final.1"
'''
for dest,source in [('mean','mean'),('scale','scale'),('coefficient','coefficients_standardized')]:
    swift+=f'    static let {dest}: [Double] = {json.dumps(p[source])}\n'
swift+=f'    static let intercept: Double = {repr(p["intercept_standardized"])}\n'
swift+='    static let bounds: [ClosedRange<Double>] = ['+', '.join(f'{float(p["bounds"][f][0])}...{float(p["bounds"][f][1])}' for f in p['features'])+']\n'
swift+='''
    static func predictRaw(_ profile: TwinTrackProfile) -> Double {
        var result = intercept
        let values = profile.orderedValues
        for feature in TwinTrackFeature.allCases {
            let i = feature.rawValue
            result += coefficient[i] * ((values[i] - mean[i]) / scale[i])
        }
        return result
    }

    static func predict(_ profile: TwinTrackProfile) -> Double {
        min(100, max(0, predictRaw(profile)))
    }
}
'''
patch='*** Begin Patch\n*** Add File: '+str(ROOT/'ios/twintrack/twintrack/TwinTrackModelV2.swift')+'\n'
patch+=''.join('+'+line+'\n' for line in swift.splitlines())
patch+='*** Add File: '+str(ROOT/'ios/twintrack/twintrackTests/golden_v2_final_1.json')+'\n'
patch+=''.join('+'+line+'\n' for line in (HERE/'golden_v2_final_1.json').read_text().splitlines())
patch+='*** End Patch\n'
Path('/private/tmp/twintrack-v2-parameters.patch').write_text(patch)
print(f'Verified approved hashes; generated {len(profiles)} profiles and Swift patch.')
