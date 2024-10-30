#Requires -Version 5.1 # TODO: Update the version number
<#
.SYNOPSIS
    Installation, configuration, and uninstallation of Beamy's web browser extension.

.DESCRIPTION
    This script can install, configure, or uninstall Beamy's web browser extension for supported browsers (Chrome, Edge, and Firefox).
    It uses registry keys and configuration files to manage the extension across all users on the machine.

.EXAMPLE
    .\beamy_wbe.ps1
#>

#region Variables

$ErrorActionPreference = 'Stop'
$ForceUpdateUserPolicy = $false # Set to $true to force update user policy values for all users


$BeamyChromeExtension = @{
    ExtensionId = 'lflophgfmbioahellkfjlmeffaedfkha'
    ExtensionUpdateUrl = 'https://clients2.google.com/service/update2/crx'
    ExtensionInstallForcelistPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist'
    PolicyPathBase = 'HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\Extensions\'
}
$BeamyChromeExtension.PolicyPath = Join-Path -Path $BeamyChromeExtension.PolicyPathBase -ChildPath "$($BeamyChromeExtension.ExtensionId)/policy"

$BeamyEdgeExtension = @{
    ExtensionId = 'nealoinbnmnpfcnodfgnegjiogllmlao'
    ExtensionUpdateUrl = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
    ExtensionInstallForcelistPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist'
    PolicyPathBase = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\Extensions\'
}
$BeamyEdgeExtension.PolicyPath = Join-Path -Path $BeamyEdgeExtension.PolicyPathBase -ChildPath "$($BeamyEdgeExtension.ExtensionId)/policy"


$BeamyGlobalVariables = @{
    ClientID = '529eb260-c82e-11ea-a5b5-6bd9fe6e2a87'
    ApiKey = 'qwerty12345'
    DeviceLoggedInUserNameExpectedFormat = 'lowercase'
}

#endregion



#region Uninstallation

function Remove-RegistryKey {
    param (
        [string]$Path
    )
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "Removed registry key: $Path"
    }
}

function Remove-RegistryValue {
    param (
        [string]$Path,
        [string]$Name
    )
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
        Write-Host "Removed registry value: $Path\$Name"
    }
}

function Uninstall-BeamyChrome {
    Write-Host "Uninstalling Beamy's Chrome extension..."
    
    if (Test-Path $BeamyChromeExtension.ExtensionInstallForcelistPath) {
        $properties = Get-ItemProperty -Path $BeamyChromeExtension.ExtensionInstallForcelistPath
        $propertiesToRemove = $properties.PSObject.Properties | Where-Object { $_.Value -like "*$($BeamyChromeExtension.ExtensionId)*" }
        foreach ($prop in $propertiesToRemove) {
            Remove-RegistryValue -Path $BeamyChromeExtension.ExtensionInstallForcelistPath -Name $prop.Name
        }
    }

    Remove-RegistryKey -Path $BeamyChromeExtension.PolicyPath

    Write-Host "Beamy's Chrome extension has been uninstalled."
}

function Uninstall-BeamyEdge {
    Write-Host "Uninstalling Beamy's Edge extension..."
    
    if (Test-Path $BeamyEdgeExtension.ExtensionInstallForcelistPath) {
        $properties = Get-ItemProperty -Path $BeamyEdgeExtension.ExtensionInstallForcelistPath
        $propertiesToRemove = $properties.PSObject.Properties | Where-Object { $_.Value -like "*$($BeamyEdgeExtension.ExtensionId)*" }
        foreach ($prop in $propertiesToRemove) {
            Remove-RegistryValue -Path $BeamyEdgeExtension.ExtensionInstallForcelistPath -Name $prop.Name
        }
    }

    Remove-RegistryKey -Path $BeamyEdgeExtension.PolicyPath

    Write-Host "Beamy's Edge extension has been uninstalled."
}

function Remove-UserPolicies {
    Write-Host "Removing Beamy's web browser extension policies for all users..."

    $UserProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }

    $HKUsersRegistryName = "HKU"
    New-PSDrive -PSProvider Registry -Name $HKUsersRegistryName -Root HKEY_USERS | Out-Null
    foreach ($UserProfile in $UserProfiles) {
        $Sid = $UserProfile.SID
        if (Test-Path -Path "${HKUsersRegistryName}:\${Sid}") {
            Remove-RegistryKey -Path $($BeamyChromeExtension.PolicyPath -replace "HKLM:\\", "${HKUsersRegistryName}:\${Sid}\")
            Remove-RegistryKey -Path $($BeamyEdgeExtension.PolicyPath -replace "HKLM:\\", "${HKUsersRegistryName}:\${Sid}\")
        }
    }
    Remove-PSDrive -Name $HKUsersRegistryName

    Write-Host "Removed Beamy's web browser extension policies for all users."
}

#endregion
#region Main

switch ('Uninstall') {


    "Uninstall" {
        Uninstall-BeamyChrome
        Uninstall-BeamyEdge
        Remove-UserPolicies
        Write-Host "Beamy's web browser extension has been uninstalled from all supported browsers."
    }
    default {
        Write-Host "Invalid action specified. Please set the `$Action variable to 'InstallAndConfigure', 'Configure', or 'Uninstall'."
    }
}

#endregion
