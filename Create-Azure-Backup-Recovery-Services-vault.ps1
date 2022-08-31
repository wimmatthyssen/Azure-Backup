<#
.SYNOPSIS

A script used to create an Azure Backup Recovery Services vault to backup different workloads in an Azure subscription.

.DESCRIPTION

A script used to create an Azure Backup Recovery Services vault in a resource group to backup different workloads in an Azure subscription.
The script will do all of the following:

Check if the PowerShell window is running as Administrator (when not running from Cloud Shell), otherwise the Azure PowerShell script will be exited.
Suppress breaking change warning messages.
Change the current context to use a management subscription (a subscription with *management* in the subscription name will be automatically selected).
Save the Log Analytics workspace from the management subscription in a variable.
Store a specified set of tags in a hash table.
Register required Azure resource provider (Microsoft.RecoveryServices) in your subscription (only necessary if you use Azure Backup for the first time), if not already registered.
Create a resource group backup, if it not already exists. Add specified tags and do not add a resource lock.
Create a resource group backup irp, if it not already exists. Add specified tags and do not add a resource lock.
Create the Recovery Services vault if it does not exist.
Set specified tags on the Recovery Services vault.
Specify the type of backup storage redundancy for the Recovery Services vault (can only be modified if there are no backup items protected in the vault). Adjust the variable if required.
Set the diagnostic settings (log and metrics) for the Recovery Services vault if they don't exist.

.NOTES

Filename:       Create-Azure-Backup-Recovery-Services.ps1
Created:        11/09/2020
Last modified:  31/08/2022
Author:         Wim Matthyssen
Version:        2.0
PowerShell:     Azure PowerShell and Cloud Shell
Requires:       PowerShell Az (v8.1.0) and Az.RecoveryServices (v5.4.1)
Action:         Change variables were needed to fit your needs
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "<xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx>" (if not using the default tenant)
Set-AzContext -Subscription "<SubscriptionName>" (if not using the default subscription)
.\Create-Azure-Backup-Recovery-Services-vault.ps1

.LINK

https://wmatthyssen.com/2022/08/31/azure-backup-create-a-recovery-services-vault-with-azure-powershell/
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$spoke = #<your spoke here> The spoke where you want to deploy the Recovery Services vault. Example: "hub"
$region = #<your region here> The used Azure public region. Example: "westeurope"
$purpose = "backup"

$rgNameBackup = #<your Recovery Services vault resource group name here> The name of the resource group in which the new vault will be created. Example: "rg-hub-myh-backup-01"
$rgNameBackupIrp = #<your Recovery Services vault instant restore resource group name here> The name of the resource group for the instant restore capability. Example: "rg-hub-myh-backup-irp-01"

$logAnalyticsWorkSpaceName = #<your Log Analytics workspace name here> The name of your existing Log Analytics workspace. Example: "law-hub-myh-01"
$vaultName = #<your Recovery Services vault name here> The name for the Recovery Services vault here. Example: "rsv-hub-myh-we-01"
$backupStorageRedundancy = "LocallyRedundant" # "GeoRedundant" (GRS) - "ZoneRedundant" (ZRS)

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example:"Env"
$tagSpokeValue = (Get-Culture).TextInfo.ToTitleCase($spoke.ToLower())
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example: "CostCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "23"
$tagCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example: "Criticality"
$tagCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "High"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example: "Purpose"
$tagPurposeValue = (Get-Culture).TextInfo.ToTitleCase($purpose.ToLower()) 

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if PowerShell runs as Administrator (when not running from Cloud Shell), otherwise exit the script

if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    
    ## Start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        ## Check if running as Administrator, otherwise exit the script
        if ($isAdministrator -eq $false) {
        Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        Start-Sleep -s 3
        exit
        }
        else {

        ## If running as Administrator, start script execution    
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine 
        }
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to use the management subscription

$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}

Set-AzContext -SubscriptionId $subNameManagement.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Management subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Save Log Analytics workspace from the management subscription in a variable

$workSpace = Get-AzOperationalInsightsWorkspace | Where-Object Name -Match $logAnalyticsWorkSpaceName

Write-Host ($writeEmptyLine + "# Log Analytics workspace variable created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tags = @{$tagSpokeName=$tagSpokeValue;$tagCostCenterName=$tagCostCenterValue;$tagCriticalityName=$tagCriticalityValue;$tagPurposeName=$tagPurposeValue}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Register required Azure resource provider (Microsoft.RecoveryServices) in your subscription (only necessary if you use Azure Backup for the first time), if not already registered.

# Register Microsoft.RecoveryServices resource provider
Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices" | Out-Null

Write-Host ($writeEmptyLine + "# All required resource providers for a Recovery Services vault are currently registering or already registerd" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a resource group backup, if it not already exists. Add specified tags and do not add a resource lock

try {
    Get-AzResourceGroup -Name $rgNameBackup -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgNameBackup -Location $region -Force | Out-Null   
}

# Set tags resource group backup
Set-AzResourceGroup -Name $rgNameBackup -Tag $tags | Out-Null

Write-Host ($writeEmptyLine + "# Resource group $rgNameBackup available with tags" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a resource group backup irp, if it not already exists. Add specified tags and do not add a resource lock

try {
    Get-AzResourceGroup -Name $rgNameBackupIrp -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgNameBackupIrp -Location $region -Force | Out-Null
}

# Set tags resource group backup irp
Set-AzResourceGroup -Name $rgNameBackupIrp -Tag $tags | Out-Null

Write-Host ($writeEmptyLine + "# Resource group $rgNameBackupIrp available with tags" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the Recovery Services vault if it does not exist

try {
    Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgNameBackup -ErrorAction Stop | Out-Null 
} catch {
    New-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgNameBackup -Location $region | Out-Null
}

Write-Host ($writeEmptyLine + "# Recovery Services vault $vaultName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set specified tags on the Recovery Services vault

$vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgNameBackup

# Replace exisiting tags on the Recovery Services vault
Update-AzTag -ResourceId ($vault.Id) -Tag $tags -Operation Replace | Out-Null

Write-Host ($writeEmptyLine + "# Tags Recovery Services vault $vaultName set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Specify the type of backup storage redundancy for the Recovery Services vault (can be modified only if there are no backup items protected in the vault)

Set-AzRecoveryServicesBackupProperty -Vault $vault -BackupStorageRedundancy $backupStorageRedundancy

Write-Host ($writeEmptyLine + "# Backup storage redundancy set to $backupStorageRedundancy" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set the diagnostic settings (log and metrics) for the Recovery Services vault if they don't exist

try {
    Get-AzDiagnosticSetting -Name $vaultName -ResourceId ($vault.Id) -ErrorAction Stop | Out-Null
} catch {    
    Set-AzDiagnosticSetting -Name $vaultName -ResourceId ($vault.Id) `
    -Category AzureBackupReport,CoreAzureBackup,AddonAzureBackupJobs,AddonAzureBackupAlerts,AddonAzureBackupPolicy,AddonAzureBackupStorage,AddonAzureBackupProtectedInstance `
    -MetricCategory Health -Enabled $true -WorkspaceId ($workSpace.ResourceId) | Out-Null
}

Write-Host ($writeEmptyLine + "# Recovery Services vault $vaultName diagnostic settings set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

