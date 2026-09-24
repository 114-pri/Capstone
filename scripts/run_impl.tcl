# Create project in memory (or open existing if we want, but memory is faster and cleaner for batch)
create_project -in_memory -part xc7a35tcpg236-1

# Read all RTL sources
read_verilog -sv {
    src/adaptive_controller.sv
    src/alu_rv32i.sv
    src/bist_controller.sv
    src/bist_top.sv
    src/enhanced_wsa_monitor.sv
    src/fault_boost_generator.sv
    src/fault_coverage_monitor.sv
    src/fault_injector_32bit.sv
    src/lt_lfsr_32bit.sv
    src/misr_32bit.sv
    src/operand_pattern_generator.sv
    src/programmable_workload_mapper.sv
    src/signature_comparator_32bit.sv
    src/transition_model.sv
}

# Read constraints
read_xdc constraints/physical_pins_basys3.xdc
read_xdc constraints/timing.xdc

# Run synthesis
synth_design -top bist_top -part xc7a35tcpg236-1

# Force all ports to LVCMOS33 so unassigned ports can be placed in 3.3V banks
set_property IOSTANDARD LVCMOS33 [get_ports *]

write_checkpoint -force post_synth.dcp

# Run optimization and implementation
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force post_route.dcp

# Report timing and utilization
report_timing_summary -file timing_summary.rpt
report_utilization -file utilization.rpt

puts "IMPLEMENTATION DONE"
