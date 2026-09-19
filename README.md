# Workload-Correlated Low-Power BIST (WA-LP-BIST) for 32-Bit RISC-V RV32I ALU

A publication-grade Vivado SystemVerilog project implementing an **ISA-Aware / Workload-Correlated Low-Power BIST (WA-LP-BIST)** architecture for a **32-bit RISC-V (RV32I)** execution datapath, targeted for IEEE VLSI Test Symposium (VTS), Asian Test Symposium (ATS), European Test Symposium (ETS), and ISCAS.

---

## Key Features & Research Contributions

1. **Target CUT**: Full 32-bit RISC-V RV32I execution core supporting 10 standard operations (`ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`) with intermediate gate fault observability.
2. **Three Reconfigurable Test Modes (`lp_mode[1:0]`)**:
   - **Mode `2'b00` (Standard Uniform LFSR)**: Uncorrelated pseudo-random baseline ($x^{32} + x^{22} + x^2 + x + 1$).
   - **Mode `2'b01` (Abu-Issa BS-LFSR)**: Classical Bit-Swapping LFSR (IEEE TVLSI 2012 benchmark).
   - **Mode `2'b10` (Proposed WA-LP-BIST)**: Synthesizable Weighted Opcode Mapper (WOM) profiling CoreMark/Dhrystone instruction distributions (50% Arithmetic, 25% Logic, 12.5% Shift, 12.5% Compare) with 4-cycle burst phase clustering and interleaved bank bit-swapping.
3. **Statistical 50-Seed Monte Carlo Validation**:
   - **48.23% $\pm$ 2.12% reduction in Weighted Switching Activity (WSA)** over standard LFSR ($4464.7 \pm 183.2$ vs. $8637.5 \pm 438.6$ transitions).
   - **24.10% improvement over Abu-Issa BS-LFSR** ($6551.6 \pm 316.5$ transitions).
   - **44.0% reduction in peak single-cycle transitions** (28 vs. 50 transitions).
4. **Deep Gate-Level & Primary Output Fault Grading (100.0% Detection)**:
   - Evaluated across 12 stuck-at faults covering primary outputs (bits 0, 15, 31) and deep internal netlist nodes:
     - Internal adder carry-16 propagation line.
     - Internal barrel shifter stage-2 multiplexer intermediate node.
     - Internal signed comparator sign evaluation flag.
5. **Matched 32-Bit MISR Compactor**: Optimal parallel signature generation with aliasing probability $P_{alias} \approx 2.33 \times 10^{-10}$.
6. **Vector-Based SAIF Power Analysis**: Annotated simulation switching activity (`activity.saif`) into implemented Artix-7 database, proving 88 mW dynamic power, 873 LUTs (4.20%), and 91 I/O pins (fitting the strict 106-pin CPG236 limit).

---

## Directory Structure

```
LFSR_BIST_ALU_Vivado/
│
├── src/                                  # Clean Synthesizable SystemVerilog Sources
│   ├── alu_rv32i.sv                     # 32-bit RV32I ALU with internal gate fault hooks
│   ├── bist_workload_mapper.sv          # Synthesizable Weighted Opcode Mapper (CoreMark/Dhrystone)
│   ├── lt_lfsr_32bit.sv                 # 3-Mode Pattern Generator (Standard, BS-LFSR, WA-LP-BIST)
│   ├── misr_32bit.sv                    # 32-bit Parallel MISR Response Compactor
│   ├── fault_injector_32bit.sv          # Primary & Internal Fault Injector (SA0 / SA1)
│   ├── signature_comparator_32bit.sv    # 32-bit Signature Comparator
│   ├── wsa_monitor.sv                   # Hardware Cycle-by-Cycle Transition / WSA Monitor
│   ├── bist_controller.sv               # 3-State Autonomous BIST FSM Controller
│   └── bist_top.sv                      # Top-Level LP-BIST Integration (91 package pins)
│
├── sim/                                  # Verification Testbench
│   └── tb_lp_bist_top.sv                # 50-seed Monte Carlo & deep fault injection suite
│
├── constraints/                          # Timing and Physical Constraints
│   └── timing.xdc                       # 100 MHz clock and I/O delay constraints
│
├── scripts/                              # Modular Vivado Automation Scripts
│   ├── create_project.tcl               # Builds project, simulates, synthesizes, and places/routes
│   ├── run_simulation.tcl               # Runs 50-seed Monte Carlo & fault simulation in XSim
│   └── generate_saif_power.tcl          # Generates SAIF activity & runs vector-based power analysis
│
├── reports/                              # Exported Synthesis, Timing & Power Reports
│   ├── power_saif_vector_based.rpt      # Vector-based SAIF power report (88 mW dynamic)
│   ├── utilization.rpt                  # Hardware resource utilization report (873 LUTs)
│   ├── timing_summary.rpt               # Static timing analysis report (Fmax = 85.48 MHz)
│   ├── power.rpt                        # Vectorless baseline power report
│   └── activity.saif                    # Simulation switching activity interchange trace
│
├── vivado_lp_project/                    # Vivado Project Database
│   └── LFSR_LP_BIST_ALU.xpr             # Main Vivado project file
│
├── .gitignore                            # Excludes Vivado runtime temporary journals and logs
├── PAPER_RESULTS.md                      # Publication research paper draft & experimental tables
└── README.md                             # Project overview & quickstart guide
```

---

## How to Run

### 1. Open in Vivado GUI
Open the project directly in the Vivado GUI:
- Double-click `vivado_lp_project/LFSR_LP_BIST_ALU.xpr`, or run:
  ```powershell
  & "E:\vivado\2025.2\Vivado\bin\vivado.bat" "vivado_lp_project\LFSR_LP_BIST_ALU.xpr"
  ```

### 2. Run Monte Carlo & Fault Simulation
To run the 50-seed Monte Carlo simulation and full 12-fault matrix in batch mode:
```powershell
& "E:\vivado\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts/run_simulation.tcl
```

### 3. Run Vector-Based SAIF Power Analysis
To record simulation SAIF activity and extract vector-based power from the implemented design:
```powershell
& "E:\vivado\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts/generate_saif_power.tcl
```

### 4. Full Clean Rebuild, Synthesis & Implementation
To generate a fresh project, run behavioral simulation, logic synthesis, place-and-route, and export all reports:
```powershell
& "E:\vivado\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts/create_project.tcl
```
