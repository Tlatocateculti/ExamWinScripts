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

