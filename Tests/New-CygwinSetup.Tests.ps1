$ps_version = $PSVersionTable.PSVersion.Major
$module_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Import-Module -Name $PSScriptRoot\..\PSTestWinibleZ -Force
. $PSScriptRoot\..\PSTestWinibleZ\Private\$module_name.ps1
. $PSScriptRoot\..\PSTestWinibleZ\Private\Invoke-BashCygwin

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Fails to install Cygwin packages' -TestCases @(
            @{
                Expected = "Failed to setup Cygwin with the required packages, rc: 1"
                FailInvocation = 1
            }
            @{
                # this covers 2 and 3 as the 2nd call only writes a warning (Failed to update pip and setuptools)
                Expected = "Failed to install the required Python packages in Cygwin for PSTestWinibleZ, rc: 1"
                FailInvocation = 2
            }
            @{
                Expected = "Failed to remove Ansible from the base Python packages in Cygwin, rc: 1"
                FailInvocation = 4
            }
            @{
                Expected = "Failed to create virtualenv in Cygwin at PSTestWinibleZ-Ansible-2.5.5, rc: 1"
                FailInvocation = 5
            }
            @{
                Expected = "Failed to install Ansible 2.5.5 in the virtualenv PSTestWinibleZ-Ansible-2.5.5, rc: 1"
                FailInvocation = 6
            }
        ) {
            param($Expected, $FailInvocation)
            $script:failure = $FailInvocation
            $script:invocation_count = 0

            Function Invoke-Executable {
                param(
                    [Parameter(Mandatory=$true)][String]$Executable,
                    $Arguments,
                    [Switch]$GetOutput
                )
                $script:invocation_count += 1
                if ($script:invocation_count -ge $script:failure) {
                    return 1
                } else {
                    return 0
                }
            }

            { New-CygwinSetup -Path "C:\root" -SetupExe "C:\setup.exe" -AnsibleVersions "2.5.5" } | Should -Throw $Expected
        }

        It 'Calls the correct Invoke-Executable cmdlets' {
            # because we can't guarantee Cygwin is installed on the system, we
            # mock out the calls and verify they are what we expect
            $script:exec_invocations = @()
            Function Invoke-Executable {
                param(
                    [Parameter(Mandatory=$true)][String]$Executable,
                    $Arguments,
                    [Switch]$GetOutput
                )
                $script:exec_invocations += @{
                    Executable = $Executable
                    Arguments = $Arguments
                    GetOutput = $GetOutput.ToBool()
                }
                return 0
            }

            $expected = New-Object -TypeName System.Collections.ArrayList
            $expected.Add("PSTestWinibleZ-Ansible-2.5.5") > $null
            $expected.Add("PSTestWinibleZ-Ansible-2.4.5.0") > $null

            $actual = New-CygwinSetup -Path C:\root -SetupExe C:\root\setup.exe -AnsibleVersions 2.5.5, 2.4.5.0
            $actual | Should -Be $expected
            $script:exec_invocations.Count | Should -Be 10

            $exec1 = $script:exec_invocations[0]
            $exec1.GetOutput | Should -Be $false
            $exec1.Arguments | Should -Be @(
                "--quiet-mode",
                "--no-desktop",
                "--no-shortcuts",
                "--site", "http://cygwin.mirror.constant.com",
                "--root", "C:\root",
                "--packages", "_autorebase,alternatives,base-cygwin,base-files,bash,binutils,bzip2,ca-certificates,coreutils,csih,curl,cygrunsrv,cygutils,cygwin-devel,dash,desktop-file-utils,diffutils,editrights,file,findutils,gamin,gawk,gcc-core,getent,grep,groff,gsettings-desktop-schemas,gzip,hostname,info,ipc-utils,less,libargp,libatomic1,libattr1,libblkid1,libbz2_1,libcom_err2,libcrypt0,libcurl4,libdb5.3,libedit0,libexpat1,libfam0,libffi-devel,libffi6,libgc2,libgcc1,libgcrypt20,libgdbm4,libglib2.0_0,libgmp10,libgomp1,libgpg-error0,libgssapi_krb5_2,libguile2.0_22,libiconv,libiconv2,libidn2_0,libintl8,libisl15,libk5crypto3,libkrb5_3,libkrb5support0,libltdl7,liblzma5,libmetalink3,libmpc3,libmpfr6,libncursesw10,libnghttp2_14,libopenldap2_4_2,libopenssl100,libp11-kit0,libpcre1,libpipeline1,libpopt-common,libpopt0,libpsl5,libquadmath0,libreadline7,libsasl2_3,libsigsegv2,libsmartcols1,libsqlite3_0,libssh2_1,libstdc++6,libtasn1_6,libunistring2,libuuid-devel,libuuid1,libxml2,libxslt,login,make,man-db,mintty,ncurses,openssh,openssl,openssl-devel,p11-kit,p11-kit-trust,pkg-config,publicsuffix-list-dafsa,python,python-crypto,python2,python2-appdirs,python2-asn1crypto,python2-backports.ssl_match_hostname,python2-cffi,python2-chardet,python2-cryptography,python2-devel,python2-enum34,python2-idna,python2-ipaddress,python2-jinja2,python2-lockfile,python2-lxml,python2-markupsafe,python2-openssl,python2-packaging,python2-pip,python2-ply,python2-pycparser,python2-pyparsing,python2-requests,python2-setuptools,python2-six,python2-urllib3,python2-wheel,rebase,run,sed,shared-mime-info,tar,terminfo,tzcode,tzdata,util-linux,vim-minimal,w32api-headers,w32api-runtime,which,windows-default-manifest,xz,zlib0"
            )
            $exec1.Executable | Should -Be "C:\root\setup.exe"

            $exec2 = $script:exec_invocations[1]
            $exec2.GetOutput | Should -Be $false
            $exec2.Arguments | Should -Be "--login -c 'pip2 install -U pip setuptools'"
            $exec2.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec3 = $script:exec_invocations[2]
            $exec3.GetOutput | Should -Be $false
            $exec3.Arguments | Should -Be "--login -c 'LIBSODIUM_MAKE_ARGS=-j4 pip2 install ansible pywinrm[credssp] virtualenv'"
            $exec3.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec4 = $script:exec_invocations[3]
            $exec4.GetOutput | Should -Be $false
            $exec4.Arguments | Should -Be "--login -c 'pip2 uninstall ansible -y'"
            $exec4.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec5 = $script:exec_invocations[4]
            $exec5.GetOutput | Should -Be $false
            $exec5.Arguments | Should -Be "--login -c 'virtualenv PSTestWinibleZ-Ansible-2.5.5 --system-site-packages'"
            $exec5.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec6 = $script:exec_invocations[5]
            $exec6.GetOutput | Should -Be $false
            $exec6.Arguments | Should -Be "--login -c 'PSTestWinibleZ-Ansible-2.5.5/bin/pip install ansible==2.5.5 ansible-lint'"
            $exec6.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec7 = $script:exec_invocations[6]
            $exec7.GetOutput | Should -Be $false
            $exec7.Arguments | Should -Be "--login -c 'PSTestWinibleZ-Ansible-2.5.5/bin/ansible --version'"
            $exec7.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec8 = $script:exec_invocations[7]
            $exec8.GetOutput | Should -Be $false
            $exec8.Arguments | Should -Be "--login -c 'virtualenv PSTestWinibleZ-Ansible-2.4.5.0 --system-site-packages'"
            $exec8.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec9 = $script:exec_invocations[8]
            $exec9.GetOutput | Should -Be $false
            $exec9.Arguments | Should -Be "--login -c 'PSTestWinibleZ-Ansible-2.4.5.0/bin/pip install ansible==2.4.5.0 ansible-lint'"
            $exec9.Executable | Should -Be "C:\root\bin\bash.exe"

            $exec10 = $script:exec_invocations[9]
            $exec10.GetOutput | Should -Be $false
            $exec10.Arguments | Should -Be "--login -c 'PSTestWinibleZ-Ansible-2.4.5.0/bin/ansible --version'"
            $exec10.Executable | Should -Be "C:\root\bin\bash.exe"
        }
    }
}