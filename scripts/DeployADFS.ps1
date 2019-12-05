
function New-ADFSCertificate {

    $Domain = (Get-AdDomain | Select-Object -ExpandProperty Name)
    $DnsName = "adfs.$Domain.local"
    $CertLocation = "cert:\\localmachine\my"
    $CertRootLocation = "cert:\localmachine\Root"

    try {
        $InstalledCertificate = Get-ChildItem $CertLocation | Where-Object { $_.Subject -like "*$DnsName*" } -ErrorAction SilentlyContinue
        if ($InstalledCertificate) {
            Write-Host "A certificate for $DnsName already exists."
        }
        else {
            Write-Host "Creating a certificate for $DnsName and adding it to the TrustedRoot."
            New-SelfSignedCertificate -DnsName $DnsName, certauth.$DnsName -CertStoreLocation $CertLocation | Out-Null
        }

        $InstalledRootCertificate = Get-ChildItem $CertRootLocation | Where-Object { $_.Subject -like "*$DnsName*" } -ErrorAction SilentlyContinue
        if ($InstalledRootCertificate) {
            Write-Host "A certificate for $DnsName is imported to TrustedRoot."
        }
        else {
            $Password = ConvertTo-SecureString -String "1234" -Force -AsPlainText
            $Thumbprint = Get-ChildItem $CertLocation | Where-Object { $_.Subject -like "*$DnsName*" } | Sort-Object NotBefore -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Thumbprint 
            Export-PfxCertificate -Cert $CertLocation\$Thumbprint -FilePath "C:\$DnsName.pfx" -Password $Password | Out-Null
            Import-PfxCertificate -FilePath "C:\$DnsName.pfx" -Password $Password -Exportable -CertStoreLocation $CertRootLocation | Out-Null
            Remove-Item -Path "C:\$DnsName.pfx"
        }

    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }
}

function New-ADFSFarm {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $DnsName
    )

    $Domain = (Get-AdDomain | Select-Object -ExpandProperty Name)
    $PublicDomainSplit = $DnsName.Split(".")
    $PublicDomain = ($PublicDomainSplit[-2] + "." + $PublicDomainSplit[-1])
    $CertLocation = "cert:\\localmachine\my"

    try {
        $Thumbprint = Get-ChildItem $CertLocation | Where-Object { $_.Subject -like "*$PublicDomain*" } | Sort-Object NotBefore -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Thumbprint 
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }

    $KdsRootKey = Get-KdsRootKey
    if (!($KdsRootKey)) {
        try {
            Write-Host "Creating KdsRootKey."
            Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10) | Out-Null
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    $ErrorActionPreference = "SilentlyContinue"
    $ServiceAccountName = "adfs_gmsa"
    $ServiceAccount = Get-AdServiceAccount $ServiceAccountName
    $ErrorActionPreference = "Continue"
    if (!($ServiceAccount)) {
        try {
            Write-Host "Creating a service account."
            New-ADServiceAccount -Name $ServiceAccountName -DNSHostName $DnsName -AccountExpirationDate $null -ServicePrincipalNames http/$DnsName | Out-Null
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    if ((Get-WindowsFeature -Name ADFS-Federation).Installed -eq $false) {
        try {
            Write-Host "Installing ADFS windows feature."
            Add-WindowsFeature -Name ADFS-Federation | Out-Null
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    try {
        Write-Host "Installing ADFS farm $DnsName."
        Install-AdfsFarm -CertificateThumbprint $Thumbprint -FederationServiceName $DnsName -FederationServiceDisplayName "ADFS" -GroupServiceAccountIdentifier "$Domain\$ServiceAccountName$" -OverwriteConfiguration
        Write-Host "Adding $DnsName to hosts file"
        Add-Content -Value "127.0.0.1 $DnsName" -Path "C:\Windows\system32\drivers\etc\hosts"
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }
}
