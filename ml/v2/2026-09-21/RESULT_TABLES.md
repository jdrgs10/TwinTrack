# Complete synthetic comparison tables

Generated from the immutable results CSVs. Values below are rounded to six decimals for readability; full precision remains in CSV/JSON. No real-world accuracy claim. Raw and clamped metrics coincide in all sampled evaluation cohorts; bound-corner probes can require clamping.

## Central independent synthetic test, n=2,000

| model | mae | rmse | r2 | bias_pred_minus_actual | calibration_slope | calibration_intercept |
| --- | --- | --- | --- | --- | --- | --- |
| v1_frozen | 8.154576 | 10.116371 | 0.365240 | -4.952993 | 1.242851 | -11.328701 |
| mean_only | 10.211532 | 12.701708 | -0.000656 | -0.325125 | undefined | undefined |
| previous_only | 6.651097 | 8.253290 | 0.577512 | -0.137129 | 0.993019 | 0.638749 |
| ridge_six | 6.577101 | 8.167940 | 0.586205 | -0.163153 | 0.993129 | 0.656696 |
| ridge_seven | 6.581027 | 8.173222 | 0.585669 | -0.168413 | 0.992245 | 0.725431 |

## Five development holdouts, mean and sample SD (1,500 each)

| model | mae_mean | mae_std | rmse_mean | rmse_std | r2_mean | r2_std |
| --- | --- | --- | --- | --- | --- | --- |
| mean_only | 10.259432 | 0.325759 | 12.818949 | 0.321121 | -0.000749 | 0.000725 |
| previous_only | 6.590356 | 0.148785 | 8.206673 | 0.151511 | 0.589518 | 0.015201 |
| ridge_seven | 6.504370 | 0.153329 | 8.110063 | 0.157697 | 0.599038 | 0.017860 |
| ridge_six | 6.503670 | 0.154158 | 8.109797 | 0.158024 | 0.599067 | 0.017808 |
| v1_frozen | 8.087518 | 0.135682 | 10.059884 | 0.185593 | 0.383097 | 0.025888 |

## Stress MAE, frozen central-trained candidates, n=2,000 each

| scenario | mean_only | previous_only | ridge_seven | ridge_six | v1_frozen |
| --- | --- | --- | --- | --- | --- |
| central | 10.211532 | 6.651097 | 6.581027 | 6.577101 | 8.154576 |
| double_habits | 10.417321 | 6.851364 | 6.664863 | 6.661419 | 8.047411 |
| high_noise | 12.351596 | 9.694987 | 9.647021 | 9.643118 | 10.720086 |
| low_noise | 9.339132 | 5.119926 | 5.028152 | 5.023311 | 7.025841 |
| null_habits | 10.083094 | 6.588014 | 6.634420 | 6.631055 | 8.375000 |
| opposite_sleep | 10.176231 | 6.654210 | 6.634871 | 6.631486 | 8.241993 |
| population_shift | 13.921897 | 6.691486 | 6.610706 | 6.606623 | 7.580684 |
| rhr_negative | 10.285495 | 6.713860 | 6.604037 | 6.613172 | 8.122986 |
| rhr_positive | 10.244414 | 6.762319 | 6.722616 | 6.708074 | 8.313123 |
| saturation | 10.190045 | 6.626531 | 6.592658 | 6.588599 | 8.217170 |

## Raw coefficient stability across five independent fits

| model | feature | mean | std | min | max | positive_fraction |
| --- | --- | --- | --- | --- | --- | --- |
| previous_only | previous_score | 0.793792 | 0.011373 | 0.777019 | 0.807020 | 1.000000 |
| ridge_seven | exercise_minutes | -0.011082 | 0.007167 | -0.018328 | 0.000211 | 0.200000 |
| ridge_seven | previous_score | 0.781479 | 0.011310 | 0.764197 | 0.794505 | 1.000000 |
| ridge_seven | resting_heart_rate | -0.001933 | 0.019481 | -0.024388 | 0.020189 | 0.400000 |
| ridge_seven | screen_time_minutes | -0.004113 | 0.001161 | -0.005774 | -0.003029 | 0.000000 |
| ridge_seven | sleep_hours | 0.470050 | 0.128351 | 0.276280 | 0.598409 | 1.000000 |
| ridge_seven | steps | 0.000132 | 0.000141 | -0.000045 | 0.000327 | 0.800000 |
| ridge_seven | study_minutes | 0.013971 | 0.002052 | 0.011083 | 0.016733 | 1.000000 |
| ridge_six | exercise_minutes | -0.011009 | 0.006877 | -0.018064 | -0.000747 | 0.000000 |
| ridge_six | previous_score | 0.781426 | 0.011289 | 0.764170 | 0.794444 | 1.000000 |
| ridge_six | screen_time_minutes | -0.004118 | 0.001168 | -0.005782 | -0.003045 | 0.000000 |
| ridge_six | sleep_hours | 0.474061 | 0.108554 | 0.319726 | 0.584030 | 1.000000 |
| ridge_six | steps | 0.000132 | 0.000140 | -0.000045 | 0.000326 | 0.800000 |
| ridge_six | study_minutes | 0.013946 | 0.002044 | 0.011084 | 0.016708 | 1.000000 |

## Missingness: accuracy comparisons require same cohort

| model | cohort | coverage | n | mae | rmse | r2 | bias_pred_minus_actual | calibration_slope | calibration_intercept |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| v1_frozen | common_seven | 0.410000 | 820 | 8.170290 | 10.033870 | 0.380176 | -4.939260 | 1.274767 | -13.587438 |
| v1_frozen | model_eligible | 0.410000 | 820 | 8.170290 | 10.033870 | 0.380176 | -4.939260 | 1.274767 | -13.587438 |
| mean_only | common_seven | 0.410000 | 820 | 10.230561 | 12.763736 | -0.002968 | -0.694334 | undefined | undefined |
| mean_only | model_eligible | 1.000000 | 2000 | 10.211532 | 12.701708 | -0.000656 | -0.325125 | undefined | undefined |
| previous_only | common_seven | 0.410000 | 820 | 6.556712 | 8.035611 | 0.602471 | -0.260676 | 1.004509 | -0.064414 |
| previous_only | model_eligible | 0.962500 | 1925 | 6.651255 | 8.249159 | 0.577490 | -0.135674 | 0.991212 | 0.767287 |
| ridge_six | common_seven | 0.410000 | 820 | 6.504124 | 7.965353 | 0.609392 | -0.207171 | 1.005720 | -0.205574 |
| ridge_six | model_eligible | 0.648500 | 1297 | 6.473805 | 7.978083 | 0.608408 | -0.083701 | 1.016473 | -1.105171 |
| ridge_seven | common_seven | 0.410000 | 820 | 6.510040 | 7.970078 | 0.608928 | -0.212068 | 1.004644 | -0.122990 |
| ridge_seven | model_eligible | 0.410000 | 820 | 6.510040 | 7.970078 | 0.608928 | -0.212068 | 1.004644 | -0.122990 |
| previous_only | common_six | 0.648500 | 1297 | 6.566330 | 8.091617 | 0.597184 | -0.111519 | 1.014514 | -0.935589 |
| ridge_six | common_six | 0.648500 | 1297 | 6.473805 | 7.978083 | 0.608408 | -0.083701 | 1.016473 | -1.105171 |

## 128 corners per candidate (prior-only repeats two distinct inputs)

| model | permitted | count | min | max |
| --- | --- | --- | --- | --- |
| previous_only | True | 128 | 14.301821 | 93.791562 |
| ridge_seven | False | 56 | 11.615548 | 99.750744 |
| ridge_seven | True | 72 | 9.416931 | 101.204801 |
| ridge_six | False | 56 | 12.245705 | 99.389694 |
| ridge_six | True | 72 | 9.880678 | 100.851388 |

## Training-only CV selections

| seed | model | alpha | cv_mae |
| --- | --- | --- | --- |
| 1101 | previous_only | 0.100000 | 6.681699 |
| 1101 | ridge_six | 0.100000 | 6.634696 |
| 1101 | ridge_seven | 0.100000 | 6.634828 |
| 1102 | previous_only | 0.100000 | 6.572373 |
| 1102 | ridge_six | 0.100000 | 6.532148 |
| 1102 | ridge_seven | 0.100000 | 6.532272 |
| 1103 | previous_only | 0.100000 | 6.470173 |
| 1103 | ridge_six | 0.100000 | 6.402601 |
| 1103 | ridge_seven | 0.100000 | 6.405257 |
| 1104 | previous_only | 0.100000 | 6.630043 |
| 1104 | ridge_six | 0.100000 | 6.547710 |
| 1104 | ridge_seven | 0.100000 | 6.548527 |
| 1105 | previous_only | 0.100000 | 6.535579 |
| 1105 | ridge_six | 0.100000 | 6.469816 |
| 1105 | ridge_seven | 0.100000 | 6.469682 |

