"""Synthetic-only invariant tests; never invokes V1 writing scripts or real data."""
import json
import unittest
from pathlib import Path

import numpy as np
import pandas as pd
from pandas.testing import assert_frame_equal

import experiment as e


class V2Invariants(unittest.TestCase):
    def test_generator_is_deterministic(self):
        a, _, _ = e.generate(120, 500)
        b, _, _ = e.generate(120, 500)
        assert_frame_equal(a, b)

    def test_bounds_and_time_budget(self):
        for scenario in e.SCENARIOS:
            frame, _, _ = e.generate(121, 1000, scenario)
            self.assertTrue(np.isfinite(frame.to_numpy()).all())
            for f, (low, high) in e.CONFIG["bounds"].items():
                self.assertTrue(frame[f].between(low, high).all(), (scenario, f))
            self.assertTrue(frame[e.TARGET].between(0, 100).all())
            used = 60 * frame.sleep_hours + frame.study_minutes + frame.screen_time_minutes + frame.exercise_minutes
            t = e.CONFIG["generator"]["time"]
            self.assertTrue((used <= t["minutes_per_day"] - t["school_minutes_daily_average"] - t["other_reserved_minutes"] + 1e-9).all())

    def test_synthetic_correlations_not_independent_marginals(self):
        frame, _, _ = e.generate(122, 3000)
        c = frame.corr()
        self.assertGreater(c.loc["steps", "exercise_minutes"], .5)
        self.assertLess(c.loc["study_minutes", "screen_time_minutes"], -.1)
        self.assertLess(c.loc["sleep_hours", "screen_time_minutes"], -.2)

    def test_sensitivity_scenarios_share_inputs_and_random_noise(self):
        central, _, _ = e.generate(123, 500)
        for scenario in e.SCENARIOS:
            if scenario != "population_shift":
                other, _, _ = e.generate(123, 500, scenario)
                assert_frame_equal(central[e.FEATURES], other[e.FEATURES])

    def test_missingness_preserves_values_and_labels(self):
        frame, fitness, _ = e.generate(124, 1000)
        masked = e.apply_missingness(frame, fitness, 125)
        self.assertGreater(masked[e.FEATURES].isna().sum().sum(), 0)
        for f in e.FEATURES:
            observed = masked[f].notna()
            np.testing.assert_array_equal(masked.loc[observed, f], frame.loc[observed, f])
        np.testing.assert_array_equal(frame[e.TARGET], masked[e.TARGET])
        six = masked[e.SIX].notna().all(axis=1)
        seven = masked[e.FEATURES].notna().all(axis=1)
        self.assertTrue((~seven | six).all())
        self.assertGreater(six.sum(), seven.sum())

    def test_scaler_uses_training_rows_and_export_matches_sklearn(self):
        data, _, _ = e.generate(126, 600)
        train, holdout = e.train_test_split(data, test_size=.25, random_state=126)
        self.assertFalse(set(train.index) & set(holdout.index))
        model, _, _ = e.fit_ridge(train, e.SIX, 126)
        np.testing.assert_allclose(model["standardscaler"].mean_, train[e.SIX].mean())
        params = e.export_ridge(model, e.SIX, 126)
        np.testing.assert_allclose(e.predict_export(params, holdout), model.predict(holdout[e.SIX]), atol=1e-10)

    def test_export_rejects_missing_nonfinite_outside_support(self):
        params = json.loads((e.HERE / "results/ridge_six_candidate.json").read_text())
        for f in e.SIX:
            for bad in [None, np.nan, np.inf, -np.inf, e.CONFIG["bounds"][f][0] - 1, e.CONFIG["bounds"][f][1] + 1]:
                with self.assertRaises(ValueError):
                    e.checked_predict(params, {**e.CONFIG["reference"], f: bad})

    def test_export_rejects_infeasible_combination(self):
        params = json.loads((e.HERE / "results/ridge_six_candidate.json").read_text())
        with self.assertRaises(ValueError):
            e.checked_predict(params, {f: e.CONFIG["bounds"][f][1] for f in e.FEATURES})

    def test_removed_rhr_does_not_change_six_input_prediction(self):
        params = json.loads((e.HERE / "results/ridge_six_candidate.json").read_text())
        values = dict(e.CONFIG["reference"])
        a = e.checked_predict(params, values)
        del values["resting_heart_rate"]
        self.assertEqual(a, e.checked_predict(params, values))

    def test_artifact_manifest_and_protected_hashes(self):
        directory = e.HERE / "results"
        for name, expected in json.loads((directory / "artifact_sha256.json").read_text()).items():
            self.assertEqual(e.digest(directory / name), expected, name)
        self.assertEqual(e.protected_hashes(), json.loads((directory / "protected_v1_ios_sha256.json").read_text()))

    def test_all_candidates_use_common_final_rows(self):
        metrics = pd.read_csv(e.HERE / "results/metrics.csv")
        final = metrics[metrics.split == "independent_synthetic_test"]
        self.assertTrue((final.n == e.CONFIG["final_rows"]).all())
        self.assertEqual(len(final), len(e.SCENARIOS) * 5 * 2)

    def test_stored_v1_parity_and_no_rounding_loss(self):
        audit = json.loads((e.HERE / "results/v1_audit.json").read_text())
        self.assertEqual(audit["golden"]["pass"], 21)
        self.assertLess(audit["artifact_json_prediction_max_error"], 1e-10)
        self.assertTrue(audit["generator_csv_numeric_match"])
        self.assertEqual(audit["alpha"], audit["retuned_in_memory_alpha"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
