# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Invoke-BashCygwin {
    param (
        [Parameter(Mandatory=$true)]$Executable,
        [Parameter(Mandatory=$true)]$Arguments
    )

    return Invoke-Executable -Executable $Executable -Arguments "--login -c '$Arguments'"
}
