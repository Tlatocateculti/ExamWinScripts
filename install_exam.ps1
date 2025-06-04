# Skrypt PowerShell do przygotowania stanowiska INF.03 na Windows



# Ustawienia

$EgzaminUser = "egzamin"
$egzaminDesc = "Konto do egzaminu INF.03"
$egzaminFull = "Egzamin"
$groupsUser = "Użytkownicy"
$egzaminProfile = "C:\Users\$egzaminUser"
$DesktopPath = "C:\Users\$EgzaminUser\Desktop"
# Sprawdź, czy użytkownik już istnieje
if (-not (Get-LocalUser -Name $egzaminUser -ErrorAction SilentlyContinue)) {
    Write-Host "Tworzę konto $egzaminUser bez hasła..."
    New-LocalUser -Name $egzaminUser -Description $egzaminDesc -FullName $egzaminFull -NoPassword -PasswordNeverExpires
    # Dodaj do grupy Użytkownicy (standardowe uprawnienia)
    Add-LocalGroupMember -Group $groupsUser -Member $egzaminUser
} else {
    Write-Host "Konto $egzaminUser już istnieje."
}

# Upewnij się, że konto nie jest zablokowane
Enable-LocalUser -Name $egzaminUser

# Utwórz profil użytkownika (jeśli nie istnieje)
if (-not (Test-Path $egzaminProfile)) {
    # Wymuś utworzenie profilu przez uruchomienie procesu jako Egzamin
    Start-Process -FilePath "cmd.exe" -Credential (New-Object System.Management.Automation.PSCredential($UserName, (ConvertTo-SecureString "" -AsPlainText -Force))) -ArgumentList "/c exit" -WindowStyle Hidden -Wait
}

# Utwórz podstawowe katalogi, jeśli nie istnieją
$folders = @("Desktop", "Documents", "Downloads", "Pictures", "Music", "Videos")
foreach ($folder in $folders) {
    $path = Join-Path $egzaminProfile $folder
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

$appList = @(

    @{
        Name = "Google Chrome"
        Url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        Installer = "ChromeSetup.exe"
        Args = "/silent /install"
    },
    @{
        Name = "Vivaldi"
        Url = "https://downloads.vivaldi.com/stable/Vivaldi.6.7.3329.31.x64.exe"
        Installer = "VivaldiSetup.exe"
        Args = "/silent"
    },
    @{
        Name = "Brave"
        Url = "https://github.com/brave/brave-browser/releases/latest/download/BraveBrowserStandaloneSetup.exe"
        Installer = "BraveStandaloneSetup.exe"
        Args = ""
    },
    @{
        Name = "Visual Studio Code"
        Url = "https://vscode.download.prss.microsoft.com/dbazure/download/stable/258e40fedc6cb8edf399a463ce3a9d32e7e1f6f3/VSCodeSetup-x64-1.100.3.exe"
        Installer = "VSCodeSetup.exe"
        Args = "/verysilent /allusers"
    },
    @{
        Name = "GIMP"
        Url = "https://download.gimp.org/mirror/pub/gimp/v2.10/windows/gimp-2.10.36-setup.exe"
        Installer = "GimpInstall.exe"
        Args = "/ALLUSERS /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /NOCANCEL /SUPPRESSMSGBOXES"
    },
    @{
        Name = "NotePad++"
        Url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.4/npp.8.6.4.Installer.x64.exe"
        Installer = "npp.exe"
        Args = "/S"
    },
    @{
        Name = "7-zip"
        Url = "https://www.7-zip.org/a/7z2405-x64.exe"
        Installer = "7zip.exe"
        Args = "/S"
    },
    @{
        Name = "XAMPP"
        Url = "https://deac-ams.dl.sourceforge.net/project/xampp/XAMPP%20Windows/8.2.12/xampp-windows-x64-8.2.12-0-VS16-installer.exe?viasf=1"
        Installer = "xampp.exe"
        Args = "--mode unattended"
    }
    # Dodaj kolejne aplikacje według tego schematu

)



# Katalog tymczasowy na instalatory

$TempDir = "$env:TEMP\egzamin_insta"

if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}



foreach ($app in $appList) {
    $installerPath = Join-Path $TempDir $app.Installer
    Write-Host "`n>>> Próba pobrania i instalacji: $($app.Name)"
    try {
        # Pobranie instalatora
        Invoke-WebRequest -Uri $app.Url -OutFile $installerPath -ErrorAction Stop
        Write-Host "Pobrano instalator: $installerPath"
        # Instalacja (jeśli plik istnieje)
        if (Test-Path $installerPath) {
            if (![string]::IsNullOrEmpty($app.Args)) {
                Start-Process -FilePath $installerPath -ArgumentList $app.Args -Wait
            } else {
                Start-Process -FilePath $installerPath -Wait
            }
            Write-Host "Zainstalowano: $($app.Name)"
        } else {
            Write-Warning "Nie znaleziono pliku instalatora dla $($app.Name)"
        }

    } catch {
        Write-Warning "Błąd podczas pobierania lub instalacji $($app.Name): $($_.Exception.Message)"
        continue
    } finally {
        # Usuwanie instalatora po próbie instalacji
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`nProces instalacji zakończony."



# 5. Zainstaluj rozszerzenia do VS Code (dla wszystkich użytkowników)
$extensions = @(
    "dbaeumer.vscode-eslint",    # JavaScript
    "esbenp.prettier-vscode",    # JavaScript
    "xdebug.php-debug",          # PHP
    "bmewburn.vscode-intelephense-client", # PHP
    "cweijan.vscode-mysql-client2",         # MySQL
    "MS-CEINTL.vscode-language-pack-pl"
)
foreach ($ext in $extensions) {
    Start-Process -FilePath "C:\Program Files\Microsoft VS Code\bin\code.cmd" -ArgumentList "--install-extension $ext --force" -Wait
}
$users = @("egzamin", "Administrator")
foreach ($user in $users) {
    $userProfile = "C:\Users\$user"
    $localePath = Join-Path $userProfile "AppData\Roaming\Code\User\locale.json"
    if (!(Test-Path $localePath)) {
        # Utwórz katalog, jeśli nie istnieje
        $dir = Split-Path $localePath
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    # Ustaw język polski
    Set-Content -Path $localePath -Value '{ "locale": "pl" }' -Encoding UTF8
}
Write-Host "Pakiet językowy polski zainstalowany i ustawiony jako domyślny."


# 6. Pobierz i zainstaluj GIMP

#$gimpInstaller = "$TempDir\gimpSetup.exe"
#Download-File "https://download.gimp.org/mirror/pub/gimp/v2.10/windows/gimp-2.10.36-setup.exe" $gimpInstaller
#Start-Process -FilePath $gimpInstaller -Wait



# 7. Pobierz i zainstaluj Notepad++
#$nppInstaller = "$TempDir\nppSetup.exe"
#Download-File "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.4/npp.8.6.4.Installer.x64.exe" $nppInstaller
#Start-Process -FilePath $nppInstaller -ArgumentList "/S" -Wait



# 8. Pobierz i zainstaluj 7-Zip

#$zipInstaller = "$TempDir\7zipSetup.exe"

#Download-File "https://www.7-zip.org/a/7z2405-x64.exe" $zipInstaller

#Start-Process -FilePath $zipInstaller -ArgumentList "/S" -Wait



# 9. Pobierz i zainstaluj XAMPP (wersja 8.2.12)

#$xamppInstaller = "$TempDir\xamppSetup.exe"

#Download-File "https://deac-ams.dl.sourceforge.net/project/xampp/XAMPP%20Windows/8.2.12/xampp-windows-x64-8.2.12-0-VS16-installer.exe?viasf=1" $xamppInstaller

#Start-Process -FilePath $xamppInstaller -ArgumentList "--mode unattended" -Wait



# 11. Utwórz skróty na pulpicie "Egzamin"

function Create-Shortcut($target, $shortcutName, $argsLnk) {

    $WshShell = New-Object -ComObject WScript.Shell

    
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\$shortcutName.lnk")
    
    $Shortcut.TargetPath = $target

    $Shortcut.Arguments = $argsLnk

    $Shortcut.Save()

}



# Przykładowe lokalizacje - dostosuj jeśli instalatory zmienią ścieżki!

Create-Shortcut "C:\Program Files\Google\Chrome\Application\chrome.exe" "Google Chrome"

Create-Shortcut "C:\Program Files\Vivaldi\Application\vivaldi.exe" "Vivaldi"

Create-Shortcut "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" "Brave"

Create-Shortcut "C:\Program Files\Microsoft VS Code\Code.exe" "Visual Studio Code" "--locale pl"

Create-Shortcut "C:\Program Files\GIMP 2\bin\gimp-2.10.exe" "GIMP"

Create-Shortcut "C:\Program Files\Notepad++\notepad++.exe" "Notepad++"

Create-Shortcut "C:\Program Files\7-Zip\7zFM.exe" "7-Zip"

Create-Shortcut "C:\xampp\xampp-control.exe" "XAMPP Control Panel"



# 12. Odsłoń rozszerzenia plików (dla wszystkich użytkowników)

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0



# 13. Synchronizuj czas systemowy (wymaga dostępu do internetu)

w32tm /resync



Write-Host "Przygotowanie stanowiska zakończone. Zweryfikuj ręcznie odłączenie sieci oraz dokumentację papierową."
