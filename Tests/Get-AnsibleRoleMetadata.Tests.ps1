# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force
. $PSScriptRoot\..\PSTestWinibleZ\Private\$module_name.ps1

Function ConvertTo-OrderedDictionary($hashtable) {
    $ordered_dict = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $keys = $hashtable.Keys | Sort-Object
    foreach ($key in $keys) {
        $value = $hashtable.$key
        if ($value -is [hashtable]) {
            $value = ConvertTo-OrderedDictionary $value
        }
        $ordered_dict.Add($key, $value) > $null
    }

    return ,$ordered_dict
}

Describe "$module_name PS$ps_version tests" {
    BeforeEach {
        $tmp_path = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
        New-Item -Path $tmp_path -ItemType Directory > $null
    }

    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Get metadata from yaml at <Path>' -TestCases @(
            @{
                Path = "appveyor_default.yml"
                Expected = @{
                    cygwin = @{setup_path="c:\cygwin64\setup-x86_64.exe"; path="C:\cygwin64"}
                    version = "0.0.1"
                    inventory = "inventory.ini"
                    ansible_versions = @("2.4.5.0", "2.5.5")
                    name = "simple-role"
                    ci_platform = "appveyor-windows"
                    verbosity = 3

                }
            },
            @{
                Path = "appveyor_with_cygwin_override.yml"
                Expected = @{
                    cygwin = @{setup_path="D:\cygwin64\setup.exe"; path="D:\cygwin64"}
                    version = "1.0.0"
                    inventory = "inventory.ini"
                    ansible_versions = @("2.5.4")
                    name = "role"
                    ci_platform = "appveyor-windows"
                    verbosity = 3
                }
            },
            @{
                Path = "appveyor_with_inventory.yml"
                Expected = @{
                    cygwin = @{setup_path="c:\cygwin64\setup-x86_64.exe"; path="C:\cygwin64"}
                    version = "0.0.2"
                    inventory = "inventory.yml"
                    ansible_versions = @("2.4.5.0", "2.5.5")
                    name = "role-with-inventory"
                    ci_platform = "appveyor-windows"
                    verbosity = 3
                }
            },
            @{
                Path = "appveyor_with_verbosity.yml"
                Expected = @{
                    cygwin = @{setup_path="c:\cygwin64\setup-x86_64.exe"; path="C:\cygwin64"}
                    version = "0.0.3"
                    inventory = "inventory.ini"
                    ansible_versions = @("2.4.5.0", "2.5.5")
                    name = "role-with-verbosity"
                    ci_platform = "appveyor-windows"
                    verbosity = 4
                }
            },
            @{
                Path = "no_platform.yml"
                Expected = @{
                    cygwin = @{setup_path="d:\cygwin64\setup.exe"; path="d:\cygwin64"}
                    version = "0.0.4"
                    inventory = "tmp-inventory.ini"
                    ansible_versions = @("2.4.5.0", "2.5.5")
                    name = "role-unknown-platform"
                    ci_platform = "unknown"
                    verbosity = 3
                }
            }
        ) {
            param($Path, $Expected)
            $Expected = ConvertTo-Json -InputObject (ConvertTo-OrderedDictionary $Expected)

            # if no platform is et we need to create the "test" inventory file
            if ($Path -eq "no_platform.yml") {
                $test_path = Join-Path -Path $tmp_path -ChildPath tests
                New-Item -Path $test_path -ItemType Directory > $null
                New-Item -Path (Join-Path -Path $test_path -ChildPath tmp-inventory.ini) -ItemType File > $null
            }

            $yaml_path = Join-Path "$PSScriptRoot\Resources\metadata_tests" -ChildPath $Path
            $test_path = Join-Path -Path $tmp_path -ChildPath "PSTestWinibleZ.yml"
            Copy-Item -Path $yaml_path -Destination $test_path
            $actual = Get-AnsibleRoleMetadata -Path $tmp_path
            $actual = ConvertTo-Json -InputObject (ConvertTo-OrderedDictionary $actual)
            $actual | Should -Be $Expected
        }
    }

    It 'Fail when mandatory key not set with meta <Path>' -TestCases @(
        @{
            Path = "mandatory_key_not_set.yml"
            Expected = "Expecting key 'name' to be set under 'ps_ansible_tester' in PSTestWinibleZ.yml"
        },
        @{
            Path = "invalid_ci_platform.yml"
            Expected = "ci_platform must be one of the following values: appveyor-windows"
        },
        @{
            Path = "no_platform_and_cygwin.yml"
            Expected = "No Ansible runner environment specified, please set cygwin with the keys 'path' and 'setup_path' to continue"
        },
        @{
            Path = "no_platform_and_inventory_file.yml"
            Expected = "abc"
        }
    ) {
        param($Path, $Expected)
        $yaml_path = Join-Path "$PSScriptRoot\Resources\metadata_tests" -ChildPath $Path
        $test_path = Join-Path -Path $tmp_path -ChildPath "PSTestWinibleZ.yml"
        Copy-Item -Path $yaml_path -Destination $test_path

        if ($Path -eq "no_platform_and_inventory_file.yml") {
            $Expected = "The inventory file at '$tmp_path\tests\inventory.ini' does not exist"
        }
        { Get-AnsibleRoleMetadata -Path $tmp_path } | Should -Throw $Expected
    }

    It 'Fail on invalid path' {
        $expected_path = Join-Path -Path "fakepath" -ChildPath "PSTestWinibleZ.yml"
        { Get-AnsibleRoleMetadata -Path "fakepath" } | Should -Throw "Expecting Ansible metadata file at '$expected_path' but it was not there"
    }

    AfterEach {
        if (Test-Path -Path $tmp_path) {
            Remove-Item -Path $tmp_path -Force -Recurse > $null
        }
    }
}
