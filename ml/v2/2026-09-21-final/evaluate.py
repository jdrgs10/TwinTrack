"""Preserved numerical runner with explicit predeclared acceptance for tiny effects."""
import argparse
import importlib.util
import json
from pathlib import Path
import pandas as pd
from generator import HERE,ALIGNED,PREVIOUS,CONFIG

spec=importlib.util.spec_from_file_location('final_comparison_runner',PREVIOUS/'evaluate.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
original_candidates=runner.frozen_candidates
original_dump=runner.dump


def protected():
    recorded=json.loads((ALIGNED/'results/protected_sha256.json').read_text())
    paths=[runner.ROOT/p for p in recorded]
    paths += [p for p in ALIGNED.rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    paths += [runner.ROOT/'docs/V2_PRODUCTION_ALIGNMENT_DECISION.md']
    return {str(p.relative_to(runner.ROOT)):runner.digest(p) for p in sorted(set(paths))}


def candidates():
    values=original_candidates()
    for name,folder in [('previous_seven_pooled',PREVIOUS),('aligned_seven_pooled',ALIGNED)]:
        values[name]=json.loads((folder/'results/new_ridge_seven_parameters.json').read_text())
    return values


def dump(path,value):
    if path.name=='acceptance.json':
        coef=pd.read_csv(path.parent/'final_coefficients.csv').set_index('feature')
        stability=pd.read_csv(path.parent/'coefficient_stability.csv')
        central=stability[(stability.scenario=='central')&(stability.model=='new_ridge_seven')].set_index('feature')
        gates={}
        for f in ['steps','exercise_minutes']:
            extent=CONFIG['bounds'][f][1]-CONFIG['bounds'][f][0]
            gates[f]={'pooled_increment_small':abs(coef.loc[f,'effect'])<=CONFIG['activity_acceptance']['pooled_increment_max'],
                'all_seed_increments_small':max(abs(central.loc[f,'effect_min']),abs(central.loc[f,'effect_max']))<=CONFIG['activity_acceptance']['seed_increment_max'],
                'full_range_small':abs(coef.loc[f,'raw'])*extent<=CONFIG['activity_acceptance']['full_range_max']}
        rhr=abs(coef.loc['resting_heart_rate','effect'])<=.5 and value['weak_features']['resting_heart_rate']['all_seed_effects_small']
        numeric=all(all(v.values()) for v in gates.values()) and rhr and value['previous_strongest_every_seed'] and value['strong_direction_check'] and value['corner_guard_pass']
        value.update(activity_magnitude_gates=gates,rhr_small=rhr,numerical_gates_pass=numeric,
            input_contract_matches_current_app=False,proposed_contract_explicit=True,
            recommendation='APPROVE FOR IOS INTEGRATION' if numeric else 'DO NOT APPROVE',
            approval_scope='Offline design approval only, conditional on passing semantic/preservation tests and documented diagnosis. Current app remains V1; implementation/physical validation not performed.',
            reason='Sign instability is accepted only under the preregistered tiny-effect limits, not forced positivity. See final diagnosis and claim boundary.')
    if path.name=='artifact_sha256.json':
        original_dump(path.parent/'resolved_config.json',CONFIG)
        value={p.name:runner.digest(p) for p in sorted(path.parent.iterdir()) if p.is_file()}
    original_dump(path,value)


runner.protected=protected
runner.frozen_candidates=candidates
runner.dump=dump


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=HERE/'results')
    runner.run(parser.parse_args().output)
