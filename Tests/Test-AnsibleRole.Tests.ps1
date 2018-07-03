# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        # run a full integration test on a role
        It 'runs a test on a successful role' {
            $actual = Test-AnsibleRole -Path (Join-Path -Path ($PSScriptRoot) -ChildPath Resources | Join-Path -ChildPath simple)
            $actual.build_success | Should -be $true
        }

        # mock out the New-CygwinSetup to save time on the remaining tests
        It 'runs a test on an unsuccessful role' {
            $actual = Test-AnsibleRole -Path (Join-Path -Path ($PSScriptRoot) -ChildPath Resources | Join-Path -ChildPath fail-role)
            $actual.build_success | Should -Be $false
        }
    }
}
