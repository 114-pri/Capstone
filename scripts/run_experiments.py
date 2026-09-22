import os
import subprocess
import csv
import re
import matplotlib.pyplot as plt
from collections import defaultdict

def run_simulation(log_file="sim_output.log"):
    print("Running Vivado simulation (this may take a few minutes)...")
    cmd = ["vivado", "-mode", "batch", "-source", "scripts/run_simulation.tcl"]
    try:
        with open(log_file, "w") as f:
            subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT, check=True)
        print("Simulation completed successfully.")
    except Exception as e:
        print(f"Error running simulation: {e}")
        print("If Vivado is not installed, you can provide a log file manually.")

def parse_log(log_file):
    results = []
    phases = {}
    fault_cov = {}
    
    if not os.path.exists(log_file):
        print(f"Log file {log_file} not found.")
        return results, phases, fault_cov

    with open(log_file, "r") as f:
        for line in f:
            if "CSV_OUT:" in line:
                # Format: CSV_OUT:SEED=0,MODE=0,PROF=0,WSA=8750,PEAK=50
                data = line.strip().split("CSV_OUT:")[1].split(",")
                entry = {}
                for item in data:
                    k, v = item.split("=")
                    entry[k] = int(v)
                results.append(entry)
            elif "PHASE_LOG:" in line:
                # Format: PHASE_LOG:P0=10,P1=20...
                data = line.strip().split("PHASE_LOG:")[1].split(",")
                for item in data:
                    k, v = item.split("=")
                    phases[k] = int(v)
            elif "FAULT_COV_OUT:" in line:
                data = line.strip().split("FAULT_COV_OUT:")[1].split(",")
                for item in data:
                    k, v = item.split("=")
                    fault_cov[k] = int(v)
                    
    return results, phases, fault_cov

def generate_csv(results, output_csv="reports/wsa_results.csv"):
    if not results:
        return
    
    os.makedirs("reports", exist_ok=True)
    with open(output_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["SEED", "MODE", "PROF", "WSA", "PEAK"])
        writer.writeheader()
        writer.writerows(results)
    print(f"Saved {output_csv}")

def generate_plots(results, phases, fault_cov):
    if not results:
        return
        
    os.makedirs("reports", exist_ok=True)
    
    # 1. WSA Comparison (Average across seeds)
    mode_wsa = defaultdict(list)
    mode_peak = defaultdict(list)
    
    for r in results:
        label = f"Mode {r['MODE']}"
        if r['MODE'] == 2:
            label += f" Prof {r['PROF']}"
        mode_wsa[label].append(r['WSA'])
        mode_peak[label].append(r['PEAK'])
        
    labels = list(mode_wsa.keys())
    avg_wsa = [sum(mode_wsa[l])/len(mode_wsa[l]) for l in labels]
    avg_peak = [sum(mode_peak[l])/len(mode_peak[l]) for l in labels]
    
    plt.figure(figsize=(10, 6))
    plt.bar(labels, avg_wsa, color=['blue', 'orange', 'green', 'red'])
    plt.title("Average Weighted Switching Activity (WSA) by Mode")
    plt.ylabel("Transitions")
    plt.savefig("reports/plot_avg_wsa.png")
    plt.close()
    
    plt.figure(figsize=(10, 6))
    plt.bar(labels, avg_peak, color=['blue', 'orange', 'green', 'red'])
    plt.title("Peak Switching Activity by Mode")
    plt.ylabel("Peak Transitions")
    plt.savefig("reports/plot_peak_wsa.png")
    plt.close()
    
    if phases:
        plt.figure(figsize=(8, 8))
        phase_labels = [f"Phase {i}" for i in range(6)]
        phase_vals = [phases.get(f"P{i}", 0) for i in range(6)]
        plt.pie(phase_vals, labels=phase_labels, autopct='%1.1f%%')
        plt.title("Transitions by Test Phase (Adaptive Mode)")
        plt.savefig("reports/plot_phases.png")
        plt.close()
        
    print("Generated plots in reports/ directory.")

if __name__ == "__main__":
    log_path = "sim_output.log"
    # run_simulation(log_path) # Uncomment to run actual vivado simulation
    
    # If there's no log file, create a dummy one for demonstration
    if not os.path.exists(log_path):
        print("No simulation log found. Generating a mock log for plotting...")
        with open(log_path, "w") as f:
            for s in range(5):
                f.write(f"CSV_OUT:SEED={s},MODE=0,PROF=0,WSA={8500 + s*50},PEAK=50\n")
                f.write(f"CSV_OUT:SEED={s},MODE=1,PROF=0,WSA={6500 + s*30},PEAK=45\n")
                f.write(f"CSV_OUT:SEED={s},MODE=2,PROF=0,WSA={4500 + s*20},PEAK=28\n")
                f.write(f"CSV_OUT:SEED={s},MODE=2,PROF=1,WSA={4200 + s*10},PEAK=25\n")
            f.write("PHASE_LOG:P0=100,P1=500,P2=1500,P3=2000,P4=100,P5=0\n")
            f.write("FAULT_COV_OUT:DETECTED=5,TOTAL=5\n")
            
    results, phases, fault_cov = parse_log(log_path)
    generate_csv(results)
    generate_plots(results, phases, fault_cov)
    
    if fault_cov:
        print(f"Fault Coverage: {fault_cov.get('DETECTED', 0)} / {fault_cov.get('TOTAL', 1)} detected.")
