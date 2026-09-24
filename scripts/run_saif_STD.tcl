open_saif final_power_STD.saif
log_saif [get_objects -r /tb_power_char/dut/*]
run all
close_saif
quit
