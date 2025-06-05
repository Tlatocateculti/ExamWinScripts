# Ścieżka do profilu Egzamin

$UserProfile = "C:\Users\egzamin"
$EgzaminUser = "egzamin"
$egzaminProfile = "C:\Users\$egzaminUser"
$DesktopPath = "C:\Users\$EgzaminUser\Desktop"
$sharedDir = "C:\VSCodeSharedExtensions"

# Katalogi do wyczyszczenia (możesz dodać kolejne wg potrzeb)

$FoldersToClean = @(
    "Desktop",
    "Documents",
    "Downloads",
    "Pictures",
    "Videos",
    "Music"
)



foreach ($folder in $FoldersToClean) {
    $path = Join-Path $UserProfile $folder
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$vsCodeProcesses = @("Code", "Code - Insiders")
foreach ($proc in $vsCodeProcesses) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}


# Czyszczenie cache przeglądarek (Chrome, Vivaldi, Brave)

$BrowserProfiles = @(
    "$UserProfile\AppData\Local\Google\Chrome\User Data\Default",
    "$UserProfile\AppData\Local\Vivaldi\User Data\Default",
    "$UserProfile\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default"
)

foreach ($profile in $BrowserProfiles) {
    if (Test-Path $profile) {
        Remove-Item "$profile\Cache" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$profile\Code Cache" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$profile\History" -Force -ErrorAction SilentlyContinue
        Remove-Item "$profile\Downloads" -Force -ErrorAction SilentlyContinue
        Remove-Item "$profile\Cookies" -Force -ErrorAction SilentlyContinue
    }
}

Remove-Item "$UserProfile\AppData\Roaming" -Recurse -Force -ErrorAction SilentlyContinue


# Czyszczenie folderów tymczasowych u�ytkownika

$UserTemp = "$UserProfile\AppData\Local\Temp"

if (Test-Path $UserTemp) {
    Get-ChildItem -Path $UserTemp -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

# Zatrzymaj serwery XAMPP
Stop-Process -Name "httpd" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "mysqld" -Force -ErrorAction SilentlyContinue

# Wyczyszczenie katalogów XAMPP
$htdocs = "C:\xampp\htdocs"
Get-ChildItem -Path $htdocs -Exclude "index.php" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$tmp = "C:\xampp\tmp"
if (Test-Path $tmp) {
    Get-ChildItem -Path $tmp | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# Reset MySQL – przywrócenie fabrycznego katalogu data
$dataDir = "C:\xampp\mysql\data"
$factoryDir = "C:\xampp\mysql\backup"
if (Test-Path $dataDir) {
    Remove-Item -Path $dataDir -Recurse -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path $factoryDir -Destination $dataDir -Recurse

Write-Host "XAMPP i baza MySQL zosta�y wyczyszczone i przywr�cone do stanu fabrycznego."

function Create-Shortcut($target, $shortcutName, $argsLnk) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\$shortcutName.lnk")
    $Shortcut.TargetPath = $target
    $Shortcut.Arguments = $argsLnk
    $Shortcut.Save()
}

# Przykładowe lokalizacje - dostosuj jeśli instalatory zmienią ścieżki!

#Create-Shortcut "C:\Program Files\Google\Chrome\Application\chrome.exe" "Google Chrome"
#Create-Shortcut "C:\Program Files\Vivaldi\Application\vivaldi.exe" "Vivaldi"

#Create-Shortcut "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" "Brave"

Create-Shortcut "C:\Program Files\Microsoft VS Code\Code.exe" "Visual Studio Code" "--locale=pl --extensions-dir $sharedDir"
Create-Shortcut "C:\Program Files\GIMP 2\bin\gimp-2.10.exe" "GIMP"
Create-Shortcut "C:\Program Files\Notepad++\notepad++.exe" "Notepad++"
Create-Shortcut "C:\Program Files\7-Zip\7zFM.exe" "7-Zip"
Create-Shortcut "C:\xampp\xampp-control.exe" "XAMPP Control Panel"



# 12. Odsłoń rozszerzenia plików (dla wszystkich użytkowników)

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0



# 13. Synchronizuj czas systemowy (wymaga dostępu do internetu)

w32tm /resync


Write-Host "Profil Egzamin zosta� wyczyszczony do stanu fabrycznego."