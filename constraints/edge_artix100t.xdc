# EDGE Artix-7 XC7A100T FTG256 Demo Constraints

# 50 MHz Clock
set_property PACKAGE_PIN N11 [get_ports clk_50mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz -waveform {0.000 10.000} [get_ports clk_50mhz]

# Reset Button (BTNC)
set_property PACKAGE_PIN M14 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Start Button (BTN0)
set_property PACKAGE_PIN L13 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

# Mode Switches
set_property PACKAGE_PIN L5 [get_ports {mode[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode[0]}]
set_property PACKAGE_PIN L4 [get_ports {mode[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode[1]}]

# LEDs (0 to 7)
set_property PACKAGE_PIN J3 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN H3 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN J1 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN K1 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN L3 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN L2 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN K3 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN K2 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

# 7-Segment Display Anodes
set_property PACKAGE_PIN F2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN E1 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN G5 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN G4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

# 7-Segment Display Segments
set_property PACKAGE_PIN G2 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN G1 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN H5 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN H4 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN J5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN J4 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN H2 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
set_property PACKAGE_PIN H1 [get_ports {seg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[7]}]

# UART TX
set_property PACKAGE_PIN C4 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
