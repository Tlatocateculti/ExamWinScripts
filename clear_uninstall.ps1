function Uninstall-AppByName {
    param (
        [string]$appName,
        [string[]]$appDataFolders # np. "Code", "Google", "BraveSoftware"
    )
    # 1. Deinstalacja aplikacji (z rejestru)
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $uninstallPaths) {
        $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$appName*" }
        foreach ($app in $apps) {
            if ($app.UninstallString) {
                Write-Host "Usuwam $($app.DisplayName)..."
                if ($app.UninstallString -like "MsiExec*") {
                    Start-Process "msiexec.exe" -ArgumentList "/x $($app.PSChildName) /qn /norestart" -Wait
                } else {
                    $uninstallCmd = $app.UninstallString
                    if ($uninstallCmd -notmatch "/S" -and $uninstallCmd -notmatch "/silent") {
                        $uninstallCmd += " /S"
                    }
                    Start-Process "cmd.exe" -ArgumentList "/c $uninstallCmd" -Wait
                }
            }
        }
    }
    # 2. Usuwanie katalogów AppData dla Administratora i Egzamin
    $users = @("Administrator", "Egzamin")
    foreach ($user in $users) {
        $userProfile = "C:\Users\$user"
        foreach ($folder in $appDataFolders) {
            $paths = @(
                "$userProfile\AppData\Roaming\$folder",
                "$userProfile\AppData\Local\$folder"
            )
            foreach ($appDataPath in $paths) {
                if (Test-Path $appDataPath) {
                    try {
                        Remove-Item $appDataPath -Recurse -Force -ErrorAction Stop
                        Write-Host "Usunięto $appDataPath"
                    } catch {
                        WWrite-Host "Nie udało się usunąć ${appDataPath}: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
#$chromeUninstaller = "${env:ProgramFiles(x86)}\Google\Chrome\Application\*\Installer\setup.exe"
#if (Test-Path $chromeUninstaller) {
#    Start-Process $chromeUninstaller -ArgumentList "--uninstall --multi-install --chrome --system-level --force-uninstall" -Wait
#}
Uninstall-AppByName "Google Chrome" @("Google")
Uninstall-AppByName "Vivaldi" @("Vivaldi")
Uninstall-AppByName "Brave" @("BraveSoftware")
Uninstall-AppByName "Visual Studio Code" @("Code", ".vscode")
Uninstall-AppByName "GIMP" @("GIMP")
Uninstall-AppByName "Notepad++" @("Notepad++")
Uninstall-AppByName "7-Zip" @("7-Zip")Uninstall-AppByName "Opera" @("Opera")
#Uninstall-AppByName "XAMPP" @("xampp")
#Uninstall-AppByName "CDBurnerXP" @("Canneverbe Limited", "CDBurnerXP")

$services = @("Apache2.4", "mysql")
foreach ($service in $services) {
    sc.exe stop $service | Out-Null
    sc.exe delete $service | Out-Null
}
# Zatrzymanie procesów XAMPP
$processes = @("httpd", "mysqld", "xampp-control")
foreach ($proc in $processes) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
# Uruchomienie deinstalatora XAMPP (jeśli istnieje)
$uninstaller = "C:\xampp\uninstall.exe"
if (Test-Path $uninstaller) {
    Start-Process $uninstaller -Wait
    Start-Sleep -Seconds 10
}
# Usunięcie katalogu XAMPP
if (Test-Path "C:\xampp") {
    Remove-Item "C:\xampp" -Recurse -Force -ErrorAction SilentlyContinue
}