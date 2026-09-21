"""Rebuild the offline assumption ledger, table appendix and file inventory.

Reads aggregate synthetic results only. Does not run training or access research data.
"""
import hashlib
import json
from pathlib import Path

import pandas as pd

HERE = Path(__file__).resolve().parent
RESULTS = HERE / "results"


def table(frame):
    def cell(value):
        if isinstance(value, float):
            return "undefined" if pd.isna(value) else f"{value:.6f}"
        return str(value).replace("|", "\\|")
    rows = [[cell(v) for v in row] for row in frame.itertuples(index=False, name=None)]
    return "\n".join(["| " + " | ".join(map(str, frame.columns)) + " |",
                      "| " + " | ".join(["---"] * len(frame.columns)) + " |"] +
                     ["| " + " | ".join(row) + " |" for row in rows])


def leaves(value, prefix=""):
    for key, item in value.items():
        name = f"{prefix}.{key}" if prefix else key
        if isinstance(item, dict):
            yield from leaves(item, name)
        else:
            yield name, item


def ledger():
    config = json.loads((HERE / "config.json").read_text())
    notes = {
        "sleep": "Direction informed by external sleep evidence; coefficients, mean, spread and latent loadings are not estimated from participants.",
        "study": "Positive study association motivates sign only; lognormal skew, zeros and all numeric effects assumed.",
        "screen": "Recreational screen displacement motivates dependence only; no external effect converted to points/minute.",
        "exercise": "Skew/zeros and activity overlap modeled, not calibrated to adolescent HealthKit data.",
        "time": "Primary activities are mutually exclusive; steps overlap exercise. School/other time are simplified daily averages.",
        "steps": "Overlap with exercise deliberately induced; strength is assumed, not fitted to NetHealth.",
        "rhr": "Physiological proxy for fitness/sleep in simulation only; not a clinically validated equation.",
        "previous": "Strong prior attainment motivated by NetHealth; distribution and latent dependence are assumed.",
        "measurement_sd": "Independent additive Gaussian summary-measurement errors, then support clipping/time constraint. No device accuracy claim.",
        "target": "All point-scale slopes/noise are hypothetical. Central zero direct wearable effects do not establish real null effects.",
        "missingness": "Hypothetical whole-window missingness; dependent on screen/fitness. Never imputed as zero. Not measured permission/device availability.",
    }
    rows = []
    for name, value in leaves(config):
        note = "Predeclared reproducibility/model-selection setting; not estimated scientific truth."
        if name.startswith("generator."):
            note = notes.get(name.split(".")[1], "Independent N(0,1) latent variables are assumed; not measured traits.")
        elif name.startswith("bounds."):
            note = "Research support/abstention range, not a healthy target or an empirically established safe range."
        elif name.startswith("reference."):
            note = "Centering/probe anchor; not a healthy optimum and not necessarily a training mean."
        elif name.startswith("stress."):
            note = "Prespecified counter-assumption; assess transport without refitting. No estimated dose-response curve."
        rows.append([name, json.dumps(value), "config.json / pre-run PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low scientific / explicit engineering choice", note])
    extra = [
        ("Population / subject", "UAE Grade 12, ~16–18; one specified subject and comparable assessment", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low transport evidence", "Available completed study is US college, not this target population."),
        ("Target / horizon", "Single test percentage, exactly 7 local calendar days after cutoff", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low", "No day-level timing is generated; this is a proposed future collection contract."),
        ("Prior-score eligibility", "Comparable same-subject test before cutoff, <=90 days old", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low", "Subject/date metadata gates must be implemented and validated before integration."),
        ("Habit aggregation / completeness", "28 completed days; >=21 observed per required habit; arithmetic available-day mean", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low", "Multiweek literature motivates window length qualitatively; exact length/threshold not fitted. Daily coverage not simulated."),
        ("Sleep / RHR windows", "Completed noon-to-noon sleep; daily valid RHR summaries averaged", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low", "Different from current app partial sleep cutoff / latest-72-hour RHR."),
        ("Study / screen construct", "Same-subject outside-class deliberate study; recreational screen excluding study", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Low", "Avoid double counting; unavailable construct mapping means abstention, not substitute values."),
        ("Row structure", "One independent student/assessment per row", "experiment.py", "DEVELOPMENT ASSUMPTION", "Low realism", "No school effects, repeated students, individual time series, or clustered error; real evaluation needs grouped/temporal design."),
        ("Regression to mean / Gaussian copula", "0.8 prior slope; latent N(0,1) mixed with sqrt(1-loading^2); Beta CDF inverse", "experiment.py / config.json", "DEVELOPMENT ASSUMPTION", "Low", "Not empirically fitted retention of previous performance."),
        ("Clipping / measurement order", "Latent bounds -> time budget -> steps/RHR -> bounds -> Gaussian measurement error -> bounds/time -> target clamp 0–100", "experiment.py", "DEVELOPMENT ASSUMPTION", "Low", "Target computed from latent values before measurement error; CSV preserves floating precision. Boundary masses possible."),
        ("Time conversion", "60 minutes/hour; 1,440 minutes/day bookkeeping", "Unit definitions", "DEVELOPMENT ASSUMPTION", "High for units, low for simplified day model", "Fixed average time budget, not elapsed local DST-day simulation; app calendar windows must remain calendar-based."),
        ("Missingness RNG / dependencies", "seed=97002; high-screen increment on each feature; fitness<0 adds RHR missingness; shared wearable mask", "experiment.py", "DEVELOPMENT ASSUMPTION", "Low", "Whole-window availability; observed values unchanged; labels retained for synthetic evaluation only."),
        ("Scaling / Ridge objective", "Training-fold population SD (ddof=0); squared error + alpha*sum(beta^2); unpenalized intercept", "StandardScaler/Ridge implementation", "DEVELOPMENT ASSUMPTION", "High computational / unvalidated scientific", "Feature order explicit. No nonlinear fitted transforms, imputation, feature selection, or external coefficient conversion."),
        ("Output export / abstention", "Float64; full-precision JSON; clamp [0,100]; reject missing/nonfinite/out-of-range required values", "experiment.py", "DEVELOPMENT ASSUMPTION", "High computational", "checked_predict enforces numeric/time gates only; subject/date/coverage metadata gates remain future integration work."),
        ("Bootstrap / calibration", "Paired row percentile 95% CI (2.5/97.5 percentiles); actual~prediction OLS; 10 equal-size rank bins", "PROTOCOL.md / experiment.py", "DEVELOPMENT ASSUMPTION", "Conditional on simulated rows", "Mean-only calibration slope is undefined; bins do not fit/recalibrate model; no uncertainty from unknown biology."),
        ("Seed consistency / RHR gate", ">=4/5 MAE+RMSE wins; RHR sign >=4/5 and compatible prior-adjusted external evidence", "PROTOCOL.md", "DEVELOPMENT ASSUMPTION", "Engineering policy", "Additional 0.10-point MAE gate and CI<0; not a clinically established threshold."),
        ("Extreme probes", "128 corners per candidate; 2 endpoints per required feature at configured reference", "experiment.py", "DEVELOPMENT ASSUMPTION", "Engineering checks only", "Protocol says training mean; actual probes use declared reference instead. Disclosed deviation; corner enumeration still covers support boundaries."),
        ("Numerical tolerances", "Export parity 1e-10; V1 regeneration 1e-12; time comparison 1e-9; constant-prediction SD 1e-10", "experiment.py", "DEVELOPMENT ASSUMPTION", "Engineering", "Tolerances address floating-point comparison; V1 existing golden tolerance remains 1e-6."),
        ("Steps/exercise and screen/study dependence", "Shared latent activity and engagement/screen preference; exact loadings in config", "NetHealth aggregate + external time-use literature; numeric config", "DEVELOPMENT ASSUMPTION", "Direction plausible, magnitude low", "Synthetic steps/exercise r≈.887 exceeds saved NetHealth .636. Not a fitted covariance matrix."),
        ("Strong prior / small wearable increment", "Saved NetHealth prior-only fold MAE .17127; added-wearable delta +.00003 GPA units", "Frozen local NetHealth report", "EMPIRICALLY ESTIMATED", "Moderate within reported cohort", "Aggregate report only, not recomputed; known development evidence; no 0–100 conversion."),
        ("Sleep/study/screen direction constraints", "Mixed contextual published findings, no transferable point-scale slopes", "Sources linked in final report", "PUBLISHED EVIDENCE", "Variable by construct/population", "Direction motivates scenarios, not a coefficient estimate."),
        ("Real V2 accuracy / causal habit effects", "Not known", "No compatible real evaluation", "UNKNOWN", "Unknown", "Synthetic fit cannot estimate real-world predictive accuracy or causal intervention gains."),
    ]
    rows.extend(extra)
    frame = pd.DataFrame(rows, columns=["Parameter / relationship", "Chosen value or range", "Source", "Evidence type", "Confidence", "Notes"])
    (HERE / "ASSUMPTION_LEDGER.md").write_text("# V2 assumption/source ledger\n\nAll config leaves are enumerated below. None of the V2 generator's numerical population distributions or academic effects was fitted to real participant data. Semantic rules and implementation constants follow the config entries. This ledger documents a synthetic experiment, not a validated clinical/educational protocol.\n\n" + table(frame) + "\n")


def appendices():
    metrics = pd.read_csv(RESULTS / "metrics.csv")
    final = metrics[(metrics.split == "independent_synthetic_test") & (metrics.output == "raw")]
    central = final[final.scenario == "central"]
    sections = [("Central independent synthetic test, n=2,000", central[["model", "mae", "rmse", "r2", "bias_pred_minus_actual", "calibration_slope", "calibration_intercept"]])]
    dev = metrics[(metrics.split == "development_holdout") & (metrics.output == "raw")]
    summary = dev.groupby("model")[["mae", "rmse", "r2"]].agg(["mean", "std"])
    summary.columns = ["_".join(col) for col in summary.columns]
    sections.append(("Five development holdouts, mean and sample SD (1,500 each)", summary.reset_index()))
    sections.append(("Stress MAE, frozen central-trained candidates, n=2,000 each", final.pivot(index="scenario", columns="model", values="mae").reset_index()))
    sections.append(("Raw coefficient stability across five independent fits", pd.read_csv(RESULTS / "coefficient_stability.csv")))
    sections.append(("Missingness: accuracy comparisons require same cohort", pd.read_csv(RESULTS / "missingness_coverage.csv")))
    extremes = pd.read_csv(RESULTS / "extreme_cases.csv")
    sections.append(("128 corners per candidate (prior-only repeats two distinct inputs)", extremes.groupby(["model", "permitted"]).raw_prediction.agg(["count", "min", "max"]).reset_index()))
    sections.append(("Training-only CV selections", pd.read_csv(RESULTS / "training_cv.csv")))
    text = "# Complete synthetic comparison tables\n\nGenerated from the immutable results CSVs. Values below are rounded to six decimals for readability; full precision remains in CSV/JSON. No real-world accuracy claim. Raw and clamped metrics coincide in all sampled evaluation cohorts; bound-corner probes can require clamping.\n\n"
    for title, frame in sections:
        text += "## " + title + "\n\n" + table(frame) + "\n\n"
    (HERE / "RESULT_TABLES.md").write_text(text)


def inventory():
    root = HERE.parents[2]
    files = [p for p in HERE.rglob("*") if p.is_file() and "__pycache__" not in p.parts and p.name != "FILE_INVENTORY.md"]
    files.append(root / "docs/V2_MODEL_FINAL_DECISION.md")
    rows = [[str(p.relative_to(root)), p.stat().st_size, hashlib.sha256(p.read_bytes()).hexdigest()] for p in sorted(files)]
    text = "# Files created by the V2 offline pass\n\nAll listed files are new. This inventory excludes itself from hashing. No existing production file is edited. Generated Python caches are excluded by existing Git ignore rules. Pre-existing Xcode user workspace state is unrelated and must not be included.\n\n"
    (HERE / "FILE_INVENTORY.md").write_text(text + table(pd.DataFrame(rows, columns=["Repository-relative path", "Bytes", "SHA-256"])) + "\n")


if __name__ == "__main__":
    ledger()
    appendices()
    inventory()
