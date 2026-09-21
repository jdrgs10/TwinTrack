"""Versioned adapter around the preserved comparison runner; no previous-file edits."""
import argparse
import importlib.util
import json
from pathlib import Path

import pandas as pd

from generator import HERE,PREVIOUS,CONFIG

spec=importlib.util.spec_from_file_location("aligned_previous_evaluator",PREVIOUS/"evaluate.py")
previous=importlib.util.module_from_spec(spec);spec.loader.exec_module(previous)
original_protected=previous.protected
original_candidates=previous.frozen_candidates
original_dump=previous.dump


def protected():
    values=original_protected()
    paths=[p for p in PREVIOUS.rglob("*") if p.is_file() and "__pycache__" not in p.parts]
    paths.append(previous.ROOT/"docs/V2_SEVEN_INPUT_FINAL_RECOMMENDATION.md")
    values.update({str(p.relative_to(previous.ROOT)):previous.digest(p) for p in paths})
    return dict(sorted(values.items()))


def candidates():
    values=original_candidates()
    values["previous_seven_pooled"]=json.loads((PREVIOUS/"results/new_ridge_seven_parameters.json").read_text())
    return values


def dump(path,value):
    if path.name=="acceptance.json":
        value["input_contract_matches_current_app"]=True
        value["alignment_scope"]="Literal source-snapshot definitions only; manual reporting period/subject/date remain unknown. No validated forecast claim."
        value["recommendation"]="DO NOT APPROVE"
        value["reason"]="Numerical candidate is aligned to stored snapshots, but no meaningful assessment target/horizon or manual reporting period is established; teen RHR comparison remains an unvalidated statistical prototype. Review final report."
    if path.name=="artifact_sha256.json":
        directory=path.parent
        original_dump(directory/"resolved_config.json",CONFIG)
        table=pd.read_csv(directory/"synthetic_final.csv")
        models=candidates()
        for name in ["new_previous_only","new_ridge_six","new_ridge_seven"]:
            models[name]=json.loads((directory/(name+"_parameters.json")).read_text())
        # Preserve mean fitted to the same pooled training rows, never to final labels.
        training=pd.read_csv(directory/"synthetic_v2.csv")
        models["mean_only"]={"constant":float(training.loc[training.split=="train","assessment_score"].mean())}
        old_bounds=json.loads((PREVIOUS/"config.json").read_text())["bounds"]
        mask=pd.Series(True,index=table.index)
        for f,(low,high) in old_bounds.items(): mask &= table[f].between(low,high)
        rows=[dict(model=name,cohort="common_previous_numeric_bounds",coverage=float(mask.mean()),**previous.metrics(table.loc[mask,"assessment_score"],previous.model_prediction(p,table.loc[mask]))) for name,p in models.items()]
        pd.DataFrame(rows).to_csv(directory/"common_support_metrics.csv",index=False)
        value={p.name:previous.digest(p) for p in sorted(directory.iterdir()) if p.is_file()}
    original_dump(path,value)


previous.protected=protected
previous.frozen_candidates=candidates
previous.dump=dump


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--output",type=Path,default=HERE/"results")
    previous.run(parser.parse_args().output)
