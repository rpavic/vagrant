configuration DeployAD
{
    param
    (
        $Password,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $DomainName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName StorageDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc

    $UserName = "Vagrant"
    $Credential = New-Object System.Management.Automation.PSCredential ("$UserName", $Password)
    $SafeModePassword = New-Object System.Management.Automation.PSCredential ("$UserName", $Password)

    node 'localhost'
    {
        LocalConfigurationManager {
            ActionAfterReboot  = 'ContinueConfiguration'
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }


        File 'ADFiles' {
            DestinationPath = 'C:\NTDS'
            Type            = 'Directory'
            Ensure          = 'Present'
        }
        File 'SysVolFiles' {
            DestinationPath = 'C:\SysVol'
            Type            = 'Directory'
            Ensure          = 'Present'
        }
        WindowsFeature 'ADDS' {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT-Powershell' {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT-AD' {
            Name   = 'RSAT-ADDS'
            Ensure = 'Present'
        }
        
        WindowsFeature 'ADFS-Federation' {
            Name   = 'ADFS-Federation'
            Ensure = 'Present'
        }

        ADDomain AD {
            Credential                    = $Credential
            DomainName                    = $DomainName + ".local"
            DomainNetBiosName             = $DomainName
            SafemodeAdministratorPassword = $SafeModePassword
            DatabasePath                  = 'C:\NTDS'
            LogPath                       = 'C:\NTDS'
            SysvolPath                    = 'C:\SysVol'
            DependsOn                     = "[WindowsFeature]ADDS", "[File]ADFiles", "[File]SysVolFiles"
        }
        
    }

}

$ConfigurationData = @{
    AllNodes = @(
        @{
            Nodename                    = "localhost"
            RetryCount                  = 20
            RetryIntervalSec            = 30 
            PSDscAllowDomainUser        = $true
            PsDscAllowPlainTextPassword = $true
        }
    )
}

DeployAD -Password (ConvertTo-SecureString -String "P@ssword" -AsPlainText -Force) -DomainName test -ConfigurationData $ConfigurationData

Set-DscLocalConfigurationManager -Path .\DeployAD -Verbose

Start-DscConfiguration -Force -Path .\DeployAD -Verbose
