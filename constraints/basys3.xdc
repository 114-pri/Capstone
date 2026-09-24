## Basys 3 Master XDC

## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 14.00 -waveform {0 7.00} [get_ports clk]

## Switches
set_property PACKAGE_PIN V17 [get_ports {mode_sw[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mode_sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {mode_sw[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mode_sw[1]}]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {led_running}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led_running}]
set_property PACKAGE_PIN E19 [get_ports {led_done}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led_done}]
set_property PACKAGE_PIN U19 [get_ports {led_pass}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led_pass}]
set_property PACKAGE_PIN V19 [get_ports {led_fail}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led_fail}]
set_property PACKAGE_PIN W18 [get_ports {led_pa}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led_pa}]
set_property PACKAGE_PIN U15 [get_ports {led_fb}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led_fb}]

## Buttons
set_property PACKAGE_PIN U18 [get_ports reset_btn]						
	set_property IOSTANDARD LVCMOS33 [get_ports reset_btn]
set_property PACKAGE_PIN T18 [get_ports start_btn]						
	set_property IOSTANDARD LVCMOS33 [get_ports start_btn]
 
## USB-RS232 Interface
set_property PACKAGE_PIN A18 [get_ports uart_tx]						
	set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
