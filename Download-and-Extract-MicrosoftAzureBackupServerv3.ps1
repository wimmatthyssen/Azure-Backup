<#
.SYNOPSIS

A script used to download and extract Microsoft Azure Backup Server v3 for a new deployment.

.DESCRIPTION

A script used to download Microsoft Azure Backup Server v3 for a new deployment. All required files, the .exe and seven .bin files will be downloaded in the C:\Temp folder. The C:\Temp folder will be created if it not already exists.
After the download, the .exe file will run, which extracts all .bin files to the Microsoft Azure Backup Server folder underneath C:\Temp. When extraction is completed all .bin and the .exe file will be cleaned up.
After which Setup.exe will run, which opens the Microsoft Azure Backup Server splash screen to start a manual installation.


the download the seven compressed .bin files will be extracted and setup.exe will be started.
Which will open the installation splash screen, from where Microsoft Azure Backup Server can be installed.

.NOTES

Filename:       Download-and-Extract-MicrosoftAzureBackupServerv3.ps1
Created:        19/08/2021
Last modified:  19/08/2021
Author:         Wim Matthyssen
PowerShell:     Windows PowerShell, PowerShell Core 
Version:        Minimum v 5.1
Windows Server: Windows Server 2019, Windows Server 2016
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

Download-and-Extract-MicrosoftAzureBackupServerv3.ps1

.LINK

https://wmatthyssen.com/2020/08/01/azure-powershell-script-create-a-management-group-tree-hierarchy/
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$tempFolder = "C:\Temp\"
$itemType = "Directory"
$mabsUrl1 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller.exe"
$mabsUrl2 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-1.bin"
$mabsUrl3 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-2.bin"
$mabsUrl4 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-3.bin"
$mabsUrl5 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-4.bin"
$mabsUrl6 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-5.bin"
$mabsUrl7 = "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-6.bin"
$mabsUrl8 =  "https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-7.bin"
$mabsExtFile1 = "C:\Temp\MicrosoftAzureBackupInstaller.exe"
$mabsExtFile2 = "C:\Temp\MicrosoftAzureBackupInstaller-1.bin"
$mabsExtFile3 = "C:\Temp\MicrosoftAzureBackupInstaller-2.bin"
$mabsExtFile4 = "C:\Temp\MicrosoftAzureBackupInstaller-3.bin"
$mabsExtFile5 = "C:\Temp\MicrosoftAzureBackupInstaller-4.bin"
$mabsExtFile6 = "C:\Temp\MicrosoftAzureBackupInstaller-5.bin"
$mabsExtFile7 = "C:\Temp\MicrosoftAzureBackupInstaller-6.bin"
$mabsExtFile8 = "C:\Temp\MicrosoftAzureBackupInstaller-7.bin"
$extFolderName = "C:\Microsoft Azure Backup Server"

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if running as Administrator, otherwise close the PowerShell window
 
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdministrator = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($IsAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperator + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 5
    exit
}
  
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Download started

Write-Host ($writeEmptyLine + "# MABS v3 download started" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a Temp folder on C: if it not exists

If (!(Test-Path -Path $tempFolder)){New-Item -ItemType $itemType -Force -Path $tempFolder
   Write-Host ($writeEmptyLine + "# Temp folder created" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
}Else {Write-Host ($writeEmptyLine + "# Temp folder already exists" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor1 $writeEmptyLine}

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Download MABS v3 software and save to C:\Temp

Import-Module BitsTransfer
Start-BitsTransfer -Source $mabsUrl1 -Destination $mabsExtFile1
for ($i = 1; $i -lt 2; $i++) {write-host}
   Write-Host ($writeEmptyLine + "# Download .exe completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
    
    Start-BitsTransfer -Source $mabsUrl2 -Destination $mabsExtFile2
    Write-Host ($writeEmptyLine + "# Download .bin part 1/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
    
    Start-BitsTransfer -Source $mabsUrl3 -Destination $mabsExtFile3
    Write-Host ($writeEmptyLine + "# Download .bin part 2/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine 
    
    Start-BitsTransfer -Source $mabsUrl4 -Destination $mabsExtFile4
    Write-Host ($writeEmptyLine + "# Download .bin part 3/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
    
    Start-BitsTransfer -Source $mabsUrl5 -Destination $mabsExtFile5
    Write-Host ($writeEmptyLine + "# Download .bin part 4/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
    
    Start-BitsTransfer -Source $mabsUrl6 -Destination $mabsExtFile6
    Write-Host ($writeEmptyLine + "# Download .bin part 5/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
    
    Start-BitsTransfer -Source $mabsUrl7 -Destination $mabsExtFile7
    Write-Host ($writeEmptyLine + "# Download .bin part 6/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
    
    Start-BitsTransfer -Source $mabsUrl8 -Destination $mabsExtFile8
    Write-Host ($writeEmptyLine + "# Download .bin part 7/7 completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine

for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host ($writeEmptyLine + "# Download completed" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Extraction started

Write-Host ($writeEmptyLine + "# Starting extraction" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Run MicrosoftAzureBackupInstaller.exe

Start-Process $mabsExtFile1 /SILENT -Wait

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Move extracted folder

Move-Item $extFolderName $tempFolder
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host ($writeEmptyLine + "# Extraction completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Clean up extracted files

[System.Collections.ArrayList]$mabsexfiles = $mabsExtFile1, $mabsExtFile2, $mabsExtFile3, $mabsExtFile4, $mabsExtFile5, $mabsExtFile6, $mabsExtFile7, $mabsExtFile8
Remove-Item $mabsexfiles
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host ($writeEmptyLine + "# Cleaned up extracted files" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Run Microsoft Azure Backup Server setup

& "C:\Temp\Microsoft Azure Backup Server\Setup.exe"
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host ($writeEmptyLine + "# MABS v3 setup started" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Exit PowerShell window 3 seconds after completion

Write-Host ($writeEmptyLine + "# Script completed, the PowerShell window will close in 3 seconds" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
Start-Sleep 3 
stop-process -Id $PID 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
