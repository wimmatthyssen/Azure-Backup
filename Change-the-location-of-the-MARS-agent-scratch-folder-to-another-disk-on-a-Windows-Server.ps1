<#

.SYNOPSIS

A combination of PowerShell cmdlets and Command Prompt (CMD) commands used to change the location of the MARS agent cache (scratch) folder to another disk on a Windows Server.

.DESCRIPTION

A combination of PowerShell cmdlets and CMD commands used to change the location of the MARS agent cache (scratch) folder to another disk on a Windows Server.
The used cmdlets and commands will do all of the following:

Format disk used as new drive location for the scratch folder with NTFS as the file system and 64K as allocation unit size.
Validate the correct (64K) allocation unit size.
Create the scratch folder location on the new disk.
Stop the Backup engine.
Use the Robocopy command to copy all the data from the default scratch folder to the new scratch folder on the new disk.
Update the required registry entries with the path of the newly moved scratch folder.
Restart the Backup engine.
Remove the original scratch folder and all its data.

You can follow all required steps in the following blog post: 

.NOTES

Filename:       Change-the-location-of-the-MARS-agent-scratch-folder-to-another-disk-on-a-Windows-Server.ps1
Created:        11/05/2022
Last modified:  11/05/2022
Author:         Wim Matthyssen
Version:        1.0
Requires:       PowerShell and Command Prompt
Action:         Change variables were needed to fit your needs. 
Disclaimer:     These PowerShell cmdlets and CMD commands are provided "As Is" with no warranties.

.EXAMPLE

.\Change-the-location-of-the-MARS-agent-scratch-folder-to-another-disk-on-a-Windows-Server.ps1

.LINK


#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Default scratch folder location: %ProgramFiles%\Microsoft Azure Recovery Services Agent\Scratch\

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Microsoft Azure Recovery Services Agent Scratch folder on S: drive (elevated PowerShell)

$driveLetter = "S:\" #Specify your drive letter here

New-Item -Path $driveLetter -Name "Microsoft Azure Recovery Services Agent" -ItemType "directory"

New-Item -Path "$driveLetter + Microsoft Azure Recovery Services Agent" -Name "Scratch" -ItemType "directory"

Write-Host `n "# Microsoft Azure Recovery Services Agent Scratch folder available" -foregroundcolor "Yellow"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Use Robocopy to move scratch folder data (elevated CMD)

:: Use Robocopy to move scratch folder data

robocopy "C:\Program Files\Microsoft Azure Recovery Services Agent\Scratch" "<yourdriveletterhere>:\Microsoft Azure Recovery Services Agent\Scratch" /E

robocopy "C:\Program Files\Microsoft Azure Recovery Services Agent\Scratch" "S:\Microsoft Azure Recovery Services Agent\Scratch" /E

:: Robocopy has finished

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Update scratch folder regkey values with the path of the newly moved scratch folder (elevated PowerShell)

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Azure Backup\Config" -Name ScratchLocation -Value "S:\Microsoft Azure Recovery Services Agent\Scratch"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Azure Backup\Config\CloudBackupProvider" -Name ScratchLocation -Value "S:\Microsoft Azure Recovery Services Agent\Scratch"

Write-Host `n "# Scratch folder regkey values are updated" -foregroundcolor "Yellow"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Restart the Backup engine (elevated CMD)

net stop obengine
net start obengine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Delete original scratch folder and data (elevated PowerShell)

Remove-Item -LiteralPath "C:\Program Files\Microsoft Azure Recovery Services Agent\Scratch" -Force -Recurse

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

