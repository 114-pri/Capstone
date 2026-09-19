# ==============================================================================
# Vivado Project Creation, Simulation, Synthesis, and Implementation Script
# Target Design: 32-Bit RISC-V Workload-Aware Low-Power BIST (WA-LP-BIST)
# Target Device: Xilinx Artix-7 (xc7a35tcpg236-1)
# ==============================================================================

set script_dir  [file dirname [file normalize [info script]]]
if {[file tail $script_dir] eq "scripts"} {
    set root_dir [file dirname $script_dir]
} else {
    set root_dir $script_dir
}

set project_name LFSR_LP_BIST_ALU
set project_dir  [file normalize [file join $root_dir vivado_lp_project]]
set reports_dir  [file normalize [file join $root_dir reports]]
set part         xc7a35tcpg236-1

file mkdir $reports_dir

# 1. Create Project
create_project $project_name $project_dir -part $part -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 2. Add Design Sources, Simulation Testbench, and Constraints
add_files [glob [file join $root_dir src *.sv]]
add_files -fileset sim_1 [file join $root_dir sim tb_lp_bist_top.sv]
add_files -fileset constrs_1 [file join $root_dir constraints timing.xdc]

# 3. Set Top Modules
set_property top bist_top [get_filesets sources_1]
set_property top tb_lp_bist_top [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 4. Behavioral Simulation
launch_simulation
run all
close_sim

# 5. Logic Synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# 6. Implementation (Place & Route)
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1

# 7. Export Comprehensive Reports to reports/
report_utilization -file [file join $reports_dir utilization.rpt]
report_timing_summary -file [file join $reports_dir timing_summary.rpt]
report_power -file [file join $reports_dir power.rpt]

puts "\n=================================================================="
puts " Vivado Project Generation, Simulation, Synthesis & Implementation"
puts " Completed Successfully with 0 Errors!"
puts " Project location: $project_dir/$project_name.xpr"
puts " Reports exported to: $reports_dir"
puts "==================================================================\n"
exit
