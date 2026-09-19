# Workload-Correlated Low-Power BIST (WA-LP-BIST) for 32-Bit RISC-V RV32I ALU

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![EDA Tool](https://img.shields.io/badge/EDA-AMD%20Vivado%202025.2-orange.svg)
![Target FPGA](https://img.shields.io/badge/FPGA-Artix--7%20xc7a35tcpg236--1-red.svg)
![Fault Coverage](https://img.shields.io/badge/Fault%20Coverage-100%25%20(12%2F12)-brightgreen.svg)
![Power Reduction](https://img.shields.io/badge/Dynamic%20WSA%20Reduction-48.23%25-success.svg)

An open-source, synthesizable SystemVerilog implementation of an **ISA-Aware / Workload-Correlated Low-Power Built-In Self-Test (WA-LP-BIST)** architecture for a **32-bit RISC-V (RV32I)** arithmetic logic datapath. 

This design tackles the fundamental challenge of excessive switching activity and dynamic IR-drop during pseudo-random testing by combining **Interleaved Bank Bit-Swapping (IB-BS)**, a **Synthesizable Weighted Opcode Mapper (WOM)** calibrated to empirical RISC-V benchmarks (CoreMark & Dhrystone), and **burst phase clustering**.

---

## Architecture Overview

```mermaid
graph TD
    subgraph BIST_Subsystem ["Autonomous BIST Subsystem"]
        FSM["BIST Controller (FSM)<br/><i>RESET, RUN, EVAL</i>"]
        LFSR["32-Bit Reconfigurable Pattern Gen<br/><i>Standard / Abu-Issa / WA-LP-BIST</i>"]
        WOM["Weighted Opcode Mapper<br/><i>CoreMark / Dhrystone Profiled</i>"]
        WSA["Hardware WSA Monitor<br/><i>Cycle-by-Cycle Transition Tracker</i>"]
    end

    subgraph CUT_Subsystem ["Circuit Under Test (CUT)"]
        FI["Fault Injector<br/><i>Primary & Gate-Level Hooks (SA0/SA1)</i>"]
        ALU["32-Bit RV32I Execution Core<br/><i>Adder, Barrel Shifter, Logic, Comparators</i>"]
    end

    subgraph Evaluation_Subsystem ["Response Analysis"]
        MISR["32-Bit Parallel MISR<br/><i>P(x) = x³² + x²² + x² + x + 1</i>"]
        CMP["Signature Comparator<br/><i>Golden vs Captured MISR Check</i>"]
    end

    FSM -->|Test Control & Clocks| LFSR
    FSM -->|Fault Mode & Strobe| FI
    LFSR -->|Entropy Bits R[7:5]| WOM
    LFSR -->|Low-Transition Operands| FI
    WOM -->|Weighted Opcodes| FI
    FI -->|Stimulus Vectors| ALU
    ALU -->|Datapath Outputs| MISR
    ALU -->|Bit Toggles| WSA
    MISR -->|Captured Signature| CMP
    FSM -->|Evaluation Trigger| CMP
```

### Key Modules

| Module | File | Description |
| :--- | :--- | :--- |
| **BIST Top** | [`bist_top.sv`](src/bist_top.sv) | Top-level integration uniting CUT, pattern generator, MISR, FSM, and monitor into 91 user I/O pins. |
| **RV32I ALU (CUT)** | [`alu_rv32i.sv`](src/alu_rv32i.sv) | Full 32-bit RV32I execution core supporting 10 standard operations with internal fault observation taps. |
| **Workload Mapper** | [`bist_workload_mapper.sv`](src/bist_workload_mapper.sv) | Synthesizable opcode generator weighting instructions based on CoreMark/Dhrystone profiling. |
| **Reconfigurable LFSR** | [`lt_lfsr_32bit.sv`](src/lt_lfsr_32bit.sv) | 32-bit PRPG supporting Uniform LFSR, Abu-Issa BS-LFSR, and Proposed WA-LP-BIST. |
| **Parallel MISR** | [`misr_32bit.sv`](src/misr_32bit.sv) | 32-bit maximal-length parallel signature compactor ($P_{alias} \approx 2.33 \times 10^{-10}$). |
| **Fault Injector** | [`fault_injector_32bit.sv`](src/fault_injector_32bit.sv) | Hardware injector modeling Stuck-At-0 (SA0) and Stuck-At-1 (SA1) on outputs and internal gates. |
| **FSM Controller** | [`bist_controller.sv`](src/bist_controller.sv) | Autonomous 3-state control engine (`RESET`, `RUN`, `EVAL`) managing test sequencing. |
| **WSA Monitor** | [`wsa_monitor.sv`](src/wsa_monitor.sv) | Real-time hardware transition counter computing cumulative Weighted Switching Activity. |

---

## Operating Modes (`lp_mode[1:0]`)

The test architecture includes runtime reconfigurability to evaluate baseline and low-power modes:

| Mode (`lp_mode`) | Name | Architecture & Mechanism |
| :---: | :--- | :--- |
| `2'b00` | **Standard Uniform LFSR** | Conventional unweighted maximal-length PRPG ($x^{32} + x^{22} + x^2 + x + 1$). High-entropy toggling baseline. |
| `2'b01` | **Abu-Issa BS-LFSR** | Classical Bit-Swapping LFSR (IEEE TVLSI 2012 benchmark) reducing adjacent cell transitions. |
| `2'b10` | **Proposed WA-LP-BIST** | Workload-Correlated BIST: Interleaved Bank Bit-Swapping + Profiled Opcode Mapping + 4-cycle burst phase decimation. |

### Workload-Aware Instruction Distribution
Profiled from empirical CoreMark and Dhrystone RV32I execution traces:
- **50.0% Arithmetic**: `ADD`, `SUB`
- **25.0% Logic**: `AND`, `OR`, `XOR`
- **12.5% Shifts**: `SLL`, `SRL`, `SRA`
- **12.5% Comparisons**: `SLT`, `SLTU`

---

## Experimental Results & Benchmark Summary

All metrics are validated using a **50-seed Monte Carlo statistical ensemble** and post-implementation timing/power analysis on AMD Vivado 2025.2 targeting a **Xilinx Artix-7 (`xc7a35tcpg236-1`)** FPGA.

### 1. Switching Activity & Transition Reduction (50-Seed Monte Carlo)

| Metric | Standard LFSR (`00`) | Abu-Issa BS-LFSR (`01`) | Proposed WA-LP-BIST (`10`) | Improvement vs Standard | Improvement vs Abu-Issa |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Mean Cumulative WSA** | $8637.5 \pm 438.6$ | $6551.6 \pm 316.5$ | **$4464.7 \pm 183.2$** | **$-48.23\%$** | **$-24.10\%$** |
| **Peak Single-Cycle Transitions** | 50 transitions | 38 transitions | **28 transitions** | **$-44.00\%$** | **$-26.32\%$** |
| **Normalized Power Index** | 1.000 | 0.758 | **0.517** | **$1.93\times$ lower** | **$1.47\times$ lower** |

### 2. Fault Grading & Coverage

Evaluated against 12 representative stuck-at faults across primary outputs and critical internal gate nodes:

| Fault Target | Type | Location | Detection Status | Cycles to Detect |
| :--- | :---: | :--- | :---: | :---: |
| Primary Output Bit 0 | SA0 / SA1 | Output Port `alu_out[0]` | **DETECTED (100%)** | 1 / 1 |
| Primary Output Bit 15 | SA0 / SA1 | Output Port `alu_out[15]` | **DETECTED (100%)** | 1 / 1 |
| Primary Output Bit 31 | SA0 / SA1 | Output Port `alu_out[31]` | **DETECTED (100%)** | 1 / 1 |
| Adder Internal Carry-16 | SA0 / SA1 | Internal Carry Propagation Chain | **DETECTED (100%)** | 1 / 1 |
| Barrel Shifter Stage-2 | SA0 / SA1 | Internal Multiplexer Stage | **DETECTED (100%)** | 1 / 1 |
| Signed Comparator Sign Flag | SA0 / SA1 | Internal Comparison Logic | **DETECTED (100%)** | 1 / 1 |
| **Overall Coverage** | — | **12 / 12 Fault Targets** | **100.0%** | — |

### 3. FPGA Implementation & Hardware Utilization (Artix-7 `xc7a35tcpg236-1`)

| Resource | Used | Available | Utilization |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | 873 | 20,800 | **4.20%** |
| **Slice Registers (FFs)** | 139 | 41,600 | **0.33%** |
| **Bonded I/O Pins** | 91 | 106 | **85.85%** (Within package budget) |
| **Maximum Operating Frequency ($F_{max}$)** | **85.48 MHz** | — | Met timing at 100 MHz target constraint |
| **Dynamic Power (Vector-Based SAIF)** | **88 mW** | — | Annotated from full simulation activity (`activity.saif`) |
| **Static Power (Quiescent)** | **72 mW** | — | Total chip power: 160 mW |

> Detailed mathematical formulations, power breakdown graphs, and extended experimental analyses are documented in [PAPER_RESULTS.md](PAPER_RESULTS.md).

---

## Directory Structure

```
LFSR_BIST_ALU_Vivado/
│
├── src/                                  # Synthesizable SystemVerilog Core RTL
│   ├── alu_rv32i.sv                      # 32-bit RV32I ALU with internal gate fault observation
│   ├── bist_workload_mapper.sv           # Synthesizable Weighted Opcode Mapper (WOM)
│   ├── lt_lfsr_32bit.sv                  # 3-mode PRPG (Uniform, Abu-Issa BS-LFSR, WA-LP-BIST)
│   ├── misr_32bit.sv                     # 32-bit Parallel MISR Response Compactor
│   ├── fault_injector_32bit.sv           # Primary & gate-level fault injector (SA0/SA1)
│   ├── signature_comparator_32bit.sv     # 32-bit signature evaluation comparator
│   ├── wsa_monitor.sv                    # Hardware cycle-by-cycle transition tracker
│   ├── bist_controller.sv                # 3-state autonomous BIST FSM
│   └── bist_top.sv                       # Top-level chip integration (91 I/O pins)
│
├── sim/                                  # Testbench & Verification Suite
│   └── tb_lp_bist_top.sv                 # 50-seed Monte Carlo & 12-fault matrix testbench
│
├── constraints/                          # Synthesis & Physical Constraints
│   └── timing.xdc                        # 100 MHz clock and I/O delay constraints
│
├── scripts/                              # Vivado Tcl Automation Scripts
│   ├── create_project.tcl                # Fresh project rebuild, simulation, synth & implementation
│   ├── run_simulation.tcl                # Batch simulation running Monte Carlo & fault matrix
│   └── generate_saif_power.tcl           # SAIF vector recording & post-impl power analysis
│
├── reports/                              # Implementation & Verification Deliverables
│   ├── power_saif_vector_based.rpt       # Vector-based SAIF dynamic power report
│   ├── utilization.rpt                   # Hardware resource utilization report
│   ├── timing_summary.rpt                # Post-route static timing analysis
│   ├── power.rpt                         # Vectorless baseline power comparison
│   └── activity.saif                     # Simulation switching activity interchange trace
│
├── vivado_lp_project/                    # Vivado Project File
│   └── LFSR_LP_BIST_ALU.xpr              # Managed Vivado project
│
├── PAPER_RESULTS.md                      # Comprehensive academic research & experimental tables
└── README.md                             # Project overview & reproduction guide
```

---

## Getting Started & Reproduction Guide

### Prerequisites
- **AMD Vivado**: Version 2020.1 or higher (tested on Vivado 2025.2).
- **Target Part**: `xc7a35tcpg236-1` (Xilinx Artix-7, CPG236 package).
- Environment variable `vivado` added to your system `PATH` (optional for CLI runs).

---

### Running via Vivado GUI

1. Open AMD Vivado.
2. In the Tcl Console or File Menu, open the project:
   - Navigate to `vivado_lp_project/` and open `LFSR_LP_BIST_ALU.xpr`.
3. To run behavioral simulation:
   - In the Flow Navigator, click **Run Simulation** $\rightarrow$ **Run Behavioral Simulation**.
4. To run implementation and timing/power analysis:
   - Click **Run Implementation** and then **Open Implemented Design**.

---

### Running via Vivado Batch / CLI

All major workflows are fully automated via modular Tcl scripts in the `scripts/` folder:

#### 1. Run 50-Seed Monte Carlo & Fault Simulation
Runs the full Monte Carlo WSA comparison across all 3 test modes and validates the 12-fault detection suite:
```bash
vivado -mode batch -source scripts/run_simulation.tcl
```

#### 2. Generate Vector-Based SAIF Power Analysis
Runs simulation with switching activity extraction into `reports/activity.saif`, annotates switching vectors onto the placed-and-routed netlist, and outputs `reports/power_saif_vector_based.rpt`:
```bash
vivado -mode batch -source scripts/generate_saif_power.tcl
```

#### 3. Full Project Rebuild, Synthesis & Implementation
Constructs the Vivado project from scratch, imports all constraints and sources, runs behavioral simulation, logic synthesis, physical implementation, and exports all utilization, timing, and power reports:
```bash
vivado -mode batch -source scripts/create_project.tcl
```

---

## References

1. **RV32I Base Integer Instruction Set**: *The RISC-V Instruction Set Manual, Volume I: User-Level ISA*.
2. **Abu-Issa & Quigley (2012)**: *Bit-Swapping LFSR and Scan-Chain Ordering: A Novel Technique for Peak- and Average-Power Reduction in Scan-Based BIST*, IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems (TCAD) / TVLSI.
3. **CoreMark & Dhrystone**: EEMBC CoreMark Benchmark suite instruction profiling for 32-bit embedded architectures.
4. **MISR Aliasing Theory**: M. Abramovici, M. A. Breuer, and A. D. Friedman, *Digital Systems Testing and Testable Design*, IEEE Press.

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
