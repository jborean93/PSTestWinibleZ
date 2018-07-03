# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-FileLineEndings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="We are changing endings not an ending")]
    param (
        [Parameter(Mandatory=$true)]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Cannot convert line endings of file $Path as it is not accessible or does not exist"
    }
    Write-Verbose -Message "coverting line endings from \r\n to \n for '$Path'"
    $file_text = [System.IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($Path, $file_text)
}
