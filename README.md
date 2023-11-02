# PRTG-Veeam
Monitors the states of Veeam backups and generates the output suitable for PRTG

Prerequisites
Veeam B&R Console has to be installed on the PRTG Server / Probe using this script
For powershell compatibility you need PSx64.exe (https://prtgtoolsfamily.com/downloads/sensors)
(Veeam uses x64 / PRTG uses x86)

Usage in PRTG
Parameter: -f="VeeamBackupCheck.ps1" -p=%host %windowsdomain\%windowsuser %windowspassword
