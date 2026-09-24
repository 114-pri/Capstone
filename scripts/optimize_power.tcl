# ==============================================================================
# Vivado Power Optimization Script
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

if {[current_project -quiet] eq ""} {
    open_project $project_dir/$project_name.xpr
} else {
    puts "Project is already open in GUI. Proceeding with optimization..."
}

# 1. Configure Synthesis for Power Optimization
# Enabling aggressive gated clock conversion during synthesis
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION auto [get_runs synth_1]

# 2. Configure Implementation for Power Optimization
# Explicitly enable the post-opt_design power optimization step
set_property STEPS.POWER_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

# Optionally, you can also set the implementation strategy to power explore
# set_property STRATEGY Power_DefaultOpt [get_runs impl_1]

# Reset previous runs so Vivado is forced to re-synthesize and re-implement
reset_run synth_1
reset_run impl_1

# 3. Logic Synthesis
puts "Starting Logic Synthesis with Power Optimizations..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# 4. Implementation
puts "Starting Implementation with Power Optimizations..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1

# 5. Export Reports
file mkdir $reports_dir
report_utilization -file [file join $reports_dir utilization_power_opt.rpt]
report_timing_summary -file [file join $reports_dir timing_summary_power_opt.rpt]
report_power -file [file join $reports_dir power_power_opt.rpt]

puts "\n=================================================================="
puts " Power Optimization Flow Completed Successfully!"
puts " Reports exported to: $reports_dir"
puts "==================================================================\n"
exit
