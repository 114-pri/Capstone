@echo off
title Setup GitHub & Initial Push - WA-LP-BIST
echo ===================================================================
echo     WA-LP-BIST RISC-V Project - GitHub Setup Wizard
echo ===================================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup_github_repo.ps1"
pause
