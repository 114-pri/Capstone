open_project vivado_lp_project/LFSR_LP_BIST_ALU.xpr

# 1. Update part to xc7a100tftg256-2
set_property part xc7a100tftg256-2 [current_project]
set_property part xc7a100tftg256-2 [get_runs synth_1]
set_property part xc7a100tftg256-2 [get_runs impl_1]

# 2. Set hardware top
add_files -quiet -norecurse src/awa_lp_bist_fpga_demo.sv
set_property top awa_lp_bist_fpga_demo [current_fileset]
update_compile_order -fileset sources_1

# 3. Verify and update constraints
# Remove old constraints
remove_files -quiet constraints/basys3.xdc
remove_files -quiet constraints/physical_pins_basys3.xdc
remove_files -quiet constraints/timing.xdc
remove_files -quiet constraints/edge_artix100t_demo.xdc

# Add correct physical demo constraint
add_files -fileset constrs_1 -norecurse constraints/edge_artix100t.xdc

# 4. Reset synth_1
reset_run synth_1

# 5. Synthesize
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# 6. Reset impl_1
reset_run impl_1

# 7. Implement and Bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 8. Run reports
open_run impl_1
report_utilization -file edge_utilization.rpt
report_timing_summary -file edge_timing_summary.rpt

# 9. Run DRC
report_drc -file edge_drc.rpt

puts "Physical FPGA Demo Build Complete."
