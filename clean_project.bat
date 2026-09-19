@echo off
title Clean Temporary Files - WA-LP-BIST
echo ===================================================================
echo     Cleaning Vivado Temporary & Log Files...
echo ===================================================================
echo.

del /q /f *.jou *.log *.str *.backup.* *.pb 2>nul
del /q /f vivado_lp_project\*.jou vivado_lp_project\*.log vivado_lp_project\*.str 2>nul
del /q /f vivado_lp_project\*.rpt 2>nul

if exist .Xil rmdir /s /q .Xil
if exist .vivado_user_data rmdir /s /q .vivado_user_data
if exist dfx_runtime.txt del /q /f dfx_runtime.txt

echo Cleanup complete! Project is clean and structured.
echo.
pause
