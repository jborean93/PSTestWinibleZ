$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        # run a full integration test on a role
        It 'runs a test on a successful role' {
            $actual = Test-AnsibleRole -Path (Join-Path -Path (Get-Location) -ChildPath Resources/simple)
            $actual.build_success | Should -be $true
        }

        # mock out the New-CygwinSetup to save time on the remaining tests
        It 'runs a test on an unsuccessful role' {
            $actual = Test-AnsibleRole -Path (Join-Path -Path (Get-Location) -ChildPath Resources/fail-role)
            $actual.build_success | Should -Be $false
        }
    }
}