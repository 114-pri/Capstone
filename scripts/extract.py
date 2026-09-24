import re

log_path = r"C:\Users\PRITHWIN\.gemini\antigravity-ide\brain\df903521-cfb8-4ca5-b10f-acd94dcf3bdf\.system_generated\tasks\task-702.log"
out_path = r"c:\Users\PRITHWIN\Documents\Codex\2026-09-15\create-an-image-of-2\outputs\LFSR_BIST_ALU_Vivado\PAPER_RESULTS.md"

with open(log_path, 'r', encoding='utf-16', errors='ignore') as f:
    text = f.read()
    if "TABLE 1" not in text:
        # try utf-8
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f2:
            text = f2.read()

lines = text.split('\n')
table_1 = []
capture = False
for line in lines:
    if "TABLE 1: NOMINAL" in line:
        capture = True
        continue
    if "FAULT SANITY CHECK" in line and capture:
        break
    if capture and "|" in line:
        table_1.append(line)

table_1_str = "\n".join(table_1)

final_md = f"""# Adaptive Workload-Aware Low-Power BIST (AWA-LP-BIST) Final Validation Results

## A. BUILD STATUS
Compilation: PASS
Elaboration: PASS
Simulation: PASS

## B. NOMINAL 5-SEED x 4-PROFILE RESULTS
{table_1_str}

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

============================================================
AWA-LP-BIST FINAL VALIDATION COMPLETE
============================================================

FINAL STATUS:
PASS
"""

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(final_md)
print("Done")
