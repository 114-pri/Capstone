# EDGE Artix-7 XC7A100T FTG256 Demo Constraints

# 50 MHz Clock
set_property PACKAGE_PIN N11 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]

# Reset Button (BTNC)
set_property PACKAGE_PIN M14 [get_ports reset_btn]
set_property IOSTANDARD LVCMOS33 [get_ports reset_btn]

# Start Button (BTN0)
set_property PACKAGE_PIN L13 [get_ports start_btn]
set_property IOSTANDARD LVCMOS33 [get_ports start_btn]

# Mode Switches
set_property PACKAGE_PIN L5 [get_ports {mode_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode_sw[0]}]
set_property PACKAGE_PIN L4 [get_ports {mode_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode_sw[1]}]

# LEDs
set_property PACKAGE_PIN J3 [get_ports led_running]
set_property IOSTANDARD LVCMOS33 [get_ports led_running]

set_property PACKAGE_PIN H3 [get_ports led_done]
set_property IOSTANDARD LVCMOS33 [get_ports led_done]

set_property PACKAGE_PIN J1 [get_ports led_pass]
set_property IOSTANDARD LVCMOS33 [get_ports led_pass]

set_property PACKAGE_PIN K1 [get_ports led_fail]
set_property IOSTANDARD LVCMOS33 [get_ports led_fail]

set_property PACKAGE_PIN L3 [get_ports led_pa]
set_property IOSTANDARD LVCMOS33 [get_ports led_pa]

set_property PACKAGE_PIN L2 [get_ports led_fb]
set_property IOSTANDARD LVCMOS33 [get_ports led_fb]

# UART TX
set_property PACKAGE_PIN C4 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
