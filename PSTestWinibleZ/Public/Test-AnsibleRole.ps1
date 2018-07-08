# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Test-AnsibleRole {
    [CmdletBinding()]
    param(
        [String]$Path
    )
    if (-not $Path) {
        $Path = Get-Location
    }
    # get the role metadata from meta/main.yml
    $metadata = Get-AnsibleRoleMetadata -Path $Path

    # copy the files across to a temp location before we start modifying them
    # for the tests
    $temp_path_dir = Join-Path -Path ([System.IO.Path]::GetTempPath()) `
        -ChildPath ([System.Guid]::NewGuid())
    if (-not (Test-Path -Path $temp_path_dir)) {
        New-Item -Path $temp_path_dir -ItemType Directory > $null
    }

    try {
        # ensure the environment is setup and ready for the test
        $virtual_environments = @()
        $bash_bin_path = $null
        $bash_exe = $null
        $get_bash_path = $null
        $invoke_bash_func = $null

        if ($metadata.ContainsKey("cygwin")) {
            # download the latest setup.exe
            $cygwin_setup_exe = Join-Path -Path $temp_path_dir -ChildPath "setup-x86_64.exe"
            (New-Object -TypeName System.Net.WebClient).DownloadFile("https://www.cygwin.com/setup-x86_64.exe", $cygwin_setup_exe)

            $virtual_environments = New-CygwinSetup `
                -Path $metadata.cygwin.path `
                -SetupExe $cygwin_setup_exe `
                -AnsibleVersions $metadata.ansible_versions
            $bash_bin_path = Join-Path -Path ($metadata.cygwin.path) -ChildPath bin
            $bash_exe = Join-Path -Path $bash_bin_path -ChildPath bash.exe
            $invoke_bash_func = ${Function:Invoke-BashCygwin}
            $get_bash_path = ${Function:Get-BashPathCygwin}
        }

        Copy-Item -Path $Path -Destination $temp_path_dir -Recurse -Force
        $temp_path = Join-Path -Path $temp_path_dir -ChildPath (Split-Path -Path $Path -Leaf)

        # convert line endings from Windows (\r\n) to Unix (\n), ansible-lint will
        # throw errors when \r\n is used
        Get-ChildItem -Path $temp_path -Filter "*.yml" -Recurse | `
            ForEach-Object { Convert-FileLineEndings -Path $_.FullName }

        if ($metadata.ci_platform -eq "appveyor-windows") {
            # create the inventory file for AppVeyor if one does not already exist
            $inventory_path = Join-Path -Path $temp_path -ChildPath tests | Join-Path -ChildPath $metadata.inventory
            if (-not (Test-Path -Path $inventory_path)) {
                $username = $env:USERNAME
                $password = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", '')
                $inventory_text = @"
[windows]
127.0.0.1

[windows:vars]
ansible_user=$username
ansible_password=$password
ansible_connection=winrm
ansible_port=5985
ansible_winrm_scheme=http
ansible_winrm_transport=ntlm
"@
                Set-Content -Path $inventory_path -Value $inventory_text
            }

            Enable-PSRemoting -Force > $null
        }

        $build_file = Join-Path -Path $script:PSScriptRoot -ChildPath Resources | Join-Path -ChildPath psake.ps1
        Invoke-psake -buildFile $build_file -parameters @{
            bash_bin_path = $bash_bin_path
            bash_exe = $bash_exe
            get_bash_path = $get_bash_path
            invoke_bash_func = $invoke_bash_func
            metadata = $metadata
            path = $temp_path
            ps_ansible_tester_root = $ps_ansible_tester_root
            venvs = $virtual_environments
        } > $null
    } finally {
        Remove-Item -Path $temp_path_dir -Force -Recurse > $null
    }

    if (-not $psake.build_success) {
        Write-Error -Message "psake failed with error, check error logs and fix up build"
    }

    return $psake.build_success
}
