$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force
. $PSScriptRoot\..\PSTestWinibleZ\Private\$module_name.ps1

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Get Cygwin path with stdout <stdout>, stderr <stderr> and rc <rc>' -TestCases @(
            @{expected="/cygdrive/c/temp"; stdout="/cygdrive/c/temp"; stderr=""; rc=0}
            @{expected="/cygdrive/c/temp"; stdout="/cygdrive/c/temp\n"; stderr=""; rc=0}
            @{expected="/cygdrive/c/temp"; stdout="/cygdrive/c/temp\r\n"; stderr=""; rc=0}
        ) {
            param($expected, $stdout, $stderr, $rc)
            $stdout = $stdout.Replace("\r", "`r").Replace("\n", "`n")
            $stderr = $stderr.Replace("\r", "`r").Replace("\n", "`n")

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
                $script:actual_get_output = $GetOutput.ToBool
                return $stdout, $stderr, $rc
            }
            # because we mock out the Invoke-Executable cmdlet we don't
            # actually do anything with the input params apart from validate
            # them
            $actual = Get-BashPathCygwin -Path "c:\some path" -BinPath "C:\cygwin64\bin"
            $actual | Should -Be $expected
            $script:actual_arguments | Should -Be "C:\some path"
            $script:actual_executable | Should -Be "C:\cygwin64\bin\cygpath.exe"
            $script:actual_get_output | Should -Be $true
        }

        It 'Get Cygwin path should fail with non zero rc' {
            Function Invoke-Executable {
                param(
                    [Parameter(Mandatory=$true)][String]$Executable,
                    $Arguments,
                    [Switch]$GetOutput
                )
                return "stdout", "stderr", 1
            }
            { Get-BashPathCygwin -Path "c:\some path" -BinPath "C:\cygwin64\bin" } | Should -Throw "Failed to get the Cygwin path to 'c:\some path'. RC: 1, STDOUT: 'stdout', STDERR: 'stderr'"
        }
    }
}