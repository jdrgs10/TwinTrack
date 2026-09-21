"""Run the predeclared seven-input experiment into a NEW directory only."""
import argparse
import hashlib
import importlib.util
import itertools
import json
import platform
import subprocess
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import scipy
import sklearn
from sklearn.metrics import mean_absolute_error,mean_squared_error,r2_score
from sklearn.model_selection import train_test_split

from generator import HERE,CONFIG,FEATURES,SIX,TARGET,SCENARIOS,generate,expected_score,apply_missingness
from train import fit,export,predict,eligible,checked_predict

ROOT=HERE.parents[2]
OLD=HERE.parent/"2026-09-21"


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def clean(value):
    if isinstance(value,dict): return {str(k):clean(v) for k,v in value.items()}
    if isinstance(value,(list,tuple)): return [clean(v) for v in value]
    if isinstance(value,(np.bool_,)): return bool(value)
    if isinstance(value,(np.integer,)): return int(value)
    if isinstance(value,(float,np.floating)): return float(value) if np.isfinite(value) else None
    return value


def dump(path,value):
    path.write_text(json.dumps(clean(value),indent=2,allow_nan=False)+"\n")


def protected():
    old=json.loads((OLD/"results/protected_v1_ios_sha256.json").read_text())
    paths=[ROOT/p for p in old]
    paths += [p for p in OLD.rglob("*") if p.is_file() and "__pycache__" not in p.parts]
    paths += [ROOT/"docs/V2_MODEL_FINAL_DECISION.md",
        ROOT/".twintrack-local/research/NetHealth/NetHealth_Final_Report.md",
        ROOT/".twintrack-local/research/Dataset_Strategy/TwinTrack_Dataset_Strategy_2026-09-05.pdf"]
    return {str(p.relative_to(ROOT)):digest(p) for p in sorted(set(paths))}


def metrics(y,p):
    y,p=np.asarray(y),np.asarray(p)
    slope,intercept=np.polyfit(p,y,1) if np.std(p)>1e-10 else [np.nan,np.nan]
    return dict(n=len(y),mae=mean_absolute_error(y,p),rmse=np.sqrt(mean_squared_error(y,p)),r2=r2_score(y,p),
        bias=float(np.mean(p-y)),calibration_slope=slope,calibration_intercept=intercept)


def paired(y,a,b):
    delta=np.abs(a-y)-np.abs(b-y)
    rng=np.random.default_rng(CONFIG["bootstrap_seed"])
    values=[np.mean(delta[rng.integers(0,len(y),len(y))]) for _ in range(CONFIG["bootstrap_replicates"])]
    return dict(difference=float(delta.mean()),ci95=np.quantile(values,[.025,.975]).tolist(),replicates=len(values),scope="paired independent synthetic rows only")


def model_prediction(params,frame):
    return np.full(len(frame),params["constant"]) if "constant" in params else predict(params,frame)


def frozen_candidates():
    p=json.loads((ROOT/"ml/frozen_export/twintrack_model_params.json").read_text())
    v1=dict(features=p["feature_order"],mean=p["scaler"]["mean"],scale=p["scaler"]["scale"],
        coefficients_standardized=p["ridge"]["coef"],intercept_standardized=p["ridge"]["intercept"])
    return {"v1_frozen":v1,**{"old_"+name:json.loads((OLD/"results"/(name+"_candidate.json")).read_text())
        for name in ["previous_only","ridge_six","ridge_seven"]}}


def coefficient_rows(model,fs,seed,scenario):
    p=export(model,fs,0)
    return [dict(scenario=scenario,seed=seed,feature=f,standardized=z,raw=r,
        increment=CONFIG["increments"][f],effect=r*CONFIG["increments"][f])
        for f,z,r in zip(fs,p["coefficients_standardized"],p["coefficients_raw"])]


def run(output):
    if output.exists(): raise FileExistsError("Choose a new output directory; no result overwrite")
    output.mkdir(parents=True)
    before=protected()
    dump(output/"protected_sha256.json",before)
    dump(output/"environment.json",dict(python=platform.python_version(),numpy=np.__version__,scipy=scipy.__version__,pandas=pd.__version__,sklearn=sklearn.__version__,joblib=joblib.__version__,
        source_sha256={n:digest(HERE/n) for n in ["PROTOCOL.md","config.json","generator.py","train.py","evaluate.py"]}))
    feature_sets={"new_previous_only":["previous_score"],"new_ridge_six":SIX,"new_ridge_seven":FEATURES}
    training,devrows,cvrows,coefrows=[],[],[],[]
    all_data=[]
    for seed in CONFIG["seeds"]:
        frame,_,_=generate(seed,CONFIG["rows_per_seed"])
        train,holdout=train_test_split(frame,test_size=CONFIG["holdout_fraction"],random_state=seed)
        training.append(train)
        stored=frame.copy();stored.insert(0,"synthetic_row",np.arange(len(frame)));stored.insert(0,"synthetic_seed",seed)
        stored["split"]=np.where(frame.index.isin(train.index),"train","development_holdout");all_data.append(stored)
        for name,fs in feature_sets.items():
            model,cv=fit(train,fs,seed);params=export(model,fs,len(train))
            pp=model.predict(holdout[fs]);assert np.max(np.abs(pp-predict(params,holdout)))<1e-10
            cvrows.append(dict(seed=seed,model=name,scenario="central",alpha=float(model["ridge"].alpha),cv_mae=cv))
            devrows.append(dict(seed=seed,model=name,**metrics(holdout[TARGET],pp)))
            coefrows.extend(dict(model=name,**row) for row in coefficient_rows(model,fs,seed,"central"))
    pool=pd.concat(training,ignore_index=True)
    pd.concat(all_data,ignore_index=True).to_csv(output/"synthetic_v2.csv",index=False,float_format="%.17g")
    candidates=frozen_candidates();candidates["mean_only"]={"constant":float(pool[TARGET].mean())}
    for name,fs in feature_sets.items():
        model,cv=fit(pool,fs,CONFIG["pooled_cv_seed"]);params=export(model,fs,len(pool))
        candidates[name]=params
        dump(output/(name+"_parameters.json"),params)
        cvrows.append(dict(seed="pooled",model=name,scenario="central",alpha=float(model["ridge"].alpha),cv_mae=cv))
        if name=="new_ridge_seven":
            joblib.dump(model,output/"seven_input_model.joblib",compress=3)
            pooled_model=model
    print("Central fits and pooled export complete",flush=True)
    # Fit alternative RHR worlds solely as an uncertainty diagnostic, not selectable artifacts.
    for scenario in ["rhr_null","rhr_negative","rhr_positive"]:
        for seed in CONFIG["seeds"]:
            frame,_,_=generate(seed,CONFIG["rows_per_seed"],scenario)
            train,_=train_test_split(frame,test_size=CONFIG["holdout_fraction"],random_state=seed)
            model,cv=fit(train,FEATURES,seed)
            coefrows.extend(dict(model="new_ridge_seven",**row) for row in coefficient_rows(model,FEATURES,seed,scenario))
            cvrows.append(dict(seed=seed,model="new_ridge_seven",scenario=scenario,alpha=float(model["ridge"].alpha),cv_mae=cv))
    coefs=pd.DataFrame(coefrows);coefs.to_csv(output/"multi_seed_coefficients.csv",index=False)
    stability=coefs.groupby(["scenario","model","feature"])[["standardized","raw","effect"]].agg(["mean","std","min","max"])
    stability.columns=["_".join(c) for c in stability.columns]
    stability["positive_fraction"]=coefs.groupby(["scenario","model","feature"]).raw.apply(lambda s:float((s>0).mean()))
    stability["negative_fraction"]=coefs.groupby(["scenario","model","feature"]).raw.apply(lambda s:float((s<0).mean()))
    stability.to_csv(output/"coefficient_stability.csv")
    pd.DataFrame(devrows).to_csv(output/"development_metrics.csv",index=False)
    pd.DataFrame(cvrows).to_csv(output/"training_cv.csv",index=False)
    print("Ten-seed stability and RHR assumption refits complete",flush=True)
    rows,calibration,meta=[],[],[]
    final_predictions={}
    for scenario in SCENARIOS:
        frame,fitness,description=generate(CONFIG["final_seed"],CONFIG["final_rows"],scenario);meta.append(description)
        for name,params in candidates.items():
            pp=model_prediction(params,frame)
            for kind,pred in [("raw",pp),("clamped",np.clip(pp,0,100))]:
                rows.append(dict(scenario=scenario,model=name,output=kind,**metrics(frame[TARGET],pred)))
            if scenario=="central":
                final_predictions[name]=pp
                bins=pd.qcut(pd.Series(pp).rank(method="first"),10,labels=False)
                for b in range(10):
                    ix=np.asarray(bins==b)
                    calibration.append(dict(model=name,bin=b+1,n=int(ix.sum()),prediction_mean=float(pp[ix].mean()),actual_mean=float(frame[TARGET][ix].mean())))
        if scenario=="central":
            final=frame.copy();final_fitness=fitness
            frame.to_csv(output/"synthetic_final.csv",index_label="synthetic_row",float_format="%.17g")
            dump(output/"synthetic_summary.json",dict(statistics=pd.concat(all_data)[FEATURES+[TARGET]].describe().to_dict(),correlations=pd.concat(all_data)[FEATURES+[TARGET]].corr().to_dict()))
    # New independent draws from the previous generator, not its already-used final test.
    spec=importlib.util.spec_from_file_location("previous_v2_experiment",OLD/"experiment.py")
    old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)
    old_frame,_,_=old.generate(CONFIG["old_generator_seed"],CONFIG["final_rows"])
    for name,params in candidates.items():
        pp=model_prediction(params,old_frame)
        for kind,pred in [("raw",pp),("clamped",np.clip(pp,0,100))]:
            rows.append(dict(scenario="previous_generator_transport",model=name,output=kind,**metrics(old_frame[TARGET],pred)))
    pd.DataFrame(rows).to_csv(output/"comparison_metrics.csv",index=False)
    pd.DataFrame(calibration).to_csv(output/"calibration.csv",index=False)
    dump(output/"scenario_clipping.json",meta)
    dump(output/"paired_mae.json",{name:paired(final[TARGET].to_numpy(),final_predictions["new_ridge_seven"],final_predictions[name])
        for name in ["new_previous_only","new_ridge_six","old_previous_only","old_ridge_six","v1_frozen"]})
    masked=apply_missingness(final,final_fitness,CONFIG["missingness_seed"])
    masked.to_csv(output/"synthetic_missingness.csv",index_label="synthetic_row",float_format="%.17g")
    coverage=[]
    for name,params in candidates.items():
        for cohort in ["common_seven","model_eligible"]:
            required=FEATURES if cohort=="common_seven" else params.get("features",[])
            ix=masked[required].notna().all(axis=1)
            coverage.append(dict(model=name,cohort=cohort,coverage=float(ix.mean()),**metrics(final.loc[ix,TARGET],model_prediction(params,final.loc[ix]))))
    pd.DataFrame(coverage).to_csv(output/"missingness_coverage.csv",index=False)
    new=candidates["new_ridge_seven"]
    assert np.max(np.abs(predict(new,final)-pooled_model.predict(final[FEATURES])))<1e-10
    restored=joblib.load(output/"seven_input_model.joblib")
    assert np.max(np.abs(restored.predict(final[FEATURES])-predict(new,final)))<1e-10
    final_coefs=[dict(feature=f,mean=m,scale=s,standardized=z,raw=r,increment=CONFIG["increments"][f],effect=r*CONFIG["increments"][f])
        for f,m,s,z,r in zip(FEATURES,new["mean"],new["scale"],new["coefficients_standardized"],new["coefficients_raw"])]
    pd.DataFrame(final_coefs).to_csv(output/"final_coefficients.csv",index=False)
    sensitivities=[]
    for f,increment in CONFIG["increments"].items():
        changed=final.copy();changed[f]+=increment
        ix=changed.apply(lambda row:eligible(row,FEATURES),axis=1)
        base=predict(new,final.loc[ix]);altered=predict(new,changed.loc[ix]);delta=altered-base
        truth=(expected_score(changed.loc[ix])-expected_score(final.loc[ix])).to_numpy()
        sensitivities.append(dict(feature=f,increment=increment,feasible_profiles=int(ix.sum()),raw_delta_mean=delta.mean(),raw_delta_min=delta.min(),raw_delta_max=delta.max(),
            clamped_delta_min=(np.clip(altered,0,100)-np.clip(base,0,100)).min(),clamped_delta_max=(np.clip(altered,0,100)-np.clip(base,0,100)).max(),
            hypothetical_generator_delta_min=truth.min(),hypothetical_generator_delta_max=truth.max(),
            surrogate_delta_mae=float(np.abs(delta-truth).mean())))
    pd.DataFrame(sensitivities).to_csv(output/"what_if_sensitivities.csv",index=False)
    corners=pd.DataFrame([{f:CONFIG["bounds"][f][b] for f,b in zip(FEATURES,bits)} for bits in itertools.product([0,1],repeat=7)])
    extremes=[]
    for name,params in candidates.items():
        pp=model_prediction(params,corners)
        for i,raw in enumerate(pp):
            values=corners.iloc[i].to_dict()
            extremes.append(dict(model=name,corner=i,permitted=eligible(values,params.get("features",[])),raw_prediction=raw,clamped_prediction=np.clip(raw,0,100),**values))
    pd.DataFrame(extremes).to_csv(output/"extreme_profiles.csv",index=False)
    fixtures=[]
    for f in FEATURES:
        for value in CONFIG["bounds"][f]:
            values={**CONFIG["reference"],f:value}
            try:
                raw,clamped=checked_predict(new,values);fixtures.append(dict(inputs=values,raw=raw,clamped=clamped))
            except ValueError:
                fixtures.append(dict(inputs=values,expected="reject_time_budget"))
    dump(output/"python_export_fixtures.json",dict(tolerance=1e-10,scope="Python checks; not independently audited Swift golden profiles",profiles=fixtures))
    # V1 parity directly from immutable JSON; no old pickle load needed in this experiment.
    gold=json.loads((ROOT/"ml/frozen_export/golden_profiles.json").read_text());errors=[]
    for p in gold["profiles"]:
        raw=float(predict(candidates["v1_frozen"],pd.DataFrame([p["inputs"]]))[0])
        errors.append(max(abs(raw-p["expected_raw"]),abs(np.clip(raw,0,100)-p["expected_clamped"])))
    dump(output/"v1_parity.json",dict(total=len(errors),passed=sum(e<=gold["tolerance"] for e in errors),max_error=max(errors),tolerance=gold["tolerance"],scope="Python frozen JSON only"))
    s=stability.loc[("central","new_ridge_seven")]
    central=coefs[(coefs.scenario=="central")&(coefs.model=="new_ridge_seven")]
    strongest=central.loc[central.groupby("seed").standardized.apply(lambda x:x.abs().idxmax()),"feature"]
    weak={f:dict(sign_consistent=bool(max(s.loc[f,"positive_fraction"],s.loc[f,"negative_fraction"])>=CONFIG["acceptance"]["sign_fraction"]),
        all_seed_effects_small=bool(max(abs(s.loc[f,"effect_min"]),abs(s.loc[f,"effect_max"]))<=CONFIG["acceptance"]["weak_increment_max"])) for f in ["steps","exercise_minutes","resting_heart_rate"]}
    own=pd.DataFrame(extremes);own=own[(own.model=="new_ridge_seven")&own.permitted]
    dump(output/"acceptance.json",dict(previous_strongest_every_seed=bool((strongest=="previous_score").all()),
        strong_direction_check=bool(s.loc["sleep_hours","positive_fraction"]>=.8 and s.loc["study_minutes","positive_fraction"]>=.8 and s.loc["screen_time_minutes","negative_fraction"]>=.8),
        weak_features=weak,corner_guard_pass=bool(own.raw_prediction.between(CONFIG["acceptance"]["raw_corner_min"],CONFIG["acceptance"]["raw_corner_max"]).all()),
        input_contract_matches_current_app=False,deployment_approved=False,recommendation="DO NOT APPROVE",reason="28-day model input contract is not current single-day/latest-72-hour app contract; no integration in this pass"))
    assert protected()==before,"A preserved file changed"
    dump(output/"preservation.json",dict(protected_files=len(before),all_sha256_unchanged=True))
    dump(output/"artifact_sha256.json",{p.name:digest(p) for p in sorted(output.iterdir()) if p.is_file()})
    print(json.dumps(dict(output=str(output),alpha=new["alpha"],training_rows=len(pool),coefficients=new["coefficients_raw"],protected=len(before)),indent=2),flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--output",type=Path,default=HERE/"results")
    run(parser.parse_args().output)
