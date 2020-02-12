function Set-Locale {
    try {
        $currentLangAndKeyboard = (Get-WinUserLanguageList).InputMethodTips

        if ($currentLangAndKeyboard -eq "0409:00000409") {
            $langList = New-WinUserLanguageList hr-HR
            $langList[0].InputMethodTips.Clear()
            $langList[0].InputMethodTips.Add('041a:0000041a') # Croatian - Croatia
            Write-Host "Setting the input locale to hr-HR."
            Set-WinUserLanguageList $langList -Force
        }
        Else {
            Write-Host "Input locale is set to hr-HR."
        }
    }
    catch {
        throw "Cannot set input locale to hr-HR."
    }      
}

function Install-Code {
    $ErrorActionPreference = "SilentlyContinue"
    $Script = Get-InstalledScript -Name "Install-VsCode" -ErrorAction SilentlyContinue
    $Code = & code -v
    if ($Script) {
        Write-Host "Install-VSCode.ps1 script is installed"
    }
    else {
        Write-Host "Installing Install-VSCode scipt from the PS Gallery."
        Install-Script -Name Install-VSCode -Force
    }

    if ($Code) {
        Write-Host "VS Code is installed."
    }
    else {
        Install-VsCode.ps1  
    }
}
