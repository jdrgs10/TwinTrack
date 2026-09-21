# Assumption/evidence ledger — 2.0-aligned.1

All new numerical observations and latent grade effects are **DEVELOPMENT ASSUMPTIONS**, not empirical participant estimates or medical thresholds. Read the decision report's source table for scientific context. The full prior latent-generator ledger remains preserved at `../2026-09-21-seven-input/ASSUMPTION_LEDGER.md`.

The latent generator uses the prior version's bounds and assumptions, with its observation measurement_sd set to zero in memory. The resolved config below controls the new snapshot observation layer/training/evaluation. The inherited `generator.measurement_sd.*` settings remain listed for provenance but are **not used** as extra observation noise; `snapshot.*` replaces that layer. `stress.measurement_multiplier` likewise is superseded by snapshot.variation_stress_multiplier for the two identical doubled-variation scenarios. Latent target, nonlinear transforms, correlations, clipping, time budget, outcome noise and alternate worlds are inherited, not newly fitted.

| Decision | Provenance/status | Interpretation |
| --- | --- | --- |
| Health windows/source units | VERIFIED SOURCE CODE | Actual Swift implementation, not measured participant distributions. |
| Manual reporting period/subject/date | UNKNOWN | Latest saved scalars only; no invented daily or same-subject data. |
| Forecast horizon | NONE for new prototype | Material target narrowing; no validated forecast. |
| Prior importance; weak wearable increment | COMPLETED NetHealth aggregate, qualitatively evidence-informed | Average HR is not RHR; no GPA-to-percentage conversion. |
| RHR academic numeric slope and all synthetic target effects | DEVELOPMENT ASSUMPTION | No empirical seven-variable causal/forecast equation. |
| Snapshot distributions/error/partial-night timing | DEVELOPMENT ASSUMPTION | One idealized episode, totals/scalars; no source-level/detailed DST simulator. |
| RHR personal comparison direction | EVIDENCE-INFORMED DESIGN | Adult within-person variability and official HealthKit mechanics. |
| 28/21 days, weekly coverage, 3×scaledMAD, 3of5, two-day reset | DEVELOPMENT ASSUMPTION | Not universal/pediatric/medical thresholds; false-alert rate unknown. |
| 1.4826 MAD factor | STATISTICAL CONVENTION | Approximate normal consistency, not a health cutoff. |
| Numeric What-If bounds | ENGINEERING ASSUMPTION | Not healthy ranges; preserve real values and abstain outside. |
| Teen transfer/real accuracy/causal effects | UNKNOWN | No new participant analysis or clinical validation. |

## Every resolved config leaf

Arrays list exact predeclared values. Training procedure/seeds are reproducibility choices; biological-looking constants remain synthetic assumptions. No data was used to choose a best-looking seed.

| Setting | Value |
| --- | --- |
| `version` | `"2.0-aligned.1"` |
| `seeds` | `[3101, 3102, 3103, 3104, 3105, 3106, 3107, 3108, 3109, 3110]` |
| `rows_per_seed` | `6000` |
| `holdout_fraction` | `0.25` |
| `pooled_cv_seed` | `3201` |
| `final_seed` | `99001` |
| `final_rows` | `4000` |
| `old_generator_seed` | `99002` |
| `missingness_seed` | `99003` |
| `cv_folds` | `5` |
| `alpha_grid` | `[0.1, 1, 10, 100, 1000]` |
| `bootstrap_replicates` | `2000` |
| `bootstrap_seed` | `78323` |
| `bounds.sleep_hours` | `[0, 12]` |
| `bounds.steps` | `[0, 30000]` |
| `bounds.exercise_minutes` | `[0, 180]` |
| `bounds.resting_heart_rate` | `[35, 120]` |
| `bounds.study_minutes` | `[0, 360]` |
| `bounds.screen_time_minutes` | `[0, 720]` |
| `bounds.previous_score` | `[0, 100]` |
| `reference.sleep_hours` | `7.5` |
| `reference.steps` | `7000` |
| `reference.exercise_minutes` | `35` |
| `reference.resting_heart_rate` | `70` |
| `reference.study_minutes` | `90` |
| `reference.screen_time_minutes` | `210` |
| `reference.previous_score` | `72` |
| `generator.latent_factors` | `"independent standard-normal engagement, fitness, screen preference"` |
| `generator.sleep.mean` | `7.5` |
| `generator.sleep.screen_loading` | `-0.5` |
| `generator.sleep.engagement_loading` | `0.2` |
| `generator.sleep.noise_sd` | `0.7` |
| `generator.study.median` | `75` |
| `generator.study.engagement_loading` | `0.35` |
| `generator.study.screen_loading` | `-0.15` |
| `generator.study.log_noise_sd` | `0.4` |
| `generator.study.zero_probability` | `0.05` |
| `generator.screen.median` | `210` |
| `generator.screen.preference_loading` | `0.35` |
| `generator.screen.engagement_loading` | `-0.15` |
| `generator.screen.log_noise_sd` | `0.35` |
| `generator.exercise.gamma_shape` | `2` |
| `generator.exercise.gamma_scale` | `18` |
| `generator.exercise.fitness_loading` | `0.25` |
| `generator.exercise.zero_probability` | `0.05` |
| `generator.time.minutes_per_day` | `1440` |
| `generator.time.school_minutes_daily_average` | `300` |
| `generator.time.other_reserved_minutes` | `180` |
| `generator.steps.base` | `2500` |
| `generator.steps.per_exercise_minute` | `50` |
| `generator.steps.incidental_median` | `3000` |
| `generator.steps.incidental_log_sd` | `0.55` |
| `generator.rhr.mean` | `70` |
| `generator.rhr.fitness_loading` | `-4` |
| `generator.rhr.sleep_deficit_loading` | `2` |
| `generator.rhr.noise_sd` | `5` |
| `generator.previous.beta_a` | `9` |
| `generator.previous.beta_b` | `3.5` |
| `generator.previous.engagement_loading` | `0.25` |
| `generator.measurement_sd.sleep_hours` | `0.25` |
| `generator.measurement_sd.steps` | `400` |
| `generator.measurement_sd.exercise_minutes` | `5` |
| `generator.measurement_sd.resting_heart_rate` | `2` |
| `generator.measurement_sd.study_minutes` | `15` |
| `generator.measurement_sd.screen_time_minutes` | `25` |
| `generator.measurement_sd.previous_score` | `2` |
| `generator.target.mean` | `72` |
| `generator.target.previous_slope` | `0.8` |
| `generator.target.outcome_noise_sd` | `8` |
| `generator.target.habit_coefficients.sleep_hours` | `0.5` |
| `generator.target.habit_coefficients.steps` | `3e-05` |
| `generator.target.habit_coefficients.exercise_minutes` | `0.003` |
| `generator.target.habit_coefficients.resting_heart_rate` | `-0.03` |
| `generator.target.habit_coefficients.study_minutes` | `0.015` |
| `generator.target.habit_coefficients.screen_time_minutes` | `-0.004` |
| `generator.nonlinear.sleep_cap` | `8.5` |
| `generator.nonlinear.study_scale` | `90` |
| `generator.nonlinear.study_multiplier` | `180` |
| `generator.nonlinear.exercise_cap` | `60` |
| `generator.nonlinear.screen_neutral_minutes` | `120` |
| `generator.missingness.shared_wearable_failure_probability` | `0.08` |
| `generator.missingness.sleep_hours` | `0.08` |
| `generator.missingness.steps` | `0.02` |
| `generator.missingness.exercise_minutes` | `0.06` |
| `generator.missingness.resting_heart_rate` | `0.3` |
| `generator.missingness.study_minutes` | `0.05` |
| `generator.missingness.screen_time_minutes` | `0.05` |
| `generator.missingness.previous_score` | `0.02` |
| `generator.missingness.high_screen_threshold` | `300` |
| `generator.missingness.high_screen_added_probability` | `0.05` |
| `generator.missingness.low_fitness_added_rhr_probability` | `0.1` |
| `stress.low_noise_sd` | `6` |
| `stress.high_noise_sd` | `12` |
| `stress.rhr_slopes` | `[0, -0.06, 0.03]` |
| `stress.double_effect_multiplier` | `2` |
| `stress.shifted_previous_beta` | `[6, 4]` |
| `stress.shifted_sleep_hours` | `-1` |
| `stress.shifted_screen_minutes` | `60` |
| `stress.previous_slopes` | `[0.55, 0.95]` |
| `stress.shifted_nonlinear.sleep_cap` | `9` |
| `stress.shifted_nonlinear.study_scale` | `180` |
| `stress.shifted_nonlinear.study_multiplier` | `270` |
| `stress.shifted_nonlinear.exercise_cap` | `90` |
| `stress.shifted_nonlinear.screen_neutral_minutes` | `240` |
| `stress.measurement_multiplier` | `2` |
| `increments.sleep_hours` | `1` |
| `increments.steps` | `2000` |
| `increments.exercise_minutes` | `30` |
| `increments.resting_heart_rate` | `5` |
| `increments.study_minutes` | `30` |
| `increments.screen_time_minutes` | `60` |
| `increments.previous_score` | `10` |
| `acceptance.sign_fraction` | `0.8` |
| `acceptance.weak_increment_max` | `0.5` |
| `acceptance.raw_corner_min` | `-5` |
| `acceptance.raw_corner_max` | `105` |
| `snapshot.rng_seed_offset` | `100000` |
| `snapshot.sleep_day_sd` | `1.1` |
| `snapshot.sleep_start_mean` | `21.5` |
| `snapshot.sleep_start_sd` | `1.3` |
| `snapshot.sleep_start_bounds` | `[18, 23.9]` |
| `snapshot.sleep_duration_bounds` | `[0.25, 12]` |
| `snapshot.refresh_hour_bounds` | `[0, 24]` |
| `snapshot.activity_log_sd` | `0.6` |
| `snapshot.exercise_zero_probability` | `0.1` |
| `snapshot.steps_zero_probability` | `0.03` |
| `snapshot.step_day_sd` | `1800` |
| `snapshot.step_exercise_loading` | `50` |
| `snapshot.rhr_day_sd` | `2` |
| `snapshot.rhr_age_hours_bounds` | `[0, 72]` |
| `snapshot.rhr_age_drift_sd_per_hour` | `0.02` |
| `snapshot.study_report_sd` | `40` |
| `snapshot.screen_report_sd` | `75` |
| `snapshot.score_report_sd` | `2` |
| `snapshot.previous_day_reserved_minutes` | `480` |
| `snapshot.variation_stress_multiplier` | `2` |
| `trend.baseline_days` | `28` |
| `trend.minimum_baseline_days` | `21` |
| `trend.minimum_per_week` | `4` |
| `trend.recent_days` | `5` |
| `trend.minimum_recent_days` | `4` |
| `trend.persistent_days` | `3` |
| `trend.mad_factor` | `1.4826` |
| `trend.statistical_multiplier` | `3` |
| `trend.clear_consecutive_days` | `2` |
