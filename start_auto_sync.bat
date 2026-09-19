@echo off
title GitHub Auto-Sync Watcher - WA-LP-BIST
echo ===================================================================
echo     WA-LP-BIST RISC-V Project - Real-Time GitHub Auto-Sync
echo ===================================================================
echo  This watcher runs in the background. Every time you edit or save
echo  files in this project, it automatically commits and pushes your
echo  changes to your GitHub repository after a brief 7-second debounce.
echo.
echo  Keep this terminal window open while you work.
echo  Press Ctrl+C at any time to pause or stop syncing.
echo ===================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\auto_sync_github.ps1"

pause
