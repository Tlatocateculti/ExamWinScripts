@echo off

net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Uruchom ten plik jako ADMINISTRATOR!
    pause
    exit /b 1
)

set "SCRIPT_PATH=C:\Scripts\get.bat"
set "TASK_NAME=TebiInstall"

echo Tworze zadanie...

schtasks /delete /tn "%TASK_NAME%" /f 2>nul

schtasks /create /tn "%TASK_NAME%" /tr "cmd /c \"%SCRIPT_PATH%\"" /sc ONLOGON /ru "SYSTEM" /rl HIGHEST /f

schtasks /create /tn "%TASK_NAME%_Boot" /tr "cmd /c \"%SCRIPT_PATH%\"" /sc ONSTART /ru "SYSTEM" /rl HIGHEST /f /delay 0001:00
echo Gotowe. Teraz bedzie sie odpalac w tle jako admin dla kazdego usera.
pause
