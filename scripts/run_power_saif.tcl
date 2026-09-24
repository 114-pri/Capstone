# run_power_saif.tcl — Generates SAIF files for all 3 modes and runs power analysis

# ============================================================
# STEP 1: Generate SAIF for each mode via XSim
# ============================================================
set modes {0 1 2}
set mode_names {STD STATIC_AWA ADAPTIVE_AWA}

foreach mode $modes mname $mode_names {
    puts "============================================================"
    puts "Generating SAIF for mode: $mname (POWER_MODE=$mode)"
    puts "============================================================"
    
    # Elaborate with the POWER_MODE generic
    exec E:/vivado/2025.2/Vivado/bin/xelab.bat \
        -prj sim_power.prj \
        -debug typical \
        --timescale 1ns/1ps \
        -generic_top "POWER_MODE=$mode" \
        -s "power_sim_${mname}" \
        work.tb_power_char

    # Create a TCL run script for this mode
    set fp [open "run_saif_${mname}.tcl" w]
    puts $fp "open_saif power_${mname}.saif"
    puts $fp "log_saif \[get_objects -r /tb_power_char/dut/*\]"
    puts $fp "run all"
    puts $fp "close_saif"
    puts $fp "quit"
    close $fp
    
    # Run the simulation with SAIF capture
    exec E:/vivado/2025.2/Vivado/bin/xsim.bat \
        "power_sim_${mname}" \
        -tclbatch "run_saif_${mname}.tcl"
    
    puts "SAIF generated: power_${mname}.saif"
}

puts ""
puts "============================================================"
puts "All SAIF files generated successfully."
puts "============================================================"

# ============================================================
# STEP 2: Power Analysis using post-route checkpoint
# ============================================================

puts ""
puts "============================================================"
puts "Starting Activity-Based Power Analysis"
puts "============================================================"

# Open the post-route checkpoint
open_checkpoint post_route.dcp

set power_results [list]

foreach mode $modes mname $mode_names {
    puts ""
    puts "------------------------------------------------------------"
    puts "Power Analysis: $mname"
    puts "------------------------------------------------------------"
    
    # Reset switching activity
    reset_switching_activity -all
    
    # Read SAIF
    read_saif "power_${mname}.saif" -strip_path tb_power_char/dut
    
    # Report power
    report_power -file "power_report_${mname}.rpt"
    
    puts "Power report generated: power_report_${mname}.rpt"
}

puts ""
puts "============================================================"
puts "POWER ANALYSIS COMPLETE"
puts "============================================================"
