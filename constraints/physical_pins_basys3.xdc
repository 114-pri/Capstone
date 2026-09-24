## Physical Pin Constraints for Digilent Basys 3 (Artix-7 xc7a35tcpg236-1)
## This file maps the BIST inputs/outputs to physical buttons, switches, and LEDs on the board.

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Buttons
# Using Center Button for Reset
set_property PACKAGE_PIN U18 [get_ports reset]						
	set_property IOSTANDARD LVCMOS33 [get_ports reset]
# Using Up Button for Start
set_property PACKAGE_PIN T18 [get_ports start]						
	set_property IOSTANDARD LVCMOS33 [get_ports start]

# Switches
# SW0, SW1: bist_mode
set_property PACKAGE_PIN V17 [get_ports {bist_mode[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {bist_mode[0]}]
set_property PACKAGE_PIN V16 [get_ports {bist_mode[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {bist_mode[1]}]

# SW2, SW3: profile_select
set_property PACKAGE_PIN W16 [get_ports {profile_select[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {profile_select[0]}]
set_property PACKAGE_PIN W17 [get_ports {profile_select[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {profile_select[1]}]

# SW4: fault_enable
set_property PACKAGE_PIN W15 [get_ports fault_enable]					
	set_property IOSTANDARD LVCMOS33 [get_ports fault_enable]

# SW5: fault_is_internal
set_property PACKAGE_PIN V15 [get_ports fault_is_internal]					
	set_property IOSTANDARD LVCMOS33 [get_ports fault_is_internal]

# SW6, SW7: fault_type
set_property PACKAGE_PIN W14 [get_ports {fault_type[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_type[0]}]
set_property PACKAGE_PIN W13 [get_ports {fault_type[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_type[1]}]

# SW8, SW9: fault_internal_target
set_property PACKAGE_PIN V2 [get_ports {fault_internal_target[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_internal_target[0]}]
set_property PACKAGE_PIN T3 [get_ports {fault_internal_target[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_internal_target[1]}]

# SW10 to SW14: fault_select
set_property PACKAGE_PIN T2 [get_ports {fault_select[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_select[0]}]
set_property PACKAGE_PIN R3 [get_ports {fault_select[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_select[1]}]
set_property PACKAGE_PIN W2 [get_ports {fault_select[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_select[2]}]
set_property PACKAGE_PIN U1 [get_ports {fault_select[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_select[3]}]
set_property PACKAGE_PIN T1 [get_ports {fault_select[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {fault_select[4]}]

# LEDs
# LED 0 (Right-most LED) - PASS (Green on most RGBs, but standard yellow/green here)
set_property PACKAGE_PIN U16 [get_ports pass]					
	set_property IOSTANDARD LVCMOS33 [get_ports pass]

# LED 1 - FAIL
set_property PACKAGE_PIN E19 [get_ports fail]					
	set_property IOSTANDARD LVCMOS33 [get_ports fail]

# LED 2 - TEST DONE
set_property PACKAGE_PIN U19 [get_ports test_done]					
	set_property IOSTANDARD LVCMOS33 [get_ports test_done]

# Ignore warnings for large multi-bit output ports (signature, transitions) since we 
# are intentionally leaving them unmapped on this small board (would need UART or ILA to view them)
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
