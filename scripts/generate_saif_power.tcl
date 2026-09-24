# ==============================================================================
# Script to Generate SAIF Simulation Activity and Run Vector-Based Power Analysis
# ==============================================================================

set script_dir  [file dirname [file normalize [info script]]]
if {[file tail $script_dir] eq "scripts"} {
    set root_dir [file dirname $script_dir]
} else {
    set root_dir $script_dir
}

set project_dir [file normalize [file join $root_dir vivado_lp_project]]
set reports_dir [file normalize [file join $root_dir reports]]
set saif_file   [file normalize [file join $reports_dir activity.saif]]

file mkdir $reports_dir

# Open Project
if {[current_project -quiet] eq ""} {
    open_project [file join $project_dir LFSR_LP_BIST_ALU.xpr]
} else {
    puts "Project is already open in GUI. Proceeding with SAIF generation..."
}

# 1. Run Simulation with Native SAIF Dumping
launch_simulation
open_saif $saif_file
log_saif [get_objects -r /tb_lp_bist_top/dut/*]
run all
close_saif
close_sim

# 2. Open Implemented Design and Apply SAIF Vector Activity
open_run impl_1
read_saif $saif_file
report_power -file [file join $reports_dir power_saif_vector_based.rpt]

puts "\n=================================================================="
puts " Vector-Based SAIF Power Analysis Completed Successfully!"
puts " Report saved to: [file join $reports_dir power_saif_vector_based.rpt]"
puts "==================================================================\n"
exit
