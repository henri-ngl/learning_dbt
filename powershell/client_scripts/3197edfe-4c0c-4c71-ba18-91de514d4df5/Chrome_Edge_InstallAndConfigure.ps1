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
    ClientID = '3197edfe-4c0c-4c71-ba18-91de514d4df5'
    ApiKey = 'qwerty12345'
    DeviceLoggedInUserNameExpectedFormat = 'lowercase'
}

#endregion

#region Installation

function Check-Extension {
    param (
        [string]$RegistryKey,
        [string]$Value
    )

    $extensionExists = $false
    if (Test-Path -Path $RegistryKey) {
        $existingExtensions = Get-ItemProperty -Path $RegistryKey -ErrorAction SilentlyContinue
        $values = $existingExtensions.PSObject.Properties | Select-Object -ExpandProperty Value
        return $values -contains $Value
    }

    return $extensionExists
} 

function Install-Extension {
    param (
        [string]$RegistryKey,
        [string]$Value
    )

    if (-not (Test-Path -Path $RegistryKey)) {
        New-Item -Path $RegistryKey -Force | Out-Null
        Write-Host "Created registry key: $RegistryKey"
    }

    $existingExtensions = Get-ItemProperty -Path $RegistryKey -ErrorAction SilentlyContinue
    $nextKey = 1
    while ($existingExtensions."$nextKey" -ne $null) {
        $nextKey++
    }
    New-ItemProperty -Path $RegistryKey -Name "$nextKey" -Value "$Value" -PropertyType "String" -Force | Out-Null
    Write-Host "Created registry value: $nextKey = $Value"
}

function Install-BeamyChrome {
    Write-Host "Installing Beamy's Chrome extension..."
    Write-Host "Checking if Beamy's Chrome extension is already installed..."
    $extensionExists = Check-Extension -RegistryKey $BeamyChromeExtension.ExtensionInstallForcelistPath -Value "$($BeamyChromeExtension.ExtensionId);$($BeamyChromeExtension.ExtensionUpdateUrl)"
    if ($extensionExists) {
        Write-Host "Beamy's Chrome extension is already installed."
    } else {
        Install-Extension -RegistryKey $BeamyChromeExtension.ExtensionInstallForcelistPath -Value "$($BeamyChromeExtension.ExtensionId);$($BeamyChromeExtension.ExtensionUpdateUrl)"
        Write-Host "Installed Beamy's Chrome extension."
    }
}

function Install-BeamyEdge {
    Write-Host "Installing Beamy's Edge extension..."
    Write-Host "Checking if Beamy's Edge extension is already installed..."
    $extensionExists = Check-Extension -RegistryKey $BeamyEdgeExtension.ExtensionInstallForcelistPath -Value "$($BeamyEdgeExtension.ExtensionId);$($BeamyEdgeExtension.ExtensionUpdateUrl)"
    if ($extensionExists) {
        Write-Host "Beamy's Edge extension is already installed."
    } else {
        Install-Extension -RegistryKey $BeamyEdgeExtension.ExtensionInstallForcelistPath -Value "$($BeamyEdgeExtension.ExtensionId);$($BeamyEdgeExtension.ExtensionUpdateUrl)"
        Write-Host "Installed Beamy's Edge extension."
    }
}

    
function Install-Extensions {
    Write-Host "Installing Beamy's web browser extension..."
    Install-BeamyChrome
    Install-BeamyEdge
}

#endregion

#region Global configuration

function Configure-Extension {
    param (
        [string]$PolicyPath,
        [string]$ArrayPropertyType = "String"
    )

    if (-not (Test-Path -Path $PolicyPath)) {
        New-Item -Path $PolicyPath -Force | Out-Null
        Write-Host "Created policy path: $PolicyPath"
    }

    New-ItemProperty -Path $PolicyPath -PropertyType "STRING" -Name "clientId" -Value $BeamyGlobalVariables.ClientID -Force | Out-Null
    New-ItemProperty -Path $PolicyPath -PropertyType "STRING" -Name "apiKey" -Value $BeamyGlobalVariables.ApiKey -Force | Out-Null
    New-ItemProperty -Path $PolicyPath -PropertyType "STRING" -Name "deviceLoggedInUserNameExpectedFormat" -Value $BeamyGlobalVariables.DeviceLoggedInUserNameExpectedFormat -Force | Out-Null
    Write-Host "Configured policy values in $PolicyPath"
}

function Configure-Extensions-GlobalContext {
    Write-Host "Configuring Beamy's web browser extension..."
    Write-Host "Configuring Beamy's Chrome extension..."
    Configure-Extension -PolicyPath $BeamyChromeExtension.PolicyPath
    Write-Host "Configuring Beamy's Edge extension..."
    Configure-Extension -PolicyPath $BeamyEdgeExtension.PolicyPath

#endregion

#region Users configuration

function Get-UserProfiles {
    $profiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }
    return $profiles
}

function Get-OrgaMapping-Identifier {
    param (
        [string]$Sid
    )
    Write-Host "Getting orga mapping identifier for SID: $Sid"
    ## Update this function to return the orga mapping identifier for the given SID. By default, it returns the username.

    $ObjSID = New-Object System.Security.Principal.SecurityIdentifier ($Sid)
    $ObjUser = $objSID.Translate([System.Security.Principal.NTAccount])
    $Identifier = $ObjUser.Value

    Write-Host "Orga mapping identifier for SID $Sid is $Identifier"
    
    return $Identifier
}

function Get-Identifier {
    param (
        [string]$Sid
    )
    Write-Host "Getting identifier for SID: $Sid"
    ## Update this function to return the identifier for the given SID. By default, it returns the SID.

    return $Sid
}

function Configure-Extension-User {
    param (
        [string]$PolicyPath,
        [string]$Identifier,
        [string]$OrgaMappingIdentifier
    )

    if (-not (Test-Path $PolicyPath)) {
        New-Item -Path $PolicyPath -Force | Out-Null
        Write-Host "Created policy path: $PolicyPath"
    }

    if ($ForceUpdateUserPolicy -eq $false) {
        $existingPolicy = Get-ItemProperty -Path $PolicyPath -ErrorAction SilentlyContinue
        if ($existingPolicy -ne $null) {
            Write-Host "Policy values already configured for extension at $PolicyPath"
            return
        }
    }
    
    if (-not [string]::IsNullOrWhiteSpace($OrgaMappingIdentifier)) {
        New-ItemProperty -Path $PolicyPath -Name "deviceLoggedInUserName" -PropertyType "STRING" -Value $OrgaMappingIdentifier -Force | Out-Null
        Write-Host "Configured user policy values for extension at $PolicyPath"
    } else {
        Write-Host "Warning: OrgaMappingIdentifier is null or empty. Skipping deviceLoggedInUserName configuration for $PolicyPath"
    }

    if (-not [string]::IsNullOrWhiteSpace($Identifier)) {
        New-ItemProperty -Path $PolicyPath -Name "userId" -PropertyType "STRING" -Value $Identifier -Force | Out-Null
        Write-Host "Configured user policy values for extension at $PolicyPath"
    } else {
        Write-Host "Warning: Identifier is null or empty. Skipping userId configuration for $PolicyPath"
    }
}

function Configure-Extensions-UserContext {
    Write-Host "Configuring Beamy's web browser extension for user context..."
    $UserProfiles = Get-UserProfiles

    $HKUsersRegistryName = "HKU"
    New-PSDrive -PSProvider Registry -Name $HKUsersRegistryName -Root HKEY_USERS | Out-Null
    foreach ($UserProfile in $UserProfiles) {
        $Sid = $UserProfile.SID
        # Check if SID is on HKEY_USERS
        if (-not (Test-Path -Path "${HKUsersRegistryName}:\${Sid}")) {
            Write-Host "Skipping user profile $Sid as it is not loaded"
            continue
        }
        $OrgaMappingIdentifier = Get-OrgaMapping-Identifier -Sid $Sid
        $Identifier = Get-Identifier -Sid $Sid
        Configure-Extension-User -Identifier $Identifier -OrgaMappingIdentifier $OrgaMappingIdentifier -PolicyPath $($BeamyChromeExtension.PolicyPath -replace "HKLM:\\", "${HKUsersRegistryName}:\${Sid}\")
        Configure-Extension-User -Identifier $Identifier -OrgaMappingIdentifier $OrgaMappingIdentifier -PolicyPath $($BeamyEdgeExtension.PolicyPath -replace "HKLM:\\", "${HKUsersRegistryName}:\${Sid}\")
    }
    Remove-PSDrive -Name $HKUsersRegistryName
}

#endregion

#region Main

switch ('InstallAndConfigure') {
    "InstallAndConfigure" {
        Install-Extensions
        Configure-Extensions-GlobalContext
        Configure-Extensions-UserContext
        Write-Host "Beamy's web browser extension has been installed and configured."
    }


    default {
        Write-Host "Invalid action specified. Please set the `$Action variable to 'InstallAndConfigure', 'Configure', or 'Uninstall'."
    }
}

#endregion
coucou