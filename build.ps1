# thanks to http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/

function Resolve-Module {
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][String]$Name,
        [Parameter()][Version]$Version
    )

    Write-Verbose -Message "Resolving module $Name"
    $module = Get-Module -Name $Name -ListAvailable

    if ($module) {
        if ($null -eq $Version) {
            Write-Verbose -Message "Module $Name is present, checking if version is the latest available"
            $Version = (Find-Module -Name $Name -Repository PSGallery | `
                Measure-Object -Property Version -Maximum).Maximum
            $installed_version = ($module | Measure-Object -Property Version -Maximum).Maximum

            $install = $installed_version -lt $Version
        } else {
            Write-Verbose -Message "Module $Name is present, checking if version matched $Version"
            $version_installed = $module | Where-Object { $_.Version -eq $Version }
            $install = $null -eq $version_installed
        }

        if ($install) {
            Write-Verbose -Message "Installing module $Name at version $Version"
            Install-Module -Name $Name -Force -SkipPublisherCheck -RequiredVersion $Version
        }
        Import-Module -Name $Name -RequiredVersion $Version
    } else {
        Write-Verbose -Message "Module $Name is not installed, installing"
        $splat_args = @{}
        if ($null -ne $Version) {
            $splat_args.RequiredVersion = $Version
        }
        Install-Module -Name $Name -Force -SkipPublisherCheck @splat_args
        Import-Module -Name $Name -Force
    }
}

Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
    Write-Verbose -Message "Setting PSGallery as a trusted repository"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

# 4.7.1 has issue when running Invoke-Psake from Pester which we do in this
# test, so revert back to the 4.7.0 release
Resolve-Module -Name Psake -Version 4.7.0
Resolve-Module -Name PSDeploy
Resolve-Module -Name Pester
Resolve-Module -Name BuildHelpers
Resolve-Module -Name PsScriptAnalyzer
Resolve-Module -Name powershell-yaml

Set-BuildEnvironment

Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )
