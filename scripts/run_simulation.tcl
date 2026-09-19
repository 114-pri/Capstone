# ==============================================================================
# Simulation Script for Workload-Aware BIST (WA-LP-BIST)
# ==============================================================================

set script_dir  [file dirname [file normalize [info script]]]
if {[file tail $script_dir] eq "scripts"} {
    set root_dir [file dirname $script_dir]
} else {
    set root_dir $script_dir
}

set project_xpr [file normalize [file join $root_dir vivado_lp_project LFSR_LP_BIST_ALU.xpr]]

if {[file exists $project_xpr]} {
    open_project $project_xpr
    launch_simulation
    run all
    close_sim
} else {
    set project_dir [file normalize [file join $root_dir vivado_sim_run]]
    set part        xc7a35tcpg236-1

    create_project LFSR_LP_BIST_SIM $project_dir -part $part -force
    set_property target_language Verilog [current_project]
    set_property simulator_language Mixed [current_project]

    add_files [glob [file join $root_dir src *.sv]]
    add_files -fileset sim_1 [file join $root_dir sim tb_lp_bist_top.sv]
    add_files -fileset constrs_1 [file join $root_dir constraints timing.xdc]

    set_property top bist_top [get_filesets sources_1]
    set_property top tb_lp_bist_top [get_filesets sim_1]

    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1

    launch_simulation
    run all
    close_sim
}
exit
