# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    RootModule = 'PSTestWinibleZ.psm1'
    ModuleVersion = '0.1.2'
    GUID = '7395e601-efc5-4248-8d2e-d1983fbf7204'
    Author = 'Jordan Borean'
    Copyright = 'Copyright (c) 2018 by Jordan Borean, Red Hat, licensed under MIT.'
    Description = "Helper cmdlets to automatically test Ansible Windows Roles in a CI environment.`nSee https://github.com/jborean93/PSTestWinibleZ for more info"
    PowerShellVersion = '3.0'
    FunctionsToExport = @(
        'Test-AnsibleRole'
    )
    RequiredModules = @(
        @{
            ModuleName = 'powershell-yaml'
            Guid = '6a75a662-7f53-425a-9777-ee61284407da'
            ModuleVersion = '0.1'
        },
        @{
            ModuleName = 'psake'
            Guid = 'cfb53216-072f-4a46-8975-ff7e6bda05a5'
            ModuleVersion = '4.6.0'
        }
    )
    PrivateData = @{
        PSData = @{
            Tags = @(
                "Automation",
                "DevOps",
                "Windows",
                "Ansible"
            )
            LicenseUri = 'https://github.com/jborean93/PSTestWinibleZ/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jborean93/PSTestWinibleZ'
            ReleaseNotes = 'See https://github.com/jborean93/PSTestWinibleZ/blob/master/CHANGELOG.md'
        }
    }
}
