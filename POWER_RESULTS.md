# AWA-LP-BIST Activity-Based Power Characterization Report

## Methodology

| Parameter | Value |
| :--- | :--- |
| **Tool** | Vivado v2025.2 (report_power) |
| **Device** | xc7a35tcpg236-1 (Artix-7, Speed Grade -1, Commercial) |
| **Design State** | Routed (post-route checkpoint) |
| **Clock** | 71.4 MHz (14 ns period) |
| **Activity Source** | SAIF files from XSim behavioral simulation |
| **Simulation Duration** | 72,331 ns per mode (5 seeds x 4 profiles x 255 BIST cycles each) |
| **Process** | Typical |
| **Ambient Temperature** | 25.0 C |
| **Confidence Level** | Medium (Design: High, Clocks: High, I/O: High, Internal: Medium) |
| **Design Nets Matched** | 19% (316/1638) |

## Final Power Table

| Mode | Dynamic Power (mW) | Static Power (mW) | Total Power (mW) | Logic Power (mW) | Signal Power (mW) | Clock Power (mW) | I/O Power (mW) | Confidence |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |
| **STANDARD** | 127 | 72 | 199 | 11 | 17 | 4 | 95 | Medium |
| **STATIC AWA** | 115 | 72 | 187 | 8 | 12 | 4 | 92 | Medium |
| **ADAPTIVE AWA** | 114 | 72 | 186 | 7 | 12 | 4 | 91 | Medium |

## Dynamic Power Reduction

| Comparison | Result |
| :--- | ---: |
| **Static AWA vs Standard** | **9.45 %** |
| **Adaptive AWA vs Standard** | **10.24 %** |
| **Adaptive Additional vs Static AWA** | **0.87 %** |

## Total On-Chip Power Reduction

| Comparison | Result |
| :--- | ---: |
| **Static AWA vs Standard** | **6.03 %** |
| **Adaptive AWA vs Standard** | **6.53 %** |

## Core Logic + Signal Power Reduction (Excluding I/O)

| Mode | Logic + Signal (mW) |
| :--- | ---: |
| **STANDARD** | 28 |
| **STATIC AWA** | 20 |
| **ADAPTIVE AWA** | 19 |

| Comparison | Core Reduction |
| :--- | ---: |
| **Static AWA vs Standard** | **28.57 %** |
| **Adaptive AWA vs Standard** | **32.14 %** |
| **Adaptive Additional vs Static** | **5.00 %** |

## Hierarchical Power Breakdown

| Hierarchy Block | STD (mW) | STATIC AWA (mW) | ADAPTIVE AWA (mW) |
| :--- | ---: | ---: | ---: |
| bist_top (total) | 127 | 115 | 114 |
| u_lfsr (pattern gen) | 25 | 17 | 17 |
| u_lfsr/u_op_gen | 21 | 14 | 13 |
| u_wsa (WSA monitor) | 4 | 3 | 3 |
| u_adaptive (controller) | 1 | 1 | 1 |
| u_misr (compactor) | 1 | 1 | 1 |

## Validity Checks

- SAIF files generated from real simulation: PASS
- All three modes use identical implementation: PASS
- Same clock constraint (14 ns / 71.4 MHz): PASS
- Same device, voltage, process, temperature: PASS
- Same simulation duration (72,331 ns): PASS
- Equivalent workload scope (5 seeds x 4 profiles): PASS
- Clock activity = High confidence: PASS
- I/O activity = High confidence: PASS
- Design implementation = High confidence: PASS
- Device models = Production: PASS
- No SAIF parsing errors: PASS
- Timing remains PASS (WNS = +0.202 ns): PASS
- Resource utilization unchanged: PASS
- Functional simulation PASS (from prior validation): PASS

============================================================
AWA-LP-BIST ACTIVITY-BASED POWER CHARACTERIZATION COMPLETE
============================================================
