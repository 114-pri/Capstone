# Adaptive Workload-Aware Low-Power BIST (AWA-LP-BIST)

This project contains a hardware design that solves the overheating problem that occurs when testing microchips after they are manufactured. 

Specifically, this is a **Built-In Self-Test (BIST)** for a **32-bit RISC-V processor ALU**. It allows the chip to test itself for physical manufacturing defects (like broken wires) without drawing massive amounts of electrical power.

## The Problem
Usually, testing a chip involves blasting it with completely random 1s and 0s billions of times per second. This forces the chip to rapidly jump between doing completely different tasks on every single clock cycle (e.g., Add -> Shift -> XOR). This extreme "thrashing" draws drastically more power than normal software ever would. The chip can literally overheat and melt, or falsely fail the test.

## The Solution
Instead of blasting random noise, this **Adaptive Workload-Aware BIST** mimics normal software workloads. 
- It uses a **Programmable Workload Mapper** to calm down the random data, making it look like real-world software behavior (like performing lots of additions in a row, rather than jumping wildly).
- It includes an **Adaptive Controller** that tracks the testing progress. If it stops finding new bugs, it automatically boosts the switching activity to aggressively hunt down hidden faults, ensuring the chip is perfectly tested, and then drops back to low-power mode.

## Project Results
- **Power Reduction:** Achieved a **32% reduction** in core dynamic power during testing.
- **Switching Activity:** Reduced violent transistor toggling by over **48%**.
- **Test Coverage:** Maintained a perfect **100% defect detection rate**.

## Directory Structure
- `src/` - The SystemVerilog source code for the hardware.
- `sim/` - Testbenches used to simulate and verify the design.
- `scripts/` - Automation scripts for running tests in AMD Vivado.
- `constraints/` - Physical hardware mapping and timing constraints.
- `reports/` - Detailed data reports, power analyses, and timing summaries.

## Documentation
For a deep dive into the methodology, experimental results, and complete power characterization data, please refer to the [COMPREHENSIVE_PROJECT_REPORT.md](COMPREHENSIVE_PROJECT_REPORT.md) included in this repository.
