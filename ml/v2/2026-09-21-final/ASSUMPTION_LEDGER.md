# Final candidate assumption ledger

Every number below is either inherited synthetic modeling, a declared product/engineering choice, or reproducibility configuration—not a new empirical estimate. Scientific motivation and real-world limitations are in the final report. No direct steps/exercise/RHR target effect was inflated or fitted coefficient manually edited.

Source chain: `../2026-09-21-seven-input` latent generator → `../2026-09-21-aligned` noisy source snapshots → new dated previous-day manual bookkeeping. The old latent measurement_sd is disabled in memory; `snapshot.*` controls observations. Inherited `generator.measurement_sd.*` is provenance, not extra applied noise. The inherited measurement_double scenario and source_variation_double are identical observation stress labels.

| New decision | Exact meaning | Status |
| --- | --- | --- |
| Upcoming target | Same-subject individual written assessment1–7 local days away | PRODUCT ASSUMPTION; unvalidated forecast |
| Prior age | Most recent same-subject result1–90 days old | PRODUCT ASSUMPTION |
| Study/screen | Previous-day subject study / recreational screen elapsed totals | PRODUCT DEFINITION; manual recall uncertainty |
| Metadata | Source/target/prior dates and subject/scale, excluded from features | ELIGIBILITY, no added Ridge inputs |
| Daily bookkeeping | Preserve separate previous-day sleep/exercise; proportionally constrain manual totals, floor minutes | SYNTHETIC PLAUSIBILITY ASSUMPTION |
| Latent outcome/day relation | Prior and hypothetical habit effects unchanged; horizon-independent mean | DEVELOPMENT ASSUMPTION, not real prospective labels |
| Tiny-effect gate |≤.10 pooled/≤.50 all-seed usual increment;≤1.5 pooled full-range points | PREDECLARED ENGINEERING INTERPRETATION LIMIT |
| Noise/dependence diagnostics | Fixed variants/ten seeds/large-N; none selectable | SIMULATOR DIAGNOSIS ONLY |
| RHR trend | Preserved separate personal-baseline design | NON-DIAGNOSTIC DEVELOPMENT ASSUMPTIONS |
| NetHealth | Completed/frozen aggregate; different outcome and HR measure | RELATED EVIDENCE, not direct model validation |
| HSLS/MCS/COMPASS | No completed TwinTrack comparison used | NO NEW OUTCOME ANALYSIS |

## Fully resolved settings

| Setting | Exact value |
| --- | --- |
| `version` | `"2.0-final.1"` |
| `seeds` | `[4101, 4102, 4103, 4104, 4105, 4106, 4107, 4108, 4109, 4110]` |
| `rows_per_seed` | `6000` |
| `holdout_fraction` | `0.25` |
| `pooled_cv_seed` | `4201` |
| `final_seed` | `100001` |
| `final_rows` | `4000` |
| `old_generator_seed` | `100002` |
| `missingness_seed` | `100003` |
| `cv_folds` | `5` |
| `alpha_grid` | `[0.1, 1, 10, 100, 1000]` |
| `bootstrap_replicates` | `2000` |
| `bootstrap_seed` | `78423` |
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
| `contract.minimum_horizon_days` | `1` |
| `contract.maximum_horizon_days` | `7` |
| `contract.maximum_prior_age_days` | `90` |
| `contract.manual_period` | `"previous_completed_local_calendar_day"` |
| `contract.reference_date` | `"2026-09-21"` |
| `contract.subject_key` | `"synthetic_subject"` |
| `contract.previous_day_minutes` | `1440` |
| `activity_acceptance.pooled_increment_max` | `0.1` |
| `activity_acceptance.seed_increment_max` | `0.5` |
| `activity_acceptance.full_range_max` | `1.5` |
| `what_if_steps.sleep_hours` | `0.5` |
| `what_if_steps.steps` | `500` |
| `what_if_steps.exercise_minutes` | `5` |
| `what_if_steps.resting_heart_rate` | `1` |
| `what_if_steps.study_minutes` | `15` |
| `what_if_steps.screen_time_minutes` | `30` |
| `what_if_steps.previous_score` | `1` |
| `diagnostics.seeds` | `[3101, 3102, 3103, 3104, 3105, 3106, 3107, 3108, 3109, 3110]` |
| `diagnostics.rows` | `6000` |
| `diagnostics.large_rows` | `60000` |
| `diagnostics.fixed_alphas` | `[0, 0.1, 100, 1000]` |
| `diagnostics.large_alpha` | `100` |
