$FINAL_DIR = "final_results"
$beh_text = Get-Content "$FINAL_DIR\final_behavioral_report.txt" -Raw
$util_text = Get-Content "$FINAL_DIR\final_utilization.rpt" -Raw
$tim_text = Get-Content "$FINAL_DIR\final_timing_summary.rpt" -Raw
$drc_text = Get-Content "$FINAL_DIR\final_drc.rpt" -Raw

$pwr_std = Get-Content "$FINAL_DIR\final_power_STD.rpt" -Raw
$pwr_stat = Get-Content "$FINAL_DIR\final_power_STATIC_AWA.rpt" -Raw
$pwr_adap = Get-Content "$FINAL_DIR\final_power_ADAPTIVE_AWA.rpt" -Raw

$std_trans = 0; $stat_trans = 0; $adap_trans = 0
$pa_act = 0; $pa_deact = 0
$std_fc = 0.0; $awa_fc = 0.0

if ($beh_text -match 'Standard total transitions\s*:\s*(\d+)') { $std_trans = [int]$matches[1] }
if ($beh_text -match 'Static AWA total transitions\s*:\s*(\d+)') { $stat_trans = [int]$matches[1] }
if ($beh_text -match 'Adaptive AWA total transitions\s*:\s*(\d+)') { $adap_trans = [int]$matches[1] }
if ($beh_text -match 'Total autonomous PA activations\s*:\s*(\d+)') { $pa_act = [int]$matches[1] }
if ($beh_text -match 'Total autonomous PA deactivations\s*:\s*(\d+)') { $pa_deact = [int]$matches[1] }

if ($beh_text -match 'Standard:[\s\S]*?Coverage\s*:\s*([\d\.]+)') { $std_fc = [float]$matches[1] }
if ($beh_text -match 'AWA:[\s\S]*?Coverage\s*:\s*([\d\.]+)') { $awa_fc = [float]$matches[1] }

$stat_red = 0.0; $adap_red = 0.0; $add_red = 0.0
if ($std_trans -gt 0) {
    $stat_red = ($std_trans - $stat_trans) * 100.0 / $std_trans
    $adap_red = ($std_trans - $adap_trans) * 100.0 / $std_trans
    $add_red = ($stat_trans - $adap_trans) * 100.0 / $std_trans
}

$beh_std_pass = if ($std_trans -eq 170504) { "PASS" } else { "FAIL (DIFFERENT)" }
$beh_stat_pass = if ($stat_trans -eq 84087) { "PASS" } else { "FAIL (DIFFERENT)" }
$beh_adap_pass = if ($adap_trans -eq 81982) { "PASS" } else { "FAIL (DIFFERENT)" }
$fc_pass = if ($std_fc -eq 100.0 -and $awa_fc -eq 100.0) { "PASS" } else { "FAIL" }
$sanity_pass = if ($pa_act -eq 38 -and $pa_deact -eq 33) { "PASS" } else { "FAIL" }

function Extract-Util($pattern, $text) {
    if ($text -match $pattern) { return $matches[1].Trim() }
    return "0"
}

$lut = Extract-Util '\|\s*Slice LUTs\s*\|\s*(\d+)', $util_text
$ff = Extract-Util '\|\s*Slice Registers\s*\|\s*(\d+)', $util_text
$carry4 = Extract-Util '\|\s*CARRY4\s*\|\s*(\d+)', $util_text
$bram = Extract-Util '\|\s*Block RAM Tile\s*\|\s*([\d\.]+)', $util_text
$dsp = Extract-Util '\|\s*DSPs\s*\|\s*(\d+)', $util_text
$bufg = Extract-Util '\|\s*BUFGCTRL\s*\|\s*(\d+)', $util_text
$iob = Extract-Util '\|\s*Bonded IOB\s*\|\s*(\d+)', $util_text
$slices = Extract-Util '\|\s*Slices\s*\|\s*(\d+)', $util_text

$wns = 0.0; $tns = 0.0; $whs = 0.0; $ths = 0.0; $setup_fail = 0; $hold_fail = 0

if ($tim_text -match 'clk\s+([-\d\.]+)\s+([-\d\.]+)\s+(\d+)\s+(\d+)\s+([-\d\.]+)\s+([-\d\.]+)\s+(\d+)') {
    $wns = [float]$matches[1]
    $tns = [float]$matches[2]
    $setup_fail = [int]$matches[3]
    $whs = [float]$matches[5]
    $ths = [float]$matches[6]
    $hold_fail = [int]$matches[7]
}

$failing = $setup_fail + $hold_fail
$timing_pass = if ($wns -ge 0 -and $tns -eq 0 -and $whs -ge 0 -and $ths -eq 0 -and $failing -eq 0) { "PASS" } else { "FAIL" }

function Get-Power($text) {
    $dyn = 0.0; $stat = 0.0; $tot = 0.0
    if ($text -match '\|\s*Dynamic\s*\(W\)\s*\|\s*([\d\.]+)') { $dyn = [float]$matches[1] * 1000.0 }
    if ($text -match '\|\s*Device Static\s*\(W\)\s*\|\s*([\d\.]+)') { $stat = [float]$matches[1] * 1000.0 }
    if ($text -match '\|\s*Total On-Chip Power\s*\(W\)\s*\|\s*([\d\.]+)') { $tot = [float]$matches[1] * 1000.0 }
    return @($dyn, $stat, $tot)
}

$p_std = Get-Power $pwr_std
$p_stat = Get-Power $pwr_stat
$p_adap = Get-Power $pwr_adap

$std_dyn = $p_std[0]; $std_stat = $p_std[1]; $std_tot = $p_std[2]
$stat_dyn = $p_stat[0]; $stat_stat = $p_stat[1]; $stat_tot = $p_stat[2]
$adap_dyn = $p_adap[0]; $adap_stat = $p_adap[1]; $adap_tot = $p_adap[2]

$pwr_dyn_stat_red = if ($std_dyn -gt 0) { ($std_dyn - $stat_dyn) * 100.0 / $std_dyn } else { 0 }
$pwr_dyn_adap_red = if ($std_dyn -gt 0) { ($std_dyn - $adap_dyn) * 100.0 / $std_dyn } else { 0 }
$pwr_tot_stat_red = if ($std_tot -gt 0) { ($std_tot - $stat_tot) * 100.0 / $std_tot } else { 0 }
$pwr_tot_adap_red = if ($std_tot -gt 0) { ($std_tot - $adap_tot) * 100.0 / $std_tot } else { 0 }

$drc_errors = ([regex]::Matches($drc_text, '\(Error\)')).Count
$drc_cw = ([regex]::Matches($drc_text, '\(Critical Warning\)')).Count
$drc_warn = ([regex]::Matches($drc_text, '\(Warning\)')).Count

$final_pass = if ($beh_std_pass -eq "PASS" -and $beh_stat_pass -eq "PASS" -and $beh_adap_pass -eq "PASS" -and $fc_pass -eq "PASS" -and $sanity_pass -eq "PASS" -and $timing_pass -eq "PASS") { "PASS" } else { "FAIL" }

$out = @"
========================================================
FINAL AWA-LP-BIST VALIDATION SUMMARY
========================================================

Behavior:
  Standard correctness: $beh_std_pass
  Static AWA correctness: $beh_stat_pass
  Adaptive AWA correctness: $beh_adap_pass
  Fault coverage: $fc_pass
  Adaptive controller sanity: $sanity_pass

Switching:
  Standard: $std_trans transitions
  Static AWA: $stat_trans transitions
  Adaptive AWA: $adap_trans transitions
  Static reduction: $([math]::Round($stat_red, 2))%
  Adaptive reduction: $([math]::Round($adap_red, 2))%
  Additional adaptive contribution: $([math]::Round($add_red, 2))%

Hardware:
  LUT: $lut
  FF: $ff
  CARRY4: $carry4
  BRAM: $bram
  DSP: $dsp
  BUFG: $bufg
  IOB: $iob
  Slices: $slices

Timing:
  WNS: $([math]::Round($wns, 3)) ns
  TNS: $([math]::Round($tns, 3)) ns
  WHS: $([math]::Round($whs, 3)) ns
  THS: $([math]::Round($ths, 3)) ns
  Failing endpoints: $failing
  Frequency: 71.4 MHz
  Timing status: $timing_pass

Power:
  Standard: Dynamic=$([math]::Round($std_dyn, 0))mW, Static=$([math]::Round($std_stat, 0))mW, Total=$([math]::Round($std_tot, 0))mW
  Static AWA: Dynamic=$([math]::Round($stat_dyn, 0))mW, Static=$([math]::Round($stat_stat, 0))mW, Total=$([math]::Round($stat_tot, 0))mW
  Adaptive AWA: Dynamic=$([math]::Round($adap_dyn, 0))mW, Static=$([math]::Round($adap_stat, 0))mW, Total=$([math]::Round($adap_tot, 0))mW
  Dynamic reduction (Stat/Adap): $([math]::Round($pwr_dyn_stat_red, 2))% / $([math]::Round($pwr_dyn_adap_red, 2))%
  Total reduction (Stat/Adap): $([math]::Round($pwr_tot_stat_red, 2))% / $([math]::Round($pwr_tot_adap_red, 2))%

DRC:
  Errors: $drc_errors
  Critical warnings: $drc_cw
  I/O planning warnings: $drc_warn (All warnings shown)

FINAL PROJECT STATUS:
  $final_pass

========================================================
"@

Set-Content -Path "FINAL_MASTER_SUMMARY.txt" -Value $out
Copy-Item -Path "FINAL_MASTER_SUMMARY.txt" -Destination "$FINAL_DIR\FINAL_MASTER_SUMMARY.txt" -Force

Write-Host $out

$p1 = (Resolve-Path "final_validation.tcl").Path
$p2 = (Resolve-Path "FINAL_MASTER_SUMMARY.txt").Path
$p3 = (Resolve-Path "vivado_lp_project/LFSR_LP_BIST_ALU.runs/impl_1/bist_top_routed.dcp").Path
$tstamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host ""
Write-Host "1. Exact path to final_validation.tcl: $p1"
Write-Host "2. Exact path to FINAL_MASTER_SUMMARY.txt: $p2"
Write-Host "3. Exact implementation checkpoint used: $p3"
Write-Host "4. Exact timestamp of final validation: $tstamp"
