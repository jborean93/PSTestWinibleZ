Function Get-BashPathCygwin {
    param(
        [Parameter(Mandatory=$true)][String]$Path,
        [Parameter(Mandatory=$true)][String]$BinPath
    )
    $cygpath_exe = Join-Path -Path $BinPath -ChildPath "cygpath.exe"

    $stdout, $stderr, $rc = Invoke-Executable -Executable $cygpath_exe -Arguments $Path -GetOutput
    if ($rc -ne 0) {
        throw "Failed to get the Cygwin path to '$Path'. RC: $rc, STDOUT: '$stdout', STDERR: '$stderr'"
    }
    return $stdout.TrimEnd()
}