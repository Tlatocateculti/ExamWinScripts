@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "MOUNTPOINT=C:\WirtualneDyski"
set "LABELS=VM MAGAZYN"

if not exist "%MOUNTPOINT%" (
    mkdir "%MOUNTPOINT%"
)

:: ============================================================
:: Pobieranie dyskow przez WMI bez WMIC i bez PowerShell
:: ============================================================

set "WMISCRIPT=%TEMP%\get_logical_disks_%RANDOM%.vbs"

(
    echo Set objWMI = GetObject^("winmgmts:\\.\root\cimv2"^)
    echo Set colDisks = objWMI.ExecQuery^("SELECT DeviceID, DriveType FROM Win32_LogicalDisk"^)
    echo For Each objDisk In colDisks
    echo     WScript.Echo objDisk.DeviceID ^& " " ^& objDisk.DriveType
    echo Next
) > "%WMISCRIPT%"

for /f "tokens=1,2" %%A in ('cscript //nologo "%WMISCRIPT%"') do (
    call :HandleDrive %%A %%B
)

del "%WMISCRIPT%" >nul 2>&1


:: ============================================================
:: Szukamy woluminu o odpowiedniej etykiecie
:: ============================================================

for /f "tokens=2,3,* skip=2" %%a in ('"echo list volume | diskpart"') do (

    set "VOLUME_NUM=%%a"
    set "VOLUME_LABEL=%%b"

    set "MATCH=0"

    for %%z in (!LABELS!) do (
        if /I "!VOLUME_LABEL!"=="%%z" set "MATCH=1"
    )

    if "!MATCH!"=="1" (

        set "DETAIL_SCRIPT=%TEMP%\detail_vol_!VOLUME_NUM!.txt"

        (
            echo select volume !VOLUME_NUM!
            echo assign mount=%MOUNTPOINT%
            echo attributes volume set readonly
            echo exit
        ) > "!DETAIL_SCRIPT!"

        diskpart /s "!DETAIL_SCRIPT!" >nul 2>&1

        if !errorlevel! equ 0 (
            echo *** SUKCES: Zamontowano !VOLUME_LABEL! w %MOUNTPOINT%
        ) else (
            echo *** BLAD: Nie mozna zamontowac !VOLUME_LABEL!
        )

        del "!DETAIL_SCRIPT!" 2>nul
    )
)

goto :eof


:: ============================================================
:: Obsluga znalezionej litery dysku
:: ============================================================

:HandleDrive

set "disk=%~1"
set "type=%~2"

:: Pomin partycje C:
if /I "%disk%"=="C:" (
    echo Pomijam partycje systemowa C:
    exit /b
)

:: DriveType:
:: 2 = removable
:: 3 = local disk
:: 4 = network
:: 5 = CD/DVD
:: 6 = RAM disk

if "%type%"=="5" (
    echo Pomijam naped optyczny: %disk%
    exit /b
)

:: Inne partycje - usuwamy litere
echo Ukrywanie partycji: %disk%
mountvol %disk% /D >nul 2>nul

exit /b

