@echo off

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "MOUNTPOINT=%USERPROFILE%\Desktop\DyskUcznia"
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

:: Utwórz punkt montowania, jesli nie istnieje
if not exist "%MOUNTPOINT%" mkdir "%MOUNTPOINT%"
:: Lista woluminów z GUID
set "GUIDLIST=%TEMP%\guid_list.txt"
mountvol | findstr /R "\\\\\?\\Volume{.*}" > "!GUIDLIST!"
:: LICZNIK I ZNALEZIONY FLAG
set /a COUNT=0
set "found=0"

:: Tymczasowe montowanie i sprawdzanie etykiet
for /f "tokens=*" %%G in (!GUIDLIST!) do (
    set "GUID=%%G"
    set /a COUNT+=1
    set "TMPMNT=%TEMP%\mnt_!COUNT!"
    mkdir "!TMPMNT!" >nul 2>&1
    mountvol "!TMPMNT!" "!GUID!" >nul 2>&1
    for /f "tokens=1,2,* skip=1" %%a in ('"wmic volume get Label,DeviceID,DriveLetter"') do (

            set "MATCH=0"
            for %%z in (!LABELS!) do (
                if /I "%%b"=="%%z" set "MATCH=1"
            )
            if "!MATCH!"=="1" (
				mountvol "!TMPMNT!" /D >nul 2>&1
				rmdir "!TMPMNT!" >nul 2>&1
                ::echo Zamontowano wolumin z etykieta [%%b] jako folder: %MOUNTPOINT%
                mountvol "%MOUNTPOINT%" %%a >nul 2>&1
                set "found=1"
            )
    )
	mountvol "!TMPMNT!" /D >nul 2>&1
	rmdir "!TMPMNT!" >nul 2>&1
)
:: Jesli nie znaleziono nic
if "!found!"=="0" (
    echo Nie znaleziono odpowiedniego woluminu z etykieta
    rmdir "%MOUNTPOINT%" >nul 2>&1
)
goto :eof

:HandleDrive
set "disk=%~1"
set "type=%~2"

:: Pomin partycje C:
if /I "%disk%"=="C:" (
    echo Pomijam partycjê systemow¹ C:
    exit /b
)

:: Pomin napedy CD/DVD (DriveType 5 oznacza CD-ROM)
if "%type%"=="5" (
    echo Pomijam napêd optyczny: %disk%
    exit /b
)

:: Inne partycje ? usuwamy litere
echo Ukrywanie partycji: %disk%
mountvol %disk% /D >nul 2>nul
exit /b

exit /b

