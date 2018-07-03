# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="var is used in test and AfterEach blocks")]
param()

$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force
. $PSScriptRoot\..\PSTestWinibleZ\Private\$module_name.ps1

Describe "$module_name PS$ps_version tests" {
    BeforeEach {
        $tmp_path = [System.IO.Path]::GetTempFileName()
    }

    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Convert text line endings <InputData> to <Expected>' -TestCases @(
            @{ InputData = "abc\r\ndef"; Expected = "abc\ndef" },
            @{ InputData = "abc\ndef"; Expected = "abc\ndef" },
            @{ InputData = "abc\n\rdef"; Expected = "abc\n\rdef" },
            @{ InputData = "abc\r\ndef\r\n"; Expected = "abc\ndef\n" },
            @{ InputData = "abc\ndef\n"; Expected = "abc\ndef\n" },
            @{ InputData = "\r\n"; Expected = "\n" },
            @{ InputData = "\n"; Expected = "\n" }
        ) {
            param($InputData, $Expected)
            $InputData = $InputData.Replace("\r", "`r").Replace("\n",  "`n")
            $Expected = $Expected.Replace("\r", "`r").Replace("\n", "`n")

            [System.IO.File]::WriteAllText($tmp_path, $InputData)
            Convert-FileLineEndings -Path $tmp_path
            $actual = [System.IO.File]::ReadAllText($tmp_path)
            $actual | Should -Be $Expected
        }

        It 'Fails to convert a non-existant path' {
            { Convert-FileLineEndings -Path "fake path" } | Should -Throw "Cannot convert line endings of file fake path as it is not accessible or does not exist"
        }
    }

    AfterEach {
        Remove-Item -Path $tmp_path -Force > $null
    }
}
