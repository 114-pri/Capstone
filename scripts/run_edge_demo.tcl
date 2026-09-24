# run_edge_demo.tcl
# Build script for EDGE Artix-7 XC7A100T FTG256

create_project -force edge_demo_proj ./edge_demo_proj -part xc7a100tftg256-1

# Add source files
add_files src/awa_lp_bist_fpga_demo.sv
add_files src/bist_top.sv
add_files src/adaptive_controller.sv
add_files src/alu_rv32i.sv
add_files src/bist_controller.sv
add_files src/enhanced_wsa_monitor.sv
add_files src/fault_boost_generator.sv
add_files src/fault_coverage_monitor.sv
add_files src/fault_injector_32bit.sv
add_files src/lt_lfsr_32bit.sv
add_files src/misr_32bit.sv
add_files src/operand_pattern_generator.sv
add_files src/programmable_workload_mapper.sv
add_files src/signature_comparator_32bit.sv
add_files src/transition_model.sv
add_files src/uart_tx.sv

# Add constraints
add_files -fileset constrs_1 constraints/edge_artix100t.xdc

# Set top
set_property top awa_lp_bist_fpga_demo [current_fileset]
update_compile_order -fileset sources_1

# Synthesize
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Implement & Bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Reports
open_run impl_1
report_utilization -file edge_demo_utilization.rpt
report_timing_summary -file edge_demo_timing.rpt
report_drc -file edge_demo_drc.rpt

puts "===================================================="
puts "EDGE ARTIX-7 DEMO BUILD COMPLETE"
puts "Bitstream is in: ./edge_demo_proj/edge_demo_proj.runs/impl_1/awa_lp_bist_fpga_demo.bit"
puts "===================================================="
