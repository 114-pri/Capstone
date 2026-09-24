# Adaptive Workload-Aware Low-Power BIST (AWA-LP-BIST) Final Validation Results

## A. BUILD STATUS
Compilation: PASS
Elaboration: PASS
Simulation: PASS

## B. NOMINAL 5-SEED x 4-PROFILE RESULTS
| Seed Idx | Mode     | Profile | Max Window | Mean Window | 95th Percentile | PA Acts | PA Deacts | PA Cycles | Total Trans | Avg Trans/Cyc | Peak Trans | PASS/FAIL |
|----------|----------|---------|------------|-------------|-----------------|---------|-----------|-----------|-------------|---------------|------------|-----------|
|        0 | STD      |      00 |         45 |       33.10 |              44 |       1 |         0 |       238 |        8611 |         33.77 |         49 |      PASS |
|        0 | STATIC   |      00 |         18 |       14.95 |              18 |       0 |         0 |         0 |        3986 |         15.63 |         36 |      PASS |
|        0 | ADAPTIVE |      00 |         18 |       14.95 |              18 |       0 |         0 |         0 |        3986 |         15.63 |         36 |      PASS |
|        0 | STD      |      01 |         45 |       33.10 |              44 |       1 |         0 |       238 |        8611 |         33.77 |         49 |      PASS |
|        0 | STATIC   |      01 |         18 |       14.84 |              18 |       0 |         0 |         0 |        3954 |         15.51 |         36 |      PASS |
|        0 | ADAPTIVE |      01 |         18 |       14.84 |              18 |       0 |         0 |         0 |        3954 |         15.51 |         36 |      PASS |
|        0 | STD      |      10 |         45 |       33.10 |              44 |       1 |         0 |       238 |        8611 |         33.77 |         49 |      PASS |
|        0 | STATIC   |      10 |         18 |       14.94 |              18 |       0 |         0 |         0 |        3986 |         15.63 |         36 |      PASS |
|        0 | ADAPTIVE |      10 |         18 |       14.94 |              18 |       0 |         0 |         0 |        3986 |         15.63 |         36 |      PASS |
|        0 | STD      |      11 |         45 |       33.10 |              44 |       1 |         0 |       238 |        8611 |         33.77 |         49 |      PASS |
|        0 | STATIC   |      11 |         18 |       14.99 |              18 |       0 |         0 |         0 |        3998 |         15.68 |         36 |      PASS |
|        0 | ADAPTIVE |      11 |         18 |       14.99 |              18 |       0 |         0 |         0 |        3998 |         15.68 |         36 |      PASS |
|        0 | ADAPTIVE |  STRESS |         18 |       14.60 |              17 |       0 |         0 |         0 |        3893 |         15.27 |         36 |      PASS |
|        1 | STD      |      00 |         45 |       33.92 |              40 |       1 |         0 |       238 |        8804 |         34.53 |         52 |      PASS |
|        1 | STATIC   |      00 |         21 |       16.57 |              20 |       0 |         0 |         0 |        4316 |         16.93 |         32 |      PASS |
|        1 | ADAPTIVE |      00 |         21 |       16.19 |              20 |       1 |         1 |       109 |        4230 |         16.59 |         38 |      PASS |
|        1 | STD      |      01 |         45 |       33.92 |              40 |       1 |         0 |       238 |        8804 |         34.53 |         52 |      PASS |
|        1 | STATIC   |      01 |         21 |       16.36 |              19 |       0 |         0 |         0 |        4275 |         16.76 |         32 |      PASS |
|        1 | ADAPTIVE |      01 |         21 |       16.18 |              20 |       1 |         1 |       104 |        4235 |         16.61 |         37 |      PASS |
|        1 | STD      |      10 |         45 |       33.92 |              40 |       1 |         0 |       238 |        8804 |         34.53 |         52 |      PASS |
|        1 | STATIC   |      10 |         21 |       16.49 |              20 |       0 |         0 |         0 |        4305 |         16.88 |         32 |      PASS |
|        1 | ADAPTIVE |      10 |         21 |       16.15 |              20 |       1 |         1 |       109 |        4221 |         16.55 |         38 |      PASS |
|        1 | STD      |      11 |         45 |       33.92 |              40 |       1 |         0 |       238 |        8804 |         34.53 |         52 |      PASS |
|        1 | STATIC   |      11 |         21 |       16.54 |              20 |       0 |         0 |         0 |        4314 |         16.92 |         32 |      PASS |
|        1 | ADAPTIVE |      11 |         21 |       16.19 |              20 |       1 |         1 |       109 |        4232 |         16.60 |         38 |      PASS |
|        1 | ADAPTIVE |  STRESS |         21 |       16.15 |              20 |       1 |         1 |       104 |        4216 |         16.53 |         37 |      PASS |
|        2 | STD      |      00 |         46 |       34.12 |              41 |       1 |         0 |       238 |        8943 |         35.07 |         51 |      PASS |
|        2 | STATIC   |      00 |         25 |       16.99 |              23 |       0 |         0 |         0 |        4480 |         17.57 |         33 |      PASS |
|        2 | ADAPTIVE |      00 |         24 |       16.35 |              21 |       2 |         1 |        58 |        4293 |         16.84 |         46 |      PASS |
|        2 | STD      |      01 |         46 |       34.12 |              41 |       1 |         0 |       238 |        8943 |         35.07 |         51 |      PASS |
|        2 | STATIC   |      01 |         25 |       16.85 |              23 |       0 |         0 |         0 |        4449 |         17.45 |         33 |      PASS |
|        2 | ADAPTIVE |      01 |         24 |       16.27 |              21 |       2 |         1 |        58 |        4269 |         16.74 |         46 |      PASS |
|        2 | STD      |      10 |         46 |       34.12 |              41 |       1 |         0 |       238 |        8943 |         35.07 |         51 |      PASS |
|        2 | STATIC   |      10 |         25 |       17.02 |              23 |       0 |         0 |         0 |        4485 |         17.59 |         33 |      PASS |
|        2 | ADAPTIVE |      10 |         24 |       16.41 |              21 |       2 |         1 |        59 |        4301 |         16.87 |         46 |      PASS |
|        2 | STD      |      11 |         46 |       34.12 |              41 |       1 |         0 |       238 |        8943 |         35.07 |         51 |      PASS |
|        2 | STATIC   |      11 |         25 |       17.05 |              23 |       0 |         0 |         0 |        4499 |         17.64 |         33 |      PASS |
|        2 | ADAPTIVE |      11 |         24 |       16.41 |              21 |       2 |         1 |        59 |        4307 |         16.89 |         46 |      PASS |
|        2 | ADAPTIVE |  STRESS |         24 |       15.98 |              21 |       2 |         1 |        58 |        4211 |         16.51 |         46 |      PASS |
|        3 | STD      |      00 |         37 |       29.35 |              36 |       1 |         0 |       233 |        7518 |         29.48 |         50 |      PASS |
|        3 | STATIC   |      00 |         22 |       15.94 |              21 |       0 |         0 |         0 |        4111 |         16.12 |         48 |      PASS |
|        3 | ADAPTIVE |      00 |         22 |       15.60 |              20 |       2 |         2 |        61 |        4035 |         15.82 |         52 |      PASS |
|        3 | STD      |      01 |         37 |       29.35 |              36 |       1 |         0 |       233 |        7518 |         29.48 |         50 |      PASS |
|        3 | STATIC   |      01 |         22 |       15.82 |              20 |       0 |         0 |         0 |        4091 |         16.04 |         48 |      PASS |
|        3 | ADAPTIVE |      01 |         22 |       15.57 |              20 |       2 |         2 |        61 |        4027 |         15.79 |         52 |      PASS |
|        3 | STD      |      10 |         37 |       29.35 |              36 |       1 |         0 |       233 |        7518 |         29.48 |         50 |      PASS |
|        3 | STATIC   |      10 |         22 |       15.96 |              21 |       0 |         0 |         0 |        4115 |         16.14 |         48 |      PASS |
|        3 | ADAPTIVE |      10 |         22 |       15.62 |              20 |       2 |         2 |        63 |        4037 |         15.83 |         52 |      PASS |
|        3 | STD      |      11 |         37 |       29.35 |              36 |       1 |         0 |       233 |        7518 |         29.48 |         50 |      PASS |
|        3 | STATIC   |      11 |         22 |       15.99 |              21 |       0 |         0 |         0 |        4119 |         16.15 |         48 |      PASS |
|        3 | ADAPTIVE |      11 |         22 |       15.64 |              20 |       2 |         2 |        62 |        4043 |         15.85 |         52 |      PASS |
|        3 | ADAPTIVE |  STRESS |         22 |       15.40 |              20 |       2 |         2 |        61 |        3982 |         15.62 |         52 |      PASS |
|        4 | STD      |      00 |         47 |       34.61 |              45 |       1 |         0 |       233 |        8750 |         34.31 |         50 |      PASS |
|        4 | STATIC   |      00 |         20 |       16.20 |              20 |       0 |         0 |         0 |        4158 |         16.31 |         27 |      PASS |
|        4 | ADAPTIVE |      00 |         20 |       15.33 |              19 |       3 |         3 |        88 |        3948 |         15.48 |         43 |      PASS |
|        4 | STD      |      01 |         47 |       34.61 |              45 |       1 |         0 |       233 |        8750 |         34.31 |         50 |      PASS |
|        4 | STATIC   |      01 |         20 |       16.03 |              20 |       0 |         0 |         0 |        4124 |         16.17 |         26 |      PASS |
|        4 | ADAPTIVE |      01 |         20 |       15.41 |              19 |       2 |         2 |        65 |        3976 |         15.59 |         43 |      PASS |
|        4 | STD      |      10 |         47 |       34.61 |              45 |       1 |         0 |       233 |        8750 |         34.31 |         50 |      PASS |
|        4 | STATIC   |      10 |         20 |       16.17 |              20 |       0 |         0 |         0 |        4156 |         16.30 |         26 |      PASS |
|        4 | ADAPTIVE |      10 |         20 |       15.33 |              19 |       3 |         3 |        86 |        3952 |         15.50 |         43 |      PASS |
|        4 | STD      |      11 |         47 |       34.61 |              45 |       1 |         0 |       233 |        8750 |         34.31 |         50 |      PASS |
|        4 | STATIC   |      11 |         20 |       16.23 |              20 |       0 |         0 |         0 |        4166 |         16.34 |         27 |      PASS |
|        4 | ADAPTIVE |      11 |         20 |       15.35 |              19 |       3 |         3 |        88 |        3952 |         15.50 |         43 |      PASS |
|        4 | ADAPTIVE |  STRESS |         20 |       15.31 |              19 |       2 |         2 |        65 |        3941 |         15.45 |         43 |      PASS |

## C. AGGREGATE SWITCHING RESULTS
| Metric | Result |
| :--- | :--- |
| **Standard Total Transitions** | 170504 |
| **Static AWA Total Transitions** | 84087 |
| **Adaptive AWA Total Transitions** | 81982 |
| **Static Switching Reduction** | 50.68 % |
| **Adaptive Switching Reduction** | 51.92 % |
| **Additional Adaptive Contribution** | 2.50 % |
| **Total Autonomous PA Activations** | 38 |
| **Total Autonomous PA Deactivations**| 33 |

## D. FAULT COVERAGE
**STANDARD:**
Injected : 100
Detected : 100
Missed   : 0
Coverage : 100.00 %

**AWA:**
Injected : 100
Detected : 100
Missed   : 0
Coverage : 100.00 %

## E. SANITY CHECKS
PASS/FAIL:
- no compilation errors: PASS
- no elaboration errors: PASS
- no RTL/testbench coupling: PASS
- no SESSION=NONE contamination: PASS
- all nominal runs completed: PASS
- all fault runs completed: PASS
- mean <= max for all windows: PASS
- percentile <= max for all windows: PASS
- PA activation logic correct: PASS
- PA deactivation logic correct: PASS
- hysteresis correct: PASS
- PA active cycles valid: PASS
- counters reset correctly: PASS
- switching totals isolated from fault campaign: PASS
- nominal functional checking valid: PASS
- fault detection accounting valid: PASS
- Standard and AWA fault sanity test valid: PASS
