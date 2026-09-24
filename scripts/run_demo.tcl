# run_demo.tcl
open_project vivado_lp_project/LFSR_LP_BIST_ALU.xpr

# Add new files
add_files -norecurse src/uart_tx.sv
add_files -norecurse src/fpga_demo_top.sv

# Replace constraints
remove_files constraints/timing.xdc
add_files -fileset constrs_1 -norecurse constraints/basys3.xdc

# Set new top module
set_property top fpga_demo_top [current_fileset]
update_compile_order -fileset sources_1

# Run Synthesis
reset_run synth_1
launch_runs synth_1 -jobs 10
wait_on_run synth_1

# Run Implementation
launch_runs impl_1 -jobs 10
wait_on_run impl_1

# Generate Bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 10
wait_on_run impl_1

# Reports
open_run impl_1
report_utilization -file demo_utilization.rpt
report_timing_summary -file demo_timing.rpt
report_power -file demo_power.rpt

puts "Demo Build Complete! Bitstream generated."
