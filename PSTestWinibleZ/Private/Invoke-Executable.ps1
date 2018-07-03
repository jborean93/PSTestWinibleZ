# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Invoke-Executable {
    param(
        [Parameter(Mandatory=$true)][String]$Executable,
        $Arguments,
        [Switch]$GetOutput
    )
    Write-Verbose -Message "Starting executable '$Executable' aith the arguments '$Arguments'"

    $process = New-Object -TypeName System.Diagnostics.Process
    $process.StartInfo.FileName = $Executable
    $process.StartInfo.Arguments = $Arguments
    $process.StartInfo.UseShellExecute = $false

    if ($GetOutput) {
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.RedirectStandardOutput = $true

        Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Linq;
using System.Threading;
namespace Command
{
    public static class ProcessUtil
    {
        public static void GetProcessOutput(StreamReader stdoutStream, StreamReader stderrStream, out string stdout, out string stderr)
        {
            EventWaitHandle sowait = new EventWaitHandle(false, EventResetMode.ManualReset);
            EventWaitHandle sewait = new EventWaitHandle(false, EventResetMode.ManualReset);
            string so = null;
            string se = null;
            ThreadPool.QueueUserWorkItem((s)=>
            {
                so = stdoutStream.ReadToEnd();
                sowait.Set();
            });
            ThreadPool.QueueUserWorkItem((s) =>
            {
                se = stderrStream.ReadToEnd();
                sewait.Set();
            });
            foreach(WaitHandle wh in new WaitHandle[] { sowait, sewait })
                wh.WaitOne();
            stdout = so;
            stderr = se;
        }
    }
}
'@
    }

    $process.Start() > $null

    if ($GetOutput) {
        $stdout = $stderr = $null
        [Command.ProcessUtil]::GetProcessOutput($process.StandardOutput, $process.StandardError, [ref]$stdout, [ref]$stderr)
        $process.WaitForExit() > $null
        return $stdout, $stderr, $process.ExitCode
    } else {
        $process.WaitForExit() > $null
        return $process.ExitCode
    }
}
