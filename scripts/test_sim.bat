@echo off
set XILINX_VIVADO=E:\vivado\2025.2\Vivado
call %XILINX_VIVADO%\bin\xvlog.bat -sv src\adaptive_controller.sv src\alu_rv32i.sv src\bist_controller.sv src\bist_top.sv src\enhanced_wsa_monitor.sv src\fault_boost_generator.sv src\fault_coverage_monitor.sv src\fault_injector_32bit.sv src\lt_lfsr_32bit.sv src\misr_32bit.sv src\operand_pattern_generator.sv src\programmable_workload_mapper.sv src\signature_comparator_32bit.sv src\transition_model.sv sim\tb_lp_bist_top.sv
call %XILINX_VIVADO%\bin\xelab.bat -debug typical --timescale 1ns/1ps -s final_sim work.tb_lp_bist_top
call %XILINX_VIVADO%\bin\xsim.bat final_sim -tclbatch run_final_sim.tcl > sim_output_test.log
type sim_output_test.log
