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

    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.RedirectStandardOutput = $true

    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Management.Automation.Host;

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

        public static void WriteProcessOutput(StreamReader stdoutStream, StreamReader stderrStream, PSHostUserInterface hostUI)
        {
            EventWaitHandle sowait = new EventWaitHandle(false, EventResetMode.ManualReset);
            EventWaitHandle sewait = new EventWaitHandle(false, EventResetMode.ManualReset);
            ThreadPool.QueueUserWorkItem((s)=>
            {
                while (!stdoutStream.EndOfStream)
                    hostUI.WriteLine(stdoutStream.ReadLine());
                sowait.Set();
            });
            ThreadPool.QueueUserWorkItem((s) =>
            {
                while (!stderrStream.EndOfStream)
                    hostUI.WriteErrorLine(stderrStream.ReadLine());
                sewait.Set();
            });
            foreach(WaitHandle wh in new WaitHandle[] { sowait, sewait })
                wh.WaitOne();
        }
    }
}
'@

    $process.Start() > $null
    if ($GetOutput) {
        $stdout = $stderr = $null
        [Command.ProcessUtil]::GetProcessOutput($process.StandardOutput, $process.StandardError, [ref]$stdout, [ref]$stderr)
        $process.WaitForExit() > $null
        return $stdout, $stderr, $process.ExitCode
    } else {
        # AppVeyor console does not have a proper ConsoleHost, we need to use
        # the PSHostUserInterface methods to write the child process' stdout
        # and stderr
        [Command.ProcessUtil]::WriteProcessOutput($process.StandardOutput, $process.StandardError, $Host.UI)
        $process.WaitForExit() > $null
        return $process.ExitCode
    }
}
