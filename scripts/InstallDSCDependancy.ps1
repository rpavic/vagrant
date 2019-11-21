Install-WindowsFeature -Name DNS -IncludeManagementTools
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name ActiveDirectoryDsc -Force
Install-Module -Name StorageDsc -Force
Install-Module -Name NetworkingDsc -Force