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
$Remove3rdPartyFirefoxRegistry = $false # Set to $false if you want to keep the 3rdparty Extensions registry entries.
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

$BeamyFirefoxExtension = @{
    ExtensionId = 'support.firefox@beamy.io'
    ExtensionUpdateUrl = 'https://storage.googleapis.com/bmy-data-prod-wbe-public-files/prod/firefox/beamy-latest.xpi'
    InstallPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Install"
    LockedPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Locked"
    PolicyPathBase = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\3rdparty\Extensions\"
    ThirdPartyPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\3rdparty" # Used to remove legacy Beamy entries
    PoliciesJsonPath = $null
    FirefoxInstallationPath = $null # Replace with the path to the Firefox installation folder if known, otherwise let the script find it.
}
$BeamyFirefoxExtension.PolicyPath = Join-Path -Path $BeamyFirefoxExtension.PolicyPathBase -ChildPath $BeamyFirefoxExtension.ExtensionId

$BeamyGlobalVariables = @{
    ClientID = '529eb260-c82e-11ea-a5b5-6bd9fe6e2a87'
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

function Find-FirefoxInstallationPath {
    $possiblePaths = @(
        "${env:ProgramFiles}\Mozilla Firefox",
        "${env:ProgramFiles(x86)}\Mozilla Firefox",
        "${env:LocalAppData}\Mozilla Firefox"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\firefox.exe") {
            return $path
        }
    }

    Write-Host "Firefox installation not found."
    return $null
}


function Remove-BeamyFirefox-Registry {
    # Check and remove old Beamy-specific registry entries if they exist
    $installPath = $BeamyFirefoxExtension.InstallPath
    $lockedPath = $BeamyFirefoxExtension.LockedPath
    $3rdPartyBasePath = $BeamyFirefoxExtension.ThirdPartyPath
    $policyPath = $BeamyFirefoxExtension.PolicyPath

    # Check and remove from Install path
    if (Test-Path $installPath) {
        $installValues = Get-ItemProperty -Path $installPath
        foreach ($prop in $installValues.PSObject.Properties) {
            if ($prop.Value -eq $BeamyFirefoxExtension.ExtensionUpdateUrl) {
                Remove-ItemProperty -Path $installPath -Name $prop.Name -Force
                Write-Host "Removed old Beamy registry entry from Install path: $($prop.Name)"
            }
        }
    }

    # Check and remove from Locked path
    if (Test-Path $lockedPath) {
        $lockedValues = Get-ItemProperty -Path $lockedPath
        foreach ($prop in $lockedValues.PSObject.Properties) {
            if ($prop.Value -eq $BeamyFirefoxExtension.ExtensionId) {
                Remove-ItemProperty -Path $lockedPath -Name $prop.Name -Force
                Write-Host "Removed old Beamy registry entry from Locked path: $($prop.Name)"
            }
        }
    }

    # Remove Beamy from 3rdparty registry path
    if (Test-Path $policyPath) {
        Remove-Item -Path $policyPath -Force
        Write-Host "Removed Beamy registry entry from policy path: $policyPath"
    }

    if ($Remove3rdPartyFirefoxRegistry -eq $true -and (Test-Path $3rdPartyBasePath)) {
        Remove-Item -Path $3rdPartyBasePath -Force -Recurse
        Write-Host "Removed 3rdparty Firefox registry entries: $3rdPartyBasePath"
    }
}

function Install-BeamyFirefox {
    Write-Host "Installing Beamy's Firefox extension..."

    if ($BeamyFirefoxExtension.FirefoxInstallationPath -eq $null) {
        $BeamyFirefoxExtension.FirefoxInstallationPath = Find-FirefoxInstallationPath
    }

    if ($BeamyFirefoxExtension.FirefoxInstallationPath) {
        $BeamyFirefoxExtension.PoliciesJsonPath = Join-Path $BeamyFirefoxExtension.FirefoxInstallationPath "distribution\policies.json"
    } else {
        Write-Host "Firefox installation not found. Skipping Firefox extension installation."
        return
    }

    Remove-BeamyFirefox-Registry

    $policiesJsonPath = $BeamyFirefoxExtension.PoliciesJsonPath
    $distributionFolder = [System.IO.Path]::GetDirectoryName($policiesJsonPath)

    # Create distribution folder if it doesn't exist
    if (-not (Test-Path $distributionFolder)) {
        New-Item -Path $distributionFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created distribution folder: $distributionFolder"
    }

    # Read existing policies.json or create new if it doesn't exist
    if (Test-Path $policiesJsonPath) {
        $policiesJson = Get-Content $policiesJsonPath -Raw | ConvertFrom-Json
    } else {
        $policiesJson = @{
            policies = @{
                ExtensionSettings = @{}
            }
        }
    }

    # Check if ExtensionSettings exists, if not create it
    if (-not $policiesJson.policies.ExtensionSettings) {
        $policiesJson.policies.ExtensionSettings = @{}
    } elseif ($policiesJson.policies.ExtensionSettings -is [System.Management.Automation.PSCustomObject]) {
        # Convertir PSCustomObject en Hashtable si nécessaire
        $hashTable = @{}
        $policiesJson.policies.ExtensionSettings.PSObject.Properties | ForEach-Object {
            $hashTable[$_.Name] = $_.Value
        }
        $policiesJson.policies.ExtensionSettings = $hashTable
    }

    $policiesJson.policies.ExtensionSettings[$BeamyFirefoxExtension.ExtensionId] = @{
        "installation_mode" = "force_installed"
        "install_url" = $BeamyFirefoxExtension.ExtensionUpdateUrl
    }

    # Save updated policies.json
    $policiesJson | ConvertTo-Json -Depth 10 | Set-Content $policiesJsonPath -Force
    Write-Host "Updated policies.json at $policiesJsonPath"
}
    
function Install-Extensions {
    Write-Host "Installing Beamy's web browser extension..."
    Install-BeamyChrome
    Install-BeamyEdge
    Install-BeamyFirefox
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
        Configure-Extension-User -Identifier $Identifier -OrgaMappingIdentifier $OrgaMappingIdentifier -PolicyPath $($BeamyFirefoxExtension.PolicyPath -replace "HKLM:\\", "${HKUsersRegistryName}:\${Sid}\")
        Configure-Extension -PolicyPath $($BeamyFirefoxExtension.PolicyPath -replace "HKLM:\\", "${HKUsersRegistryName}:\${Sid}\") -ArrayPropertyType "MultiString" # Firefox should be configured for each user
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