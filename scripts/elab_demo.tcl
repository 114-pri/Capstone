create_project -in_memory -part xc7a100tftg256-1
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
set_property top awa_lp_bist_fpga_demo [current_fileset]
synth_design -rtl -top awa_lp_bist_fpga_demo
report_compile_order -fileset sources_1
puts "ELABORATION SUCCESSFUL"
