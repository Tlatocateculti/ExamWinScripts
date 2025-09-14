@echo off

setlocal ENABLEDELAYEDEXPANSION
:: Pobierz liste aplikacji z serwera
set "LIST_URL=https://raw.githubusercontent.com/Tlatocateculti/ExamWinScripts/refs/heads/main/tebinstall.txt"
set "LIST_FILE=%TEMP%\winget_list.txt"
curl -s -o "%LIST_FILE%" "%LIST_URL%"
if not exist "%LIST_FILE%" (
    echo Nie mozna pobrac listy z %LIST_URL%
    exit /b 1
)

for /f "usebackq tokens=* delims=" %%a in ("%LIST_FILE%") do (
    set "app=%%a"
    echo Sprawdzanie !app!...
    winget list --id !app! >nul 2>&1
    if errorlevel 1 (
        echo Instalowanie !app!...
        winget install --id !app! --silent --accept-source-agreements --accept-package-agreements
    ) else (
        echo !app! juz zainstalowany.
    )
)
endlocal