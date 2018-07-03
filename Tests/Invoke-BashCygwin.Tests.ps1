# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force
. $PSScriptRoot\..\PSTestWinibleZ\Private\$module_name.ps1

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Invoke bash cygwin tests' {
            $script:actual_executable = $null
            $script:actual_arguments = $null
            $script:actual_get_output = $null
            Function Invoke-Executable {
                param(
                    [Parameter(Mandatory=$true)][String]$Executable,
                    $Arguments,
                    [Switch]$GetOutput
                )
                $script:actual_executable = $Executable
                $script:actual_arguments = $Arguments
                $script:actual_get_output = $GetOutput.ToBool()
            }
            # because we mock out the Invoke-Executable cmdlet we don't
            # actually do anything with the input params apart from validate
            # them
            Invoke-BashCygwin -Executable "C:\cygwin64\bin\bash.exe" -Arguments "echo hi"
            $script:actual_arguments | Should -Be "--login -c 'echo hi'"
            $script:actual_executable | Should -Be "C:\cygwin64\bin\bash.exe"
            $script:actual_get_output | Should -Be $false
        }
    }
}
