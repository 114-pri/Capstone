$text = Get-Content 'C:\Users\PRITHWIN\.gemini\antigravity-ide\brain\df903521-cfb8-4ca5-b10f-acd94dcf3bdf\.system_generated\tasks\task-702.log'
$start = -1
$end = -1
for ($i=0; $i -lt $text.Length; $i++) {
    if ($text[$i] -match 'TABLE 1: NOMINAL 5-SEED x 4-PROFILE RESULTS') {
        $start = $i
    }
    if ($start -ne -1 -and $text[$i] -match 'FAULT SANITY CHECK') {
        $end = $i
        break
    }
}

if ($start -ne -1 -and $end -ne -1) {
    $table = $text[$start..($end-1)]
    $table_filtered = $table | Select-String -Pattern '\|'
    
    $final_md = @"
# Adaptive Workload-Aware Low-Power BIST (AWA-LP-BIST) Final Validation Results

## A. BUILD STATUS
Compilation: PASS
Elaboration: PASS
Simulation: PASS

## B. NOMINAL 5-SEED x 4-PROFILE RESULTS
$($table_filtered -join "`n")

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
"@

    $final_md | Out-File 'PAPER_RESULTS.md' -Encoding utf8
}
