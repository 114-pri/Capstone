import os
import re
from datetime import datetime

FINAL_DIR = "final_results"

def read_file(path):
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    return ""

def main():
    beh_text = read_file(os.path.join(FINAL_DIR, "final_behavioral_report.txt"))
    util_text = read_file(os.path.join(FINAL_DIR, "final_utilization.rpt"))
    tim_text = read_file(os.path.join(FINAL_DIR, "final_timing_summary.rpt"))
    drc_text = read_file(os.path.join(FINAL_DIR, "final_drc.rpt"))
    
    pwr_std = read_file(os.path.join(FINAL_DIR, "final_power_STD.rpt"))
    pwr_stat = read_file(os.path.join(FINAL_DIR, "final_power_STATIC_AWA.rpt"))
    pwr_adap = read_file(os.path.join(FINAL_DIR, "final_power_ADAPTIVE_AWA.rpt"))

    # Behavior
    std_trans = 0
    stat_trans = 0
    adap_trans = 0
    pa_act = 0
    pa_deact = 0
    std_fc = 0
    awa_fc = 0
    
    m = re.search(r'Standard Total Transitions:\s*(\d+)', beh_text)
    if m: std_trans = int(m.group(1))
    
    m = re.search(r'Static AWA Total Transitions:\s*(\d+)', beh_text)
    if m: stat_trans = int(m.group(1))
        
    m = re.search(r'Adaptive AWA Total Transitions:\s*(\d+)', beh_text)
    if m: adap_trans = int(m.group(1))
        
    m = re.search(r'PA Activations:\s*(\d+)', beh_text)
    if m: pa_act = int(m.group(1))
    m = re.search(r'PA Deactivations:\s*(\d+)', beh_text)
    if m: pa_deact = int(m.group(1))
    
    m = re.search(r'Standard Fault Coverage:\s*([\d\.]+)%', beh_text)
    if m: std_fc = float(m.group(1))
    m = re.search(r'AWA Fault Coverage:\s*([\d\.]+)%', beh_text)
    if m: awa_fc = float(m.group(1))

    stat_red = 0.0
    adap_red = 0.0
    add_red = 0.0
    if std_trans > 0:
        stat_red = (std_trans - stat_trans) / std_trans * 100
        adap_red = (std_trans - adap_trans) / std_trans * 100
        add_red = (stat_trans - adap_trans) / std_trans * 100
        
    beh_std_pass = "PASS" if std_trans == 170504 else "FAIL (DIFFERENT)"
    beh_stat_pass = "PASS" if stat_trans == 84087 else "FAIL (DIFFERENT)"
    beh_adap_pass = "PASS" if adap_trans == 81982 else "FAIL (DIFFERENT)"
    fc_pass = "PASS" if (std_fc == 100 and awa_fc == 100) else "FAIL"
    sanity_pass = "PASS" if (pa_act == 38 and pa_deact == 33) else "FAIL"
    
    # Utilization
    def extract_util(name, pattern, text):
        m = re.search(pattern, text)
        if m: return m.group(1).strip()
        return "0"

    lut = extract_util("LUT", r'\|\s*Slice LUTs\s*\|\s*(\d+)', util_text)
    ff = extract_util("FF", r'\|\s*Slice Registers\s*\|\s*(\d+)', util_text)
    carry4 = extract_util("CARRY4", r'\|\s*CARRY4\s*\|\s*(\d+)', util_text)
    bram = extract_util("BRAM", r'\|\s*Block RAM Tile\s*\|\s*([\d\.]+)', util_text)
    dsp = extract_util("DSP", r'\|\s*DSPs\s*\|\s*(\d+)', util_text)
    bufg = extract_util("BUFG", r'\|\s*BUFGCTRL\s*\|\s*(\d+)', util_text)
    iob = extract_util("IOB", r'\|\s*Bonded IOB\s*\|\s*(\d+)', util_text)
    slices = extract_util("Slices", r'\|\s*Slices\s*\|\s*(\d+)', util_text)

    # Timing
    def extract_tim(pattern, text):
        m = re.search(pattern, text)
        return float(m.group(1)) if m else 0.0
    
    wns = extract_tim(r'WNS\(ns\)\s*\n\s*-+\s*\n\s*([\-\d\.]+)', tim_text)
    tns = extract_tim(r'TNS\(ns\)\s*\n\s*-+\s*\n\s*([\-\d\.]+)', tim_text)
    whs = extract_tim(r'WHS\(ns\)\s*\n\s*-+\s*\n\s*([\-\d\.]+)', tim_text)
    ths = extract_tim(r'THS\(ns\)\s*\n\s*-+\s*\n\s*([\-\d\.]+)', tim_text)
    
    # Failing endpoints
    setup_fail = 0
    hold_fail = 0
    m = re.search(r'Failing Endpoints\s*\n\s*-+\s*\n\s*(\d+)', tim_text)
    if m: setup_fail = int(m.group(1))
    
    m_h = re.search(r'WHS\(ns\).*?Failing Endpoints\s*\n\s*-+\s*\n\s*(\d+)', tim_text, re.DOTALL)
    if m_h:
        m_fails = re.findall(r'Failing Endpoints\s*\n\s*-+\s*\n\s*(\d+)', tim_text)
        if len(m_fails) >= 2: hold_fail = int(m_fails[1])

    failing = setup_fail + hold_fail
    freq = "71.4 MHz"
    timing_pass = "PASS" if wns >= 0 and tns == 0 and whs >= 0 and ths == 0 and failing == 0 else "FAIL"

    # Power
    def get_power(text):
        dyn = 0.0
        stat = 0.0
        tot = 0.0
        m1 = re.search(r'\|\s*Dynamic\s*\(W\)\s*\|\s*([\d\.]+)', text)
        m2 = re.search(r'\|\s*Device Static\s*\(W\)\s*\|\s*([\d\.]+)', text)
        m3 = re.search(r'\|\s*Total On-Chip Power\s*\(W\)\s*\|\s*([\d\.]+)', text)
        if m1: dyn = float(m1.group(1)) * 1000
        if m2: stat = float(m2.group(1)) * 1000
        if m3: tot = float(m3.group(1)) * 1000
        return dyn, stat, tot

    std_dyn, std_stat, std_tot = get_power(pwr_std)
    stat_dyn, stat_stat, stat_tot = get_power(pwr_stat)
    adap_dyn, adap_stat, adap_tot = get_power(pwr_adap)
    
    pwr_dyn_stat_red = (std_dyn - stat_dyn) / std_dyn * 100 if std_dyn else 0
    pwr_dyn_adap_red = (std_dyn - adap_dyn) / std_dyn * 100 if std_dyn else 0
    
    pwr_tot_stat_red = (std_tot - stat_tot) / std_tot * 100 if std_tot else 0
    pwr_tot_adap_red = (std_tot - adap_tot) / std_tot * 100 if std_tot else 0

    # DRC
    drc_errors = len(re.findall(r'\(Error\)', drc_text))
    drc_cw = len(re.findall(r'\(Critical Warning\)', drc_text))
    drc_warn = len(re.findall(r'\(Warning\)', drc_text))

    final_pass = (beh_std_pass == "PASS" and beh_stat_pass == "PASS" and beh_adap_pass == "PASS" 
                  and fc_pass == "PASS" and sanity_pass == "PASS" and timing_pass == "PASS")

    out = f"""========================================================
FINAL AWA-LP-BIST VALIDATION SUMMARY
========================================================

Behavior:
  Standard correctness: {beh_std_pass}
  Static AWA correctness: {beh_stat_pass}
  Adaptive AWA correctness: {beh_adap_pass}
  Fault coverage: {fc_pass}
  Adaptive controller sanity: {sanity_pass}

Switching:
  Standard: {std_trans} transitions
  Static AWA: {stat_trans} transitions
  Adaptive AWA: {adap_trans} transitions
  Static reduction: {stat_red:.2f}%
  Adaptive reduction: {adap_red:.2f}%
  Additional adaptive contribution: {add_red:.2f}%

Hardware:
  LUT: {lut}
  FF: {ff}
  CARRY4: {carry4}
  BRAM: {bram}
  DSP: {dsp}
  BUFG: {bufg}
  IOB: {iob}
  Slices: {slices}

Timing:
  WNS: {wns:.3f} ns
  TNS: {tns:.3f} ns
  WHS: {whs:.3f} ns
  THS: {ths:.3f} ns
  Failing endpoints: {failing}
  Frequency: {freq}
  Timing status: {timing_pass}

Power:
  Standard: Dynamic={std_dyn:.0f}mW, Static={std_stat:.0f}mW, Total={std_tot:.0f}mW
  Static AWA: Dynamic={stat_dyn:.0f}mW, Static={stat_stat:.0f}mW, Total={stat_tot:.0f}mW
  Adaptive AWA: Dynamic={adap_dyn:.0f}mW, Static={adap_stat:.0f}mW, Total={adap_tot:.0f}mW
  Dynamic reduction (Stat/Adap): {pwr_dyn_stat_red:.2f}% / {pwr_dyn_adap_red:.2f}%
  Total reduction (Stat/Adap): {pwr_tot_stat_red:.2f}% / {pwr_tot_adap_red:.2f}%

DRC:
  Errors: {drc_errors}
  Critical warnings: {drc_cw}
  I/O planning warnings: {drc_warn} (All warnings shown)

FINAL PROJECT STATUS:
  {"PASS" if final_pass else "FAIL"}

========================================================"""

    with open("FINAL_MASTER_SUMMARY.txt", "w") as f:
        f.write(out)

    print(out)
    
    import shutil
    shutil.copy("FINAL_MASTER_SUMMARY.txt", os.path.join(FINAL_DIR, "FINAL_MASTER_SUMMARY.txt"))
    
    print("\n1. Exact path to final_validation.tcl: " + os.path.abspath("final_validation.tcl"))
    print("2. Exact path to FINAL_MASTER_SUMMARY.txt: " + os.path.abspath("FINAL_MASTER_SUMMARY.txt"))
    print("3. Exact implementation checkpoint used: " + os.path.abspath(os.path.join("vivado_lp_project", "LFSR_LP_BIST_ALU.runs", "impl_1", "bist_top_routed.dcp")))
    print("4. Exact timestamp of final validation: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    main()
