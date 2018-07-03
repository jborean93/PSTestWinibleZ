Function Invoke-BashCygwin {
    param (
        [Parameter(Mandatory=$true)]$Executable,
        [Parameter(Mandatory=$true)]$Arguments
    )

    return Invoke-Executable -Executable $Executable -Arguments "--login -c '$Arguments'"
}