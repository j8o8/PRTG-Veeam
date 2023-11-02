# PRTG-Veeam
Monitors the states of Veeam backups and generates the output suitable for PRTG

## Prerequisites
+ Veeam B&R Console has to be installed on the PRTG Server / Probe using this script
+ For powershell compatibility you need PSx64.exe (https://prtgtoolsfamily.com/downloads/sensors)
> (Veeam uses x64 / PRTG uses x86)

## Usage
+ Place both the script and the PSx64.exe in the following directory on your PRTG Server / Probe
```
C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML
```
+ Create a new extended Script sensor
+ Under Program/Script select PSx64.exe
+ Use the following parameters
```
-f="VeeamBackupCheck.ps1" -p=%host %windowsdomain\%windowsuser %windowspassword
```
