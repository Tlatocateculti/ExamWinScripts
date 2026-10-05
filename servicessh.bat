dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0
sc config sshd start= auto
net start sshd
netsh advfirewall firewall add rule name="OpenSSH Server (sshd)" dir=in action=allow protocol=TCP localport=22
