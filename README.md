Oczywiście potrzeba zmienić uprawnienia uruchamiania skryptów PowerShell.

Z pełnymi uprawnieniami:
Set-ExecutionPolicy Unrestricted -Force

Jedynie na obecną sesję:
Set-ExecutionPolicy -Scope Process Unrestricted

Jednorazowo:
powershell -ExecutionPolicy Bypass -File ".\\&lt;skrypt&gt;.ps1"

