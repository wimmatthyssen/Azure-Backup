<#
.SYNOPSIS

A script used to configure antivirus exclusions in Windows Defender antivirus for Microsoft Azure Backup Server (MABS) v3.

.DESCRIPTION

A script used to configure antivirus exclusions in Windows Defender antivirus for Microsoft Azure Backup Server (MABS) v3.

.NOTES

File Name:      Configure-WindowsDefenderAntivirus-Antivirus-Exclusions-MicrosoftAzureBackupServerv3.ps1
Created:        23/08/2021
Last modified:  23/08/2021
Author:         Wim Matthyssen
PowerShell:     5.1 or above 
Requires:       -RunAsAdministrator
OS:             Windows Server 2019
Version:        3.0
Action:         Change variables were needed to fit your needs
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

.\Configure-WindowsDefenderAntivirus-Antivirus-Exclusions-MicrosoftAzureBackupServerv3.ps1

.LINK

https://tinyurl.com/8dpbwbne
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

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

## Add custom MABS v3 exclusions

Add-MpPreference -ExclusionProcess "DPMRA.exe"
Add-MpPreference -ExclusionProcess "csc.exe"
Add-MpPreference -ExclusionProcess "cbengine.exe"

Add-MpPreference -ExclusionPath "C:\Program Files\Microsoft Azure Backup Server\DPM\DPM\Temp\MTA"
Add-MpPreference -ExclusionPath "C:\Program Files\Microsoft Azure Backup Server\DPM\DPM\XSD\"
Add-MpPreference -ExclusionPath "C:\Program Files\Microsoft Azure Backup Server\DPM\DPM\bin"
Add-MpPreference -ExclusionPath "C:\Progam Files\Microsoft Azure Backup Server\DPM\MARS\Microsoft Azure Recovery Services Agent\bin"
Add-MpPreference -ExclusionPath "C:\Program Files\Microsoft Azure Backup Server\DPM\DPM\Cache"

Write-Host ($writeEmptyLine + "# Custom MABS v3 exclusions added" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------