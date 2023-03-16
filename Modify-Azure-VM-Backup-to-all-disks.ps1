<#

.SYNOPSIS

A script used to modify the protection of an Azure IaaS VM backup of a specific VM to backup all disks.

.DESCRIPTION

A script used to modify the protection of an Azure IaaS VM backup of a specific VM to backup all disks.
The script will do all of the following:

Remove the breaking change warning messages.
Modify protection to backup all disks.

.NOTES

Filename:       Modify-Azure-VM-Backup-all-disks.ps1
Created:        15/03/2023
Last modified:  15/03/2023
Author:         Wim Matthyssen
Version:        1.0
PowerShell:     Azure PowerShell
Requires:       PowerShell Az (v9.3.0)
Action:         Change variables as needed to fit your needs.
Disclaimer:     This script is provided "as is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
Set-AzContext -Subscription "<SubscriptionName>" (set to subscription holding the Recovery Services vault and the Azure VM)
.\Modify-Azure-VM-Backup-all-disks <"your VM name here">

-> Modify-Azure-VM-Backup-all-disks swpdc004

.LINK


#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Parameters

param(
    # $vmName -> Name of the target Azure Windows VM
    [parameter(Mandatory =$true)][ValidateNotNullOrEmpty()] [string] $vmName
)

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$rgNameBackup = #<your Recovery Services vault resource group name here> The name of the resource group in which the new vault will be created. Example: "rg-hub-myh-backup-01"
$vaultName = #<your Recovery Services vault name here> The name for the Recovery Services vault here. Example: "rsv-hub-myh-we-01"
$workloadType = "AzureVM"
$policyName = #<your Backup policy name here> The name of your Backup policy here. Example: "pol-1100-pm-2ir-sun-27d-54w-12m-5y"

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$foregroundColor3 = "Red"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Remove the breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started

Write-Host ($writeEmptyLine + "# Script started. Without errors, it can take up to 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Modify protection to backup all disks

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $rgNameBackup -Name $vaultName
Set-AzRecoveryServicesVaultContext -Vault $vault

$container = Get-AzRecoveryServicesBackupContainer -ContainerType $workloadType -FriendlyName $vmName -VaultId $vault.ID
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policyName

$backupItem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType $workloadType -VaultId $vault.ID
Enable-AzRecoveryServicesBackupProtection -Item $backupItem -ResetExclusionSettings -VaultId $vault.ID -Policy $policy | Out-Null

Write-Host ($writeEmptyLine + "# Protection VM $vmName set to backup all disks" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



