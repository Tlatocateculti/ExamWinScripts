@echo off

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "MOUNTPOINT=C:\WirtualneDyski"
set "LABELS=VM MAGAZYN"
if not exist "%MOUNTPOINT%" (
    mkdir "%MOUNTPOINT%"
)
:: Szukamy partycji z etykieta
for /f "skip=1 tokens=1,2*" %%A in ('"wmic logicaldisk get DeviceID,VolumeName,DriveType"') do (
    set "drive=%%A"
    set "type=%%B"
    call :HandleDrive %%A %%B
)

    for /f "tokens=1,2,* skip=1" %%a in ('"wmic volume get Label,DeviceID,DriveLetter"') do (
			set "MATCH=0"
            for %%z in (!LABELS!) do (
                if /I "%%b"=="%%z" set "MATCH=1"
            )
			
            if "!MATCH!"=="1" (
			echo %%b !MATCH!
                mountvol "%MOUNTPOINT%" %%a >nul 2>&1
				for /f "tokens=2 delims= " %%v in ('"echo list volume | diskpart | findstr /C:"%%b""') do (
					(
						echo select volume %%v
						echo attributes volume set readonly
						echo exit
					) | diskpart >nul 2>&1
					echo Ustawiono wolumin %%v [%%b] jako read-only
				)
            )
    )
goto :eof

:HandleDrive
set "disk=%~1"
set "type=%~2"

:: Pomin partycje C:
if /I "%disk%"=="C:" (
    echo Pomijam partycje systemowa C:
    exit /b
)

:: Pomin napedy CD/DVD (DriveType 5 oznacza CD-ROM)
if "%type%"=="5" (
    echo Pomijam naped optyczny: %disk%
    exit /b
)

:: Inne partycje ? usuwamy litere
echo Ukrywanie partycji: %disk%
mountvol %disk% /D >nul 2>nul
exit /b

exit /b

