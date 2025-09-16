@echo off

setlocal enabledelayedexpansion
:: Adres listy z ID aplikacji w jednej linii (spacjami oddzielone)
set "LIST_URL=https://raw.githubusercontent.com/Tlatocateculti/ExamWinScripts/main/tebinstall.txt"
set "LIST_FILE=%TEMP%\winget_list.txt"
echo Pobieranie listy aplikacji z: %LIST_URL%
curl -s -o "%LIST_FILE%" "%LIST_URL%"
if not exist "%LIST_FILE%" (
    echo Nie mozna pobrac listy z %LIST_URL%
    exit /b 1
)
:: Odczytaj pierwsza (i jedyna) linie z pliku
set /p line=<"%LIST_FILE%"
:: Iteruj po wszystkich ID oddzielonych spacja
for %%A in (!line!) do (
    echo.
    echo Sprawdzanie: %%A
    winget list --id %%A --accept-source-agreements --accept-package-agreements | findstr /I "%%A" >nul
	if errorlevel 1 (
        echo Instalowanie: %%A...
        winget install --id %%A --silent --accept-source-agreements --accept-package-agreements
    ) else (
        echo %%A juz zainstalowany.
    )
)
echo.
echo Gotowe.
