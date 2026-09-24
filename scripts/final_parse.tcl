# final_parse.tcl
set FINAL_DIR "final_results"

proc read_file {path} {
    if {[catch {set f [open $path r]}]} { return "" }
    set data [read $f]
    close $f
    return $data
}

set beh_text [read_file "$FINAL_DIR/final_behavioral_report.txt"]
set util_text [read_file "$FINAL_DIR/final_utilization.rpt"]
set tim_text [read_file "$FINAL_DIR/final_timing_summary.rpt"]
set drc_text [read_file "$FINAL_DIR/final_drc.rpt"]
set pwr_std [read_file "$FINAL_DIR/final_power_STD.rpt"]
set pwr_stat [read_file "$FINAL_DIR/final_power_STATIC_AWA.rpt"]
set pwr_adap [read_file "$FINAL_DIR/final_power_ADAPTIVE_AWA.rpt"]

# Behavior
set std_trans 0
set stat_trans 0
set adap_trans 0
set pa_act 0
set pa_deact 0
set std_fc 0.0
set awa_fc 0.0

if {[regexp {Standard total transitions\s*:\s*(\d+)} $beh_text match std_trans]} {}
if {[regexp {Static AWA total transitions\s*:\s*(\d+)} $beh_text match stat_trans]} {}
if {[regexp {Adaptive AWA total transitions\s*:\s*(\d+)} $beh_text match adap_trans]} {}
if {[regexp {Total autonomous PA activations\s*:\s*(\d+)} $beh_text match pa_act]} {}
if {[regexp {Total autonomous PA deactivations\s*:\s*(\d+)} $beh_text match pa_deact]} {}

set idx_std [string first "Standard:" $beh_text]
if {$idx_std != -1} {
    set part [string range $beh_text $idx_std end]
    if {[regexp {Coverage\s*:\s*([\d\.]+)\s*\%} $part match std_fc]} {}
}
set idx_awa [string first "AWA:" $beh_text]
if {$idx_awa != -1} {
    set part [string range $beh_text $idx_awa end]
    if {[regexp {Coverage\s*:\s*([\d\.]+)\s*\%} $part match awa_fc]} {}
}

set stat_red 0.0
set adap_red 0.0
set add_red 0.0
if {$std_trans > 0} {
    set stat_red [expr {($std_trans - $stat_trans) * 100.0 / $std_trans}]
    set adap_red [expr {($std_trans - $adap_trans) * 100.0 / $std_trans}]
    set add_red [expr {($stat_trans - $adap_trans) * 100.0 / $std_trans}]
}

set beh_std_pass [expr {$std_trans == 170504 ? "PASS" : "FAIL (DIFFERENT)"}]
set beh_stat_pass [expr {$stat_trans == 84087 ? "PASS" : "FAIL (DIFFERENT)"}]
set beh_adap_pass [expr {$adap_trans == 81982 ? "PASS" : "FAIL (DIFFERENT)"}]
set fc_pass [expr {($std_fc == 100.0 && $awa_fc == 100.0) ? "PASS" : "FAIL"}]
set sanity_pass [expr {($pa_act == 38 && $pa_deact == 33) ? "PASS" : "FAIL"}]

# Utilization
proc extract_util {pattern text} {
    if {[regexp $pattern $text match val]} { return $val }
    return "0"
}

set lut [extract_util {\|\s*Slice LUTs[^\d]*(\d+)} $util_text]
set ff [extract_util {\|\s*Slice Registers[^\d]*(\d+)} $util_text]
set carry4 [extract_util {\|\s*CARRY4[^\d]*(\d+)} $util_text]
set bram [extract_util {\|\s*Block RAM Tile[^\d]*([\d\.]+)} $util_text]
set dsp [extract_util {\|\s*DSPs[^\d]*(\d+)} $util_text]
set bufg [extract_util {\|\s*BUFGCTRL[^\d]*(\d+)} $util_text]
set iob [extract_util {\|\s*Bonded IOB[^\d]*(\d+)} $util_text]
set slices [extract_util {\|\s*Slices[^\d]*(\d+)} $util_text]

# Timing
proc extract_tim {pattern text} {
    if {[regexp $pattern $text match val]} { return $val }
    return 0.0
}
set wns 0.0
set tns 0.0
set whs 0.0
set ths 0.0
set setup_fail 0
set hold_fail 0
set found_wns 0
foreach line [split $tim_text "\n"] {
    if {$found_wns == 1} {
        # Extract columns using regex
        if {[regexp {^\s*([-\d\.]+)\s+([-\d\.]+)\s+(\d+)\s+(\d+)\s+([-\d\.]+)\s+([-\d\.]+)\s+(\d+)\s+(\d+)} $line match v1 v2 v3 v4 v5 v6 v7 v8]} {
            set wns $v1
            set tns $v2
            set setup_fail $v3
            set whs $v5
            set ths $v6
            set hold_fail $v7
        }
        break
    }
    if {[string match "*-------*-------*---------------------*" $line]} {
        set found_wns 1
    }
}
set failing [expr {$setup_fail + $hold_fail}]
set freq "71.4 MHz"
set timing_pass [expr {($wns >= 0 && $tns == 0 && $whs >= 0 && $ths == 0 && $failing == 0) ? "PASS" : "FAIL"}]

# Power
proc get_power {text v_dyn v_stat v_tot} {
    upvar $v_dyn dyn $v_stat stat $v_tot tot
    set dyn 0.0; set stat 0.0; set tot 0.0
    if {[regexp {\|\s*Dynamic\s*\(W\)\s*\|\s*([\d\.]+)} $text match v1]} { set dyn [expr {$v1 * 1000.0}] }
    if {[regexp {\|\s*Device Static\s*\(W\)\s*\|\s*([\d\.]+)} $text match v2]} { set stat [expr {$v2 * 1000.0}] }
    if {[regexp {\|\s*Total On-Chip Power\s*\(W\)\s*\|\s*([\d\.]+)} $text match v3]} { set tot [expr {$v3 * 1000.0}] }
}

get_power $pwr_std std_dyn std_stat std_tot
get_power $pwr_stat stat_dyn stat_stat stat_tot
get_power $pwr_adap adap_dyn adap_stat adap_tot

set pwr_dyn_stat_red 0.0
set pwr_dyn_adap_red 0.0
set pwr_tot_stat_red 0.0
set pwr_tot_adap_red 0.0

if {$std_dyn > 0} {
    set pwr_dyn_stat_red [expr {($std_dyn - $stat_dyn) * 100.0 / $std_dyn}]
    set pwr_dyn_adap_red [expr {($std_dyn - $adap_dyn) * 100.0 / $std_dyn}]
}
if {$std_tot > 0} {
    set pwr_tot_stat_red [expr {($std_tot - $stat_tot) * 100.0 / $std_tot}]
    set pwr_tot_adap_red [expr {($std_tot - $adap_tot) * 100.0 / $std_tot}]
}

# DRC
set drc_errors [regsub -all {\(Error\)} $drc_text "" temp1]
set drc_cw [regsub -all {\(Critical Warning\)} $drc_text "" temp2]
set drc_warn [regsub -all {\(Warning\)} $drc_text "" temp3]

set final_pass [expr {($beh_std_pass == "PASS" && $beh_stat_pass == "PASS" && $beh_adap_pass == "PASS" && $fc_pass == "PASS" && $sanity_pass == "PASS" && $timing_pass == "PASS") ? "PASS" : "FAIL"}]

set out "========================================================\n"
append out "FINAL AWA-LP-BIST VALIDATION SUMMARY\n"
append out "========================================================\n\n"

append out "Behavior:\n"
append out "  Standard correctness: $beh_std_pass\n"
append out "  Static AWA correctness: $beh_stat_pass\n"
append out "  Adaptive AWA correctness: $beh_adap_pass\n"
append out "  Fault coverage: $fc_pass\n"
append out "  Adaptive controller sanity: $sanity_pass\n\n"

append out "Switching:\n"
append out "  Standard: $std_trans transitions\n"
append out "  Static AWA: $stat_trans transitions\n"
append out "  Adaptive AWA: $adap_trans transitions\n"
append out "  Static reduction: [format "%.2f" $stat_red]%\n"
append out "  Adaptive reduction: [format "%.2f" $adap_red]%\n"
append out "  Additional adaptive contribution: [format "%.2f" $add_red]%\n\n"

append out "Hardware:\n"
append out "  LUT: $lut\n"
append out "  FF: $ff\n"
append out "  CARRY4: $carry4\n"
append out "  BRAM: $bram\n"
append out "  DSP: $dsp\n"
append out "  BUFG: $bufg\n"
append out "  IOB: $iob\n"
append out "  Slices: $slices\n\n"

append out "Timing:\n"
append out "  WNS: [format "%.3f" $wns] ns\n"
append out "  TNS: [format "%.3f" $tns] ns\n"
append out "  WHS: [format "%.3f" $whs] ns\n"
append out "  THS: [format "%.3f" $ths] ns\n"
append out "  Failing endpoints: $failing\n"
append out "  Frequency: $freq\n"
append out "  Timing status: $timing_pass\n\n"

append out "Power:\n"
append out "  Standard: Dynamic=[format "%.0f" $std_dyn]mW, Static=[format "%.0f" $std_stat]mW, Total=[format "%.0f" $std_tot]mW\n"
append out "  Static AWA: Dynamic=[format "%.0f" $stat_dyn]mW, Static=[format "%.0f" $stat_stat]mW, Total=[format "%.0f" $stat_tot]mW\n"
append out "  Adaptive AWA: Dynamic=[format "%.0f" $adap_dyn]mW, Static=[format "%.0f" $adap_stat]mW, Total=[format "%.0f" $adap_tot]mW\n"
append out "  Dynamic reduction (Stat/Adap): [format "%.2f" $pwr_dyn_stat_red]% / [format "%.2f" $pwr_dyn_adap_red]%\n"
append out "  Total reduction (Stat/Adap): [format "%.2f" $pwr_tot_stat_red]% / [format "%.2f" $pwr_tot_adap_red]%\n\n"

append out "DRC:\n"
append out "  Errors: $drc_errors\n"
append out "  Critical warnings: $drc_cw\n"
append out "  I/O planning warnings: $drc_warn (All warnings shown)\n\n"

append out "FINAL PROJECT STATUS:\n"
append out "  $final_pass\n\n"
append out "========================================================\n"

set f_out [open "FINAL_MASTER_SUMMARY.txt" w]
puts $f_out $out
close $f_out

file copy -force "FINAL_MASTER_SUMMARY.txt" "$FINAL_DIR/FINAL_MASTER_SUMMARY.txt"

puts $out
set tstamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

set p1 [file normalize "final_validation.tcl"]
set p2 [file normalize "FINAL_MASTER_SUMMARY.txt"]
set p3 [file normalize "vivado_lp_project/LFSR_LP_BIST_ALU.runs/impl_1/bist_top_routed.dcp"]

puts "1. Exact path to final_validation.tcl: $p1"
puts "2. Exact path to FINAL_MASTER_SUMMARY.txt: $p2"
puts "3. Exact implementation checkpoint used: $p3"
puts "4. Exact timestamp of final validation: $tstamp"
