# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force
. $PSScriptRoot\..\PSTestWinibleZ\Private\$module_name.ps1

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'executable with rc of 0' {
            $actual = Invoke-Executable -Executable "powershell.exe" -Arguments "`$host.UI.WriteLine('stdout'); `$host.UI.WriteErrorLine('stderr'); exit 0"
            $actual | Should -Be 0
        }

        It 'executable with rc of 1' {
            $actual = Invoke-Executable -Executable "powershell.exe" -Arguments "`$host.UI.WriteLine('stdout'); `$host.UI.WriteErrorLine('stderr'); exit 1"
            $actual | Should -Be 1
        }

        It 'executable and return output' {
            $actual = Invoke-Executable -Executable "powershell.exe" -Arguments "`$host.UI.WriteLine('stdout'); `$host.UI.WriteErrorLine('stderr'); exit 0" -GetOutput
            $actual[0] | Should -Be "stdout`r`n"
            $actual[1] | Should -Be "stderr`r`n"
            $actual[2] | Should -Be 0
        }

        It 'arguments as list' {
            $actual = Invoke-Executable -Executable "cmd.exe" -Arguments @("/c", "cd", "C:\Program Files", "&&", "cd") -GetOutput
            $actual[0] | Should -Be "C:\Program Files`r`n"
            $actual[1] | Should -Be ""
            $actual[2] | Should -Be 0
        }
    }
}
