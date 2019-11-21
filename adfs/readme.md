# Domain controller with ADFS

1. `vagrant up`
2. Once the VM is provisioned, wait for it to install Active Directory and reboot 
3. Log in as **test\Administrator** using VirtualBox Manager
4. Open Powershell as Administrator
5. Dot Source the scripts for deploying ADFS  
   `. C:\Install\DeployADFS.ps1`
6. Run functions  
   `New-ADFSCertificate`  
   `Install-ADFS`  
7. Reboot the machine