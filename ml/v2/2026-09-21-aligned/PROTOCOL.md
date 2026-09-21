# App-aligned V2 and separate RHR comparison protocol

Fixed before training, 2026-09-21, version `2.0-aligned.1`. Preserve all earlier versions and production Swift; no integration, stage, commit, push, participant-data analysis or HSLS outcomes.

## Alignment decision

Choose A (retrain to current app semantics) for all seven inputs. Research does not establish an exact 28-day Grade12 forecast equation that would justify silently changing HealthKit. This version estimates a **current-profile educational score on a 0–100 scale**, not a validated future test, seven-day horizon, GPA or a specified subject outcome. This is a material narrowing of the earlier research target, not evidence that a single day scientifically predicts grades. Future UI/methodology copy must disclose it before enabling V2.

Sleep: union of accessible asleep intervals, clipped yesterday local noon to min(refresh time,today local noon), hours. Steps/exercise: cumulative previous local calendar day, count/minute. RHR: latest valid positive finite sample with start timestamp within inclusive preceding72 elapsed hours. Manual study/screen: latest saved user-entered minutes, no observed period/date/averaging available. Previous score: latest saved user-entered0–100, no validated subject/date. Do not invent a reporting period, freshness rule, subject or horizon for the undated stored manual scalars. Suggested user guidance can ask that values represent their current profile, without claiming observed daily/28-day averages. Missing inputs cause abstention; true accessible activity zero is retained.

The generator explicitly separates latent usual-profile factors from noisier source snapshots. Prior bounded seven-input generator supplies latent profiles and the hypothetical score target with measurement noise disabled; coefficients are not hand-edited. New daily activity/sleep variation, refresh cutoff, recent RHR age and undated self-report error form observed predictors. Existing mild target assumptions/noise/strong prior slope are retained. Every new numerical distribution is a development assumption, not empirically estimated device error or a causal grade effect. No support for seven precise causal effects is inferred.

Source windows differ, so DO NOT apply a fictitious common24-hour budget to all snapshot values. Latent usual-profile generation keeps its own plausible time budget; a separately generated previous-day activity budget is enforced. Manual durations are independent reports of unspecified periods, not proven mutually exclusive totals. What-If overrides those scalars as hypothetical profile inputs; do not describe seven-window changes as one literal day.

## Fixed numerical plan

Inherit previous generator/trainer/evaluator read-only with hashes; local wrappers explicitly replace observation semantics, numeric bounds, feature validation, task metadata and acceptance. Config overrides and fully resolved config are recorded. Seeds3101–3110,6000 rows each,75/25 split; final artifact pools45000 training rows, excludes15000 development holdouts; training-only5-fold CV seed3201, same alpha grid[.1,1,10,100,1000]. Final4000 rows seed99001; previous-generator transport99002; missing mask99003. Preserve ten-seed and alternative-RHR refits. No best-seed or coefficient adjustment. Final artifact is unique predeclared pool.

Retain all existing scenario comparisons, adding partial-vs-complete sleep cutoff and doubled source-day variation. Include frozen V1, all earlier previous/six/seven candidates, previous seven-input pooled artifact, and matched newly trained mean/prior/six/seven models. Report full snapshot-domain and common-old-support metrics separately. Same-row scores are synthetic transport checks; differing target/window/training distributions prevent human-accuracy claims.

Support/What-If bounds: sleep0–12h, steps0–30000, exercise0–180min, RHR35–120bpm, study0–360min, screen0–720min, prior0–100. These are nonmedical engineering abstention limits, not a valid/healthy human range. Broader than earlier window means because snapshots vary more; no numeric-clamping of real input. Preserve inaccessible as missing, not zero. Existing persisted manual values can exceed support and must be preserved while prediction abstains. Snapshot windows cannot be summed into one fabricated time budget. Inference remains StandardScaler+Ridge, raw seven inputs, output clamp0–100.

Report standardized/raw coefficients, original-unit increments, seed sign stability, paired MAE intervals, calibration, out-of-support coverage, all128 corners and What-If bounds. Comparing the latent hypothetical target equation with observed snapshot changes is an approximation diagnostic only, not a real causal effect. New observation metadata is recorded for audit, never added as an eighth Ridge feature.

## Separate RHR wellbeing design

No medical threshold or diagnosis. Quiet in-app statistical comparison only; no push notification, emergency trigger, treatment advice or Ridge coupling. Source is the already-authorized restingHeartRate type only. For each of33 completed local calendar days, select that day's latest valid finite-positive sample by startDate; equal timestamps use the current app's deterministic maximum-value tie-break. Query fresh records each refresh so corrected/replaced samples are respected. Never fill a missing day with the latest72-hour reading or count repeated refreshes as new days. Today excluded. No source/device IDs retained.

Let D be yesterday. Recent days D−4..D. Baseline D−32..D−5 (28days, excludes all five recent days). Need21 valid baseline days, at least4 in each fixed7-day baseline block, >=4/5 recent days, and D present. Median m, scale s=1.4826*MAD; if MAD==0, report insufficient variable data (no arbitrary bpm floor). Flag strictly above m+3s or below m−3s; equality is inside. All parameters (28/21/4/5/3) are conservative engineering assumptions, not validated clinical/pediatric cutoffs. 1.4826 is a normal-consistency statistical factor, not a health threshold.

Deterministic states, recalculated from the fresh33-day query:
- Not enough recent data: any eligibility requirement fails, query unavailable/fails, or spread undefined.
- Within recent usual range: both latest consecutive calendar days observed and inside; OR no outside values in recent five.
- Persistently different: otherwise >=3 recent values beyond the SAME side, no opposite-side flag, with the coverage gates satisfied. Can remain through one inside day; two latest inside days clear it.
- Noticeably different: other recent deviations, including mixed directions; gentle copy, no persistence claim.

No state is latched indefinitely. Missing yesterday immediately becomes insufficient; two consecutive observed inside days reset the signal; flagged points aging out or a recomputed baseline can change state. Time-zone changes rebuild all day buckets from fresh timestamps; no stale day-key reuse. A sustained shift can eventually become part of the rolling baseline; explicitly disclose this limitation. No adaptive medical inference or diagnosis. No age/DOB request: design is for the project's teenage audience but adult evidence does NOT validate teen alert performance. Symptoms, if volunteered to the assistant, remain handled by the existing independent safety route.

## Acceptance and preservation

Existing engineering prior-dominance, sign/tiny-effect, raw-corner [-5,105] checks remain; flag any failure rather than tuning it away. All app feature meanings must match the new declared observation contract (no hidden averages). Wellbeing algorithm must pass synthetic missingness/outlier/persistence/reset/duplicate/DST tests. Human validity remains UNKNOWN. Approval can only mean permission to implement an explicitly educational prototype and quiet personal comparison after A review, not release/medical validation. Any failed gate yields DO NOT APPROVE; no forced pass.

Hash all V1/iOS and both prior V2 folders/reports, plus the approved local research reports. No private HealthKit data or screenshots needed. Keep research reports ignored. Stop after report and recommendation.
