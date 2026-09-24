# run_power_analysis.tcl — Activity-based power analysis for 3 BIST modes

# Open the post-route checkpoint
open_checkpoint post_route.dcp

# ============================================================
# STANDARD BIST
# ============================================================
puts "============================================================"
puts "POWER ANALYSIS: STANDARD BIST"
puts "============================================================"
reset_switching_activity -all
read_saif power_STD.saif -strip_path tb_power_char/dut
report_power -file power_report_STD.rpt
puts "STD power report generated."

# ============================================================
# STATIC AWA
# ============================================================
puts "============================================================"
puts "POWER ANALYSIS: STATIC AWA"
puts "============================================================"
reset_switching_activity -all
read_saif power_STATIC_AWA.saif -strip_path tb_power_char/dut
report_power -file power_report_STATIC_AWA.rpt
puts "STATIC AWA power report generated."

# ============================================================
# ADAPTIVE AWA
# ============================================================
puts "============================================================"
puts "POWER ANALYSIS: ADAPTIVE AWA"
puts "============================================================"
reset_switching_activity -all
read_saif power_ADAPTIVE_AWA.saif -strip_path tb_power_char/dut
report_power -file power_report_ADAPTIVE_AWA.rpt
puts "ADAPTIVE AWA power report generated."

puts ""
puts "============================================================"
puts "ALL POWER REPORTS GENERATED"
puts "============================================================"
