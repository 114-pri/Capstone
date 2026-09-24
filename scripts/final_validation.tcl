# final_validation.tcl

set FINAL_DIR "final_results"
file mkdir $FINAL_DIR

puts "========================================================"
puts "TASK 1: CLEAN SIMULATION"
puts "========================================================"
# Recompile sources for clean simulation
catch {exec E:/vivado/2025.2/Vivado/bin/xvlog.bat -sv \
    src/adaptive_controller.sv \
    src/alu_rv32i.sv \
    src/bist_controller.sv \
    src/bist_top.sv \
    src/enhanced_wsa_monitor.sv \
    src/fault_boost_generator.sv \
    src/fault_coverage_monitor.sv \
    src/fault_injector_32bit.sv \
    src/lt_lfsr_32bit.sv \
    src/misr_32bit.sv \
    src/operand_pattern_generator.sv \
    src/programmable_workload_mapper.sv \
    src/signature_comparator_32bit.sv \
    src/transition_model.sv \
    sim/tb_lp_bist_top.sv \
    sim/tb_power_char.sv} log_xvlog

# Elaborate main behavioral testbench
puts "Elaborating main behavioral testbench..."
catch {exec E:/vivado/2025.2/Vivado/bin/xelab.bat -debug typical --timescale 1ns/1ps -s final_sim work.tb_lp_bist_top} log_xelab

# Run main behavioral simulation
puts "Running main behavioral simulation..."
set fp [open "run_final_sim.tcl" w]
puts $fp "run all"
puts $fp "quit"
close $fp
catch {exec E:/vivado/2025.2/Vivado/bin/xsim.bat final_sim -tclbatch run_final_sim.tcl} sim_log

set f_sim [open "$FINAL_DIR/final_behavioral_report.txt" w]
puts $f_sim $sim_log
close $f_sim

# Generate SAIF files skipped: Using the existing validated SAIF files as requested
set modes {0 1 2}
set mode_names {STD STATIC_AWA ADAPTIVE_AWA}


puts "========================================================"
puts "TASK 2 & 3 & 4: CLEAN SYNTHESIS, IMPLEMENTATION, DRC"
puts "========================================================"
open_project vivado_lp_project/LFSR_LP_BIST_ALU.xpr

puts "Resetting and launching synth_1..."
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

open_run synth_1 -name synth_1
report_utilization -file $FINAL_DIR/final_utilization_synth.rpt

puts "Resetting and launching impl_1..."
reset_run impl_1
launch_runs impl_1 -jobs 8
wait_on_run impl_1

open_run impl_1 -name impl_1
report_timing_summary -file $FINAL_DIR/final_timing_summary.rpt
report_timing -max_paths 10 -file $FINAL_DIR/final_timing_paths.rpt
report_utilization -file $FINAL_DIR/final_utilization.rpt
report_drc -file $FINAL_DIR/final_drc.rpt

puts "========================================================"
puts "TASK 5: FINAL POWER CHARACTERIZATION"
puts "========================================================"
foreach mname $mode_names {
    puts "Running power analysis for $mname..."
    reset_switching_activity -all
    read_saif "power_${mname}.saif" -strip_path tb_power_char/dut
    report_power -file "$FINAL_DIR/final_power_${mname}.rpt"
}

close_project
puts "Validation complete! Reports generated in $FINAL_DIR"
