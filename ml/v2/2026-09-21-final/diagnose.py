"""Prespecified simulator diagnostics; variants NEVER select the final artifact."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from generator import HERE,CONFIG,FEATURES,aligned


def diagnostics(output):
    if output.exists():raise FileExistsError('No diagnostic overwrite')
    output.mkdir(parents=True)
    source=copy.deepcopy(aligned.CONFIG)
    latent=copy.deepcopy(aligned.latent_generator.CONFIG)
    rows=[];design=[];signal=[]
    variants=['central','no_shared_day_coupling','activity_observation_noise_off','no_outcome_noise','no_direct_activity_target','latent_oracle']
    for variant in variants+['large_sample']:
        aligned.CONFIG=copy.deepcopy(source)
        aligned.latent_generator.CONFIG=copy.deepcopy(latent)
        if variant=='no_shared_day_coupling':aligned.CONFIG['snapshot']['step_exercise_loading']=0
        if variant=='activity_observation_noise_off':
            for k in ['activity_log_sd','exercise_zero_probability','steps_zero_probability','step_day_sd']:aligned.CONFIG['snapshot'][k]=0
        if variant=='no_outcome_noise':aligned.latent_generator.CONFIG['generator']['target']['outcome_noise_sd']=0
        if variant=='no_direct_activity_target':
            for f in ['steps','exercise_minutes']:aligned.latent_generator.CONFIG['generator']['target']['habit_coefficients'][f]=0
        for seed in CONFIG['diagnostics']['seeds']:
            n=CONFIG['diagnostics']['large_rows'] if variant=='large_sample' else CONFIG['diagnostics']['rows']
            generate=aligned.latent_generator.generate if variant=='latent_oracle' else aligned.generate
            frame,_,_=generate(seed,n)
            train,_=train_test_split(frame,test_size=.25,random_state=seed)
            alphas=CONFIG['diagnostics']['fixed_alphas'] if variant=='central' else [100]
            feature_sets={'seven':FEATURES}
            if variant=='central':
                feature_sets.update(without_steps=[f for f in FEATURES if f!='steps'],without_exercise=[f for f in FEATURES if f!='exercise_minutes'])
            for name,fs in feature_sets.items():
                for alpha in alphas:
                    model=make_pipeline(StandardScaler(),Ridge(alpha=alpha)).fit(train[fs],train.assessment_score)
                    raw=model['ridge'].coef_/model['standardscaler'].scale_
                    for f,b in zip(fs,raw):rows.append(dict(variant=variant,seed=seed,n_train=len(train),features=name,alpha=alpha,feature=f,raw=b,effect=b*CONFIG['increments'][f]))
            if variant=='central':
                x=train[FEATURES].to_numpy();z=(x-x.mean(axis=0))/x.std(axis=0)
                for f in ['steps','exercise_minutes']:
                    i=FEATURES.index(f);others=np.delete(z,i,axis=1)
                    residual=z[:,i]-others@np.linalg.lstsq(others,z[:,i],rcond=None)[0]
                    yr=train.assessment_score.to_numpy();yr=yr-yr.mean()
                    yr=yr-others@np.linalg.lstsq(others,yr,rcond=None)[0]
                    design.append(dict(seed=seed,feature=f,steps_exercise_correlation=train.steps.corr(train.exercise_minutes),
                        vif=1/np.var(residual),raw_condition_number=np.linalg.cond(x-x.mean(axis=0)),scaled_condition_number=np.linalg.cond(z),
                        partial_correlation=np.corrcoef(residual,yr)[0,1],residual_feature_sd=float(x[:,i].std()*residual.std())))
                oracle,_,_=aligned.latent_generator.generate(seed,n)
                coeff=latent['generator']['target']['habit_coefficients']
                signal.append(dict(seed=seed,steps_term_sd=float((oracle.steps*coeff['steps']).std()),
                    exercise_term_sd=float((oracle.exercise_minutes.clip(upper=60)*coeff['exercise_minutes']).std()),
                    noise_sd=latent['generator']['target']['outcome_noise_sd']))
        print('Diagnostic complete:',variant,flush=True)
    aligned.CONFIG=source;aligned.latent_generator.CONFIG=latent
    values=pd.DataFrame(rows);values.to_csv(output/'coefficients.csv',index=False)
    summary=values.groupby(['variant','features','alpha','feature']).agg(mean_raw=('raw','mean'),min_raw=('raw','min'),max_raw=('raw','max'),
        mean_effect=('effect','mean'),min_effect=('effect','min'),max_effect=('effect','max'),positive_fraction=('raw',lambda v:float((v>0).mean())))
    summary.to_csv(output/'summary.csv')
    pd.DataFrame(design).to_csv(output/'design.csv',index=False)
    pd.DataFrame(signal).to_csv(output/'signal.csv',index=False)
    sources={n:hashlib.sha256((HERE/n).read_bytes()).hexdigest() for n in ['PROTOCOL.md','config.json','diagnose.py']}
    (output/'source_sha256.json').write_text(json.dumps(sources,indent=2)+'\n')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=HERE/'diagnostics')
    diagnostics(parser.parse_args().output)
