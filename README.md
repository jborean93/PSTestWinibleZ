# PSTestWinibleZ

[![Build status](https://ci.appveyor.com/api/projects/status/jdhvb0e0bpw9x7my?svg=true)](https://ci.appveyor.com/project/jborean93/pstestwiniblez)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSTestWinibleZ.svg)](https://www.powershellgallery.com/packages/PSTestWinibleZ)

PowerShell module that can be used to test Windows Ansible roles. Currently
designed to run in AppVeyor but the goal is to expand on running on any other
platform easily.

This is a rough draft of the module, I expect to make some changes to how it
runs after I go through a few different roles to see what works and what does
not.

## Info

TODO: fill this out


## Requirements

This module has the following requirements

* PowerShell v3.0 or newer
* Windows PowerShell (not PowerShell Core)
* Windows Server 2008 R2/Windows 7 or newer

It also requires the following PowerShell modules;

* [psake](https://github.com/psake/psake)
* [powershell-yaml](https://github.com/cloudbase/powershell-yaml)


## Installing

The easiest way to install this module is through
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).
This is installed by default with PowerShell 5 but can be added on PowerShell
3 or 4 by installing the MSI [here](https://www.microsoft.com/en-us/download/details.aspx?id=51451).

Once installed, you can install this module by running;

```
# Install for all users
Install-Module -Name PSTestWinibleZ

# Install for only the current user
Install-Module -Name PSTestWinibleZ -Scope CurrentUser
```

If you wish to remove the module, just run
`Uninstall-Module -Name PSTestWinibleZ`.

If you cannot use PowerShellGet, you can still install the module manually,
here are some basic steps on how to do this;

1. Download the latext zip from GitHub [here](https://github.com/jborean93/PSTestWinibleZ/releases/latest)
2. Extract the zip
3. Copy the folder `PSTestWinibleZ` inside the zip to a path that is set in `$env:PSModulePath`. By default this could be `C:\Program Files\WindowsPowerShell\Modules` or `C:\Users\<user>\Documents\WindowsPowerShell\Modules`
4. Reopen PowerShell and unblock the downloaded files with `$path = (Get-Module -Name PSTestWinibleZ -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Public\*.ps1; Unblock-File -Path $path\Private\*.ps1`
5. Reopen PowerShell one more time and you can start using the cmdlets

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable `PSModulePath` if you want to use another path._


## Examples

TODO: fill this out a bit more

To run the test, just run the cmdlet `Test-AnsibleRole`. By default it will
scan for a role in the current working directory, otherwise you can specify the
path to a role with `-Path`.

```
# test the role in the cwd
Test-AnsibleRole

# test the role at the path specified
Test-AnsibleRole -Path C:\roles\test-role
```


## Contributing

Just fork the repo and submit a pull request. To test out your changes locally,
you can run `.\build.ps1` in PowerShell. This script will ensure all
dependencies are installed before running the test suite.

_Note: this requires PowerShellGet or WMF 5 to be installed_


## Backlog

* Add support for running against Windows Subshell for Linux (WSL)
* Add support for running against a bash host (running on Linux)
* Add support for PowerShell Core
* Add automatic tagging of roles in GitHub on merge to master
* Add automatic Ansible Galaxy refresh on merge to master

