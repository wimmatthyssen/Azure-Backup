<#
.SYNOPSIS

A script used to create an Azure Backup Recovery Services vault.

.DESCRIPTION

A script used to create an Azure Backup Recovery Services vault in a resource group. When the Recovery Services vault is created with the necessary resource tags, the storage redundancy type will be set.

.NOTES

Filename:       Create_Azure_Backup_Recovery_Services_vault.ps1
Created:        11/09/2020
Last modified:  11/09/2020
Author:         Wim Matthyssen
PowerShell:     Azure Cloud Shell or Azure PowerShell
Version:        Install latest modules if using Azure PowerShell
Action:         Change variables were needed to fit your needs. Before running the script logon with "Connect-AzAccount" and select the correct Azure Subscription
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

.\Create_Azure_Backup_Recovery_Services_vault.ps1

.LINK

#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Prerequisites

## Check if running as Administrator, otherwise close the PowerShell window (if not run in Azure Cloud Shell)

$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdministrator = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($IsAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperator + $time)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 5
    exit
}

## Import Az module into the PowerShell session (if not run in Azure Cloud Shell)

Import-Module Az

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$writeEmptyLine = "`n"
$writeSeperator = "-"
$writeSeperatorSpaces = " - "

$customerName ="myh"
$hub = "hub"
$location = "westeurope"
$rgBackupHub = "rg" + $writeSeperator + $customerName + $writeSeperator + $hub + $writeSeperator + "backup"
$vaultNumber = "01"
$vaultName = "rsv" + $writeSeperator + $customerName + $writeSeperator + $hub + $writeSeperator + $vaultNumber
$storageRedundancyLRS = "LocallyRedundant"
$storageRedundancyGRS = "GeoRedundant"
$rgBackupInstantRecoveryName= "rg" + $writeSeperator + $customerName + $writeSeperator + $hub + $writeSeperator + "backup" + $writeSeperator + "irp" + $writeSeperator + "0" 

$tagCostCenter = "it"
$tagBusinessCriticality1 = "critical"
$tagBusinessCriticality2 = "high"
$tagBusinessCriticality3 = "medium"
$tagBusinessCriticality4 = "low"
$tagBackup = "backup"

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Register the Azure Recovery Service provider with your subscription (only necessary if you use Azure Backup for the first time)

Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create resource group for the Recovery Services vault

New-AzResourceGroup -Name $rgBackupHub -Location $location `
-Tag @{env=$hub;costCenter=$tagCostCenter;businessCriticality=$tagBusinessCriticality1;applicationName=$tagBackup;region=$location}

Write-Host ($writeEmptyLine + "# Resource group " + $rgBackupHub + " created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the Recovery Services vault

New-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgBackupHub -Location $location `
-Tag @{env=$hub;costCenter=$tagCostCenter;businessCriticality=$tagBusinessCriticality1;applicationName=$tagBackup;region=$location}

Write-Host ($writeEmptyLine + "# Recovery Services vault " + $vaultName + " created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Specify the type of storage redundancy for the Recovery Services vault

$varVault = Get-AzRecoveryServicesVault –Name $vaultName -ResourceGroupName $rgBackupHub
$backupStorageRedundancy = $storageRedundancyLRS

Set-AzRecoveryServicesBackupProperty -Vault $varVault -BackupStorageRedundancy $backupStorageRedundancy

Write-Host ($writeEmptyLine + "# Redundancy for " + $vaultName + " set to " + $backupStorageRedundancy + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set resource group for storing instant recovery points of managed virtual machines (for the DefaultPolicy)

Get-AzRecoveryServicesVault -Name $vaultName | Set-AzRecoveryServicesVaultContext

$bkpPol = Get-AzRecoveryServicesBackupProtectionPolicy -name "DefaultPolicy"
$bkpPol.AzureBackupRGName= $rgBackupInstantRecoveryName

Set-AzRecoveryServicesBackupProtectionPolicy -policy $bkpPol

Write-Host ($writeEmptyLine + "# Instant recovery points resource group set for the DefaultPolicy " + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
