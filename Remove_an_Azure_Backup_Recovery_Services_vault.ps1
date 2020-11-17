<#

.SYNOPSIS

A script used to delete an Azure Backup Recovery Services vault and all cloud backup items.

.DESCRIPTION

A script used to delete an Azure Backup Recovery Services vault. First soft delete is disabled, and all soft-deleted backup items are reversed.
Then all cloud backup items are removed before the Recovery Services vault is removed. 
Afterwards the resource groups holding the Recovery Services vault and the one used for the instant recovery are removed.

.NOTES

Filename:       Remove_an_Azure_Backup_Recovery_Services_vault.ps1
Created:        17/11/2020
Last modified:  17/11/2020
Author:         Wim Matthyssen
PowerShell:     PowerShell 5.1; Azure PowerShell
Version:        Install latest Az modules
Action:         Change variables where needed to fit your needs
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

.\Remove_an_Azure_Backup_Recovery_Services_vault.ps1

.LINK

#>

## Variables

$global:currentTime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currentTime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$writeEmptyLine = "`n"
$writeSeperator = "-"
$writeSeperatorSpaces = " - "

$customerName ="myh"
$spoke = "hub"
$purpose = "backup"

$rgBackup = "rg" + $writeSeperator + $customerName + $writeSeperator + $spoke + $writeSeperator + $purpose
$rgBackupInstanRecovery = "rg" + $writeSeperator + $customerName + $writeSeperator + $spoke + $writeSeperator + $purpose + $writeSeperator + "irp" + $writeSeperator + "01"
$vaultName = "rsv" + $writeSeperator + $customerName + $writeSeperator + $spoke + $writeSeperator + "01"
$vault = Get-AzRecoveryServicesVault -ResourceGroupName $rgBackup -Name $vaultName

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Prerequisites

## Check if running as Administrator (when not running from Cloud Shell), otherwise close the PowerShell window

if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime +$writeEmptyLine)`
    -foregroundcolor $foregroundColor1
        Start-Sleep -s 4
    exit} else {
        
        ## Import Az module into the PowerShell session

        Import-Module Az
        Write-Host ($writeEmptyLine + "# Az module imported" + $writeSeperatorSpaces + $currentTime +$writeEmptyLine)`
        -foregroundcolor $foregroundColor1
        }
}

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Disable soft delete for the Azure Backup Recovery Services vault

Set-AzRecoveryServicesVaultProperty -Vault $vault.ID -SoftDeleteFeatureState Disable

Write-Host ($writeEmptyLine + " # Soft delete disabled for Recovery Service vault " + $vault.Name + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if there are backup items in a soft-deleted state and reverse the delete operation

$containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted"}

foreach ($item in $containerSoftDelete) {
    Undo-AzRecoveryServicesBackupItemDeletion -Item $item -VaultId $vault.ID -Force -Verbose
}

Write-Host ($writeEmptyLine + "# Undeleted all backup items in a soft deleted state in Recovery Services vault " + $vault.Name + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Stop protection and delete data for all backup-protected items

$containerBackup = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.DeleteState -eq "NotDeleted"}

foreach ($item in $containerBackup) {
    Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vault.ID -RemoveRecoveryPoints -Force -Verbose
}

Write-Host ($writeEmptyLine + "# Deleted backup date for all cloud protected items in Recovery Services vault " + $vault.Name + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Delete the Recovery Services vault

Remove-AzRecoveryServicesVault -Vault $vault -Verbose

Write-Host ($writeEmptyLine + "# Recovery Services vault " + $vault.Name + " deleted" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Delete the resource groups holding the Recovery Services vault and the one used for the instant recovery and this without confirmation

Get-AzResourceGroup -Name $rgBackup | Remove-AzResourceGroup -Force -Verbose
Get-AzResourceGroup -Name $rgBackupInstanRecovery | Remove-AzResourceGroup -Force -Verbose

Write-Host ($writeEmptyLine + "# Resource groups " + $vault.ResourceGroupName + " and " + $rgBackupInstanRecovery + " deleted" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

