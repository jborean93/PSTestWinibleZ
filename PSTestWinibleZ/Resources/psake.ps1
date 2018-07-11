# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="Global vars are used outside of where they are declared")]
param()

# PSake makes variables declared here available in other scriptblocks
Properties {
    # load the module's private functions again, they are not available in
    # psake by default
    Get-ChildItem -Path $ps_ansible_tester_root\Private\*.ps1 -ErrorAction SilentlyContinue | `
        ForEach-Object { . $_.FullName }

    $lines = '----------------------------------------------------------------------'

    # populated when called with Invoke-psake
    $role_metadata = $metadata
    $role_name = $metadata.name
    $role_version = $metadata.version
    $role_path = $path
    $role_bash_path = Get-BashPath -Path $path
    $role_test_path = Join-Path -Path $role_path -ChildPath tests
    $role_test_bash_path = Get-BashPath -Path $role_test_path
    $role_inventory_bash_path = "$role_test_bash_path/$($metadata.inventory)"
    $virtual_environments = $venvs
    $inventory_path = Join-Path -Path $role_test_path -ChildPath inventory.ini

    # use the first venv when running Ansible commands (non playbook)
    $venv_source_cmd = "source `"$($virtual_environments[0])/bin/activate`""
}

Task Default -Depends Test

Task Setup {
    Write-ConsoleOutput -Message $lines
    if ($PSVersionTable.PSVersion -ge [Version]"6.0") {
        $platform_os = $PSVersionTable.OS
    } else {
        $win32_os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Version
        $platform_os = "Microsoft Windows $($win32_os.Version)"
    }

    $startup_msg = @"
    SETUP: Starting role tester pipeline
        Role Name: $role_name
        Role Path: $role_path
        Role Version: $role_version
        Ansible Versions: $($metadata.ansible_versions -join ", ")
        Platform: $($metadata.ci_platform)
        OS: $platform_os
        Date: $(Get-Date -Format s)
"@
    Write-ConsoleOutput -Message $startup_msg

    $requirements_path = Join-Path -Path $role_test_path -ChildPath requirements.yml
    if (Test-Path -Path $requirements_path) {
        Write-ConsoleOutput -Message "`n`tSETUP: '$requirements_path` exists, installing roles with ansible-galaxy"
        $galaxy_rc = Invoke-Bash -Arguments "$venv_source_cmd; ansible-galaxy install -r `"$role_test_bash_path/requirements.yml`" -p `"$role_test_bash_path/roles`""
        if ($galaxy_rc -ne 0) {
            Write-Error -Message "ansible-galaxy install failed to install role dependencies, rc: $galaxy_rc"
        }
    }
    Write-ConsoleOutput -Message "`n"
}

Task Sanity -Depends Setup {
    Write-ConsoleOutput -Message $lines
    Write-ConsoleOutput -Message "`n`tSANITY: Running ansible-lint for role at '$role_path'"
    $lint_rc = Invoke-Bash -Arguments "$venv_source_cmd; ansible-lint `"$role_bash_path`""
    if ($lint_rc -ne 0) {
        Write-Error -Message "ansible-lint `"$role_bash_path`" failed, rc: $lint_rc"
    }
    Write-ConsoleOutput -Message "`n"
}

Task Test -Depends Sanity {
    Write-ConsoleOutput -Message $lines
    foreach ($venv in $virtual_environments) {
        $test_playbook = Join-Path -Path $role_test_path -ChildPath main.yml

        Write-ConsoleOutput -Message "`n`tTEST: Running '$test_playbook' on $venv in check mode"
        Invoke-AnsiblePlaybook -Inventory $role_inventory_bash_path `
            -Playbook "$role_test_bash_path/main.yml" `
            -VirtualEnvPath $venv `
            -Verbosity $role_metadata.verbosity `
            -CheckMode

        Write-ConsoleOutput -Message "`n`tTEST: Running '$test_playbook' on $venv"
        Invoke-AnsiblePlaybook -Inventory $role_inventory_bash_path `
            -Playbook "$role_test_bash_path/main.yml" `
            -VirtualEnvPath $venv `
            -Verbosity $role_metadata.verbosity

        $cleanup_playbook = Join-Path -Path $role_test_path -ChildPath cleanup.yml
        if (Test-Path -Path $cleanup_playbook) {
            Write-ConsoleOutput -Message "`n`tTEST: Running '$cleanup_playbook' on $venv after completing testing"
            Invoke-AnsiblePlaybook -Inventory $role_inventory_bash_path `
                -Playbook "$role_test_bash_path/cleanup.yml" `
                -VirtualEnvPath $venv `
                -Verbosity $role_metadata.verbosity
        }
    }
    Write-ConsoleOutput -Message "`n"
}

Function Write-ConsoleOutput {
    param (
        [Parameter(Mandatory=$true)][String]$Message
    )
    if ($null -ne $host.UI) {
        $host.UI.WriteLine($Message)
    }
}

Function Get-BashPath {
    param (
        [Parameter(Mandatory=$true)][String]$Path
    )
    # bash_bin_path is specific for Cygwin, WSL's conversion exe should be
    # on the PATH env var and is set to $null
    $get_bash_path.Invoke($Path, $bash_bin_path)
}

Function Invoke-Bash {
    param (
        [Parameter(Mandatory=$true)][String]$Arguments
    )
    # the bash shell to use is dynamic and based on the environment/metadata
    # the invoke_bash_func and bash_exe are defined when calling Invoke-psake
    # and use the chosen bash shell for this run
    $invoke_bash_func.Invoke($bash_exe, $Arguments)
}

Function Invoke-AnsiblePlaybook {
    param (
        [Parameter(Mandatory=$true)][String]$Inventory,
        [Parameter(Mandatory=$true)][String]$Playbook,
        [Parameter(Mandatory=$true)][String]$VirtualEnvPath,
        [Int]$Verbosity = 3,
        [Switch]$CheckMode
    )

    $venv_source = "source `"$VirtualEnvPath/bin/activate`""
    $command = "ansible-playbook -i `"$Inventory`" `"$Playbook`" -$('v' * $Verbosity)"
    if ($CheckMode) {
        $command += " --check"
    }

    $rc = Invoke-Bash -Arguments "$venv_source; $command"
    if ($rc -ne 0) {
        Write-Error -Message "$venv_source; $command failed with rc: $rc"
    }
}
