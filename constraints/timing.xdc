# Timing constraint for 71.4 MHz system clock (14.0 ns period)
# Target Architecture: AMD Xilinx Artix-7 xc7a35tcpg236-1 (Speed Grade -1)
create_clock -period 14.000 -name clk -waveform {0.000 7.000} [get_ports clk]

# Input Delay Constraints
set_input_delay -clock clk -max 2.000 [get_ports {reset start bist_mode* profile_select* fault_enable fault_type* fault_select* fault_is_internal fault_internal_target*}]
set_input_delay -clock clk -min 0.500 [get_ports {reset start bist_mode* profile_select* fault_enable fault_type* fault_select* fault_is_internal fault_internal_target*}]

# Output Delay Constraints
set_output_delay -clock clk -max 2.000 [get_ports {pass fail test_done signature* total_transitions* peak_transitions*}]
set_output_delay -clock clk -min 0.500 [get_ports {pass fail test_done signature* total_transitions* peak_transitions*}]

# Bypass DRC errors for unassigned pins and IO standards (for power/area estimation without a physical board)
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
