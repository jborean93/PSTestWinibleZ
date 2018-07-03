# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-AnsibleRoleMetadata {
    param (
        [Parameter(Mandatory=$true)][String]$Path
    )
    $meta_path = Join-Path -Path $Path -ChildPath PSTestWinibleZ.yml
    Write-Verbose -Message "Checking if role metadata path exists at '$Path'"
    if (-not (Test-Path -Path $meta_path)) {
        throw [ArgumentException]"Expecting Ansible metadata file at '$meta_path' but it was not there"
    }
    $meta_text = Get-Content -Path $meta_path -Raw
    $test_meta = ConvertFrom-Yaml -Yaml $meta_text

    # get mandatory keys
    $mandatory_keys = @("ansible_versions", "name", "version")
    foreach ($mandatory_key in $mandatory_keys) {
        if (-not $test_meta.ContainsKey($mandatory_key)) {
            throw [ArgumentException]"Expecting key '$mandatory_key' to be set under 'ps_ansible_tester' in PSTestWinibleZ.yml"
        }
    }

    $ansible_versions = $test_meta.ansible_versions
    if ($test_meta.ansible_versions -isnot [array]) {
        $ansible_versions = @($ansible_versions)
    }
    $name = $test_meta.name
    $version = $test_meta.version

    $metadata = @{
        ansible_versions = $ansible_versions
        name = $name
        version = $version
    }

    if ($test_meta.ContainsKey("verbosity")) {
        $metadata.verbosity = [int]$test_meta.verbosity
    } else {
        $metadata.verbosity = 3
    }
    if ($test_meta.ContainsKey("inventory")) {
        $metadata.inventory = $test_meta.inventory
    } else {
        $metadata.inventory = "inventory.ini"
    }

    # get the platform that is configured, these are the currently configured
    # platforms:
    #     appveyor-windows - Running on AppVeyor Windows, will setup the
    #         inventory and Cygwin meta info automatically
    #     unknown - The default if no ci_platform is defined, setup is expected
    #         to have been done manually by the user
    if ($test_meta.ContainsKey("ci_platform")) {
        Write-Verbose -Message "setting metadata based on the platform '$($test_meta.ci_platform)'"
        $metadata.ci_platform = $test_meta.ci_platform

        $valid_platforms = @("appveyor-windows")
        if ($metadata.ci_platform -notin $valid_platforms) {
            throw [ArgumentException]"ci_platform must be one of the following values: $($valid_platforms -join ' ')"
        }
    } else {
        $metadata.ci_platform = "unknown"
    }

    switch ($metadata.ci_platform) {
        "appveyor-windows" {
            # Until AppVeyor supports WSL or a Linux container we are forced to
            # use Cygwin
            $cygwin_meta = @{
                path = "C:\cygwin64-PSTestWinibleZ"
            }
            if ($test_meta.ContainsKey("cygwin")) {
                $metadata.cygwin = $test_meta.cygwin
            } else {
                $metadata.cygwin = $cygwin_meta
            }
        }
        "unknown" {
            # no platform was specified so the metadata should contain the
            # shell key
            if ($test_meta.ContainsKey("cygwin")) {
                $metadata.cygwin = $test_meta.cygwin
            } else {
                # TODO add support for explicit WSL
                throw [ArgumentException]"No Ansible runner environment specified, please set cygwin with the keys 'path' and 'setup_path' to continue"
            }

            $inventory_path = Join-Path -Path $Path -ChildPath tests | Join-Path -ChildPath $metadata.inventory
            if (-not (Test-Path -Path $inventory_path)) {
                throw [ArgumentException]"The inventory file at '$inventory_path' does not exist"
            }
        }
    }

    return ,$metadata
}
