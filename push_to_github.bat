@echo off
title Manual Push to GitHub - WA-LP-BIST
echo ===================================================================
echo     WA-LP-BIST RISC-V Project - Manual Push to GitHub
echo ===================================================================
echo.

git add -A
set /p commit_msg="Enter commit message (or press ENTER for automatic timestamp): "
if "%commit_msg%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set dt=%%I
    set commit_msg=Update: %dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%
)

git commit -m "%commit_msg%"
echo.
echo Pushing to GitHub...
git push origin HEAD

echo.
echo Done!
pause
