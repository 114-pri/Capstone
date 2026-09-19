# Timing constraint for 80 MHz system clock (12.5 ns period)
# Target Architecture: AMD Xilinx Artix-7 xc7a35tcpg236-1 (Speed Grade -1)
create_clock -period 12.500 -name clk -waveform {0.000 6.250} [get_ports clk]

# Input Delay Constraints
set_input_delay -clock clk -max 2.000 [get_ports {reset start bist_mode* fault_enable fault_type* fault_select* fault_is_internal fault_internal_target*}]
set_input_delay -clock clk -min 0.500 [get_ports {reset start bist_mode* fault_enable fault_type* fault_select* fault_is_internal fault_internal_target*}]

# Output Delay Constraints
set_output_delay -clock clk -max 2.000 [get_ports {pass fail test_done signature* total_transitions* peak_transitions*}]
set_output_delay -clock clk -min 0.500 [get_ports {pass fail test_done signature* total_transitions* peak_transitions*}]
