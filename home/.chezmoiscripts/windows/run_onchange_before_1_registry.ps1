# Self-elevate
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -Wait -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

Import-Module Microsoft.PowerShell.Security
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
Set-ExecutionPolicy Bypass -Scope Process -Force

# Registry Tweaks
Write-Host "`nApplying registry tweaks..." -ForegroundColor Cyan

# Long path support
Write-Host "Enabling long path support..." -ForegroundColor Gray
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

# Explorer stuff
Write-Host "Configuring File Explorer settings..." -ForegroundColor Gray
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1

# Show file extensions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0

# Hide protected OS files
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ShowSuperHidden -Value 0

# Hide empty drives
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideDrivesWithNoMedia -Value 1

# Open File Explorer to This PC
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name LaunchTo -Value 1

New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force
New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -PropertyType DWORD -Value 0

# Disable navigation pane expansion
# Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name NavPaneExpandToCurrentFolder -Value 0
# Hide all folders in navigation pane
# Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name NavPaneShowAllFolders -Value 0

# Remove Gallery from File Explorer
Write-Host "Removing Gallery from File Explorer..." -ForegroundColor Gray
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_41040327\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f

# Hiding Home folder in Explorer
Write-Host "Hiding Home folder in Explorer..." -ForegroundColor Gray
$homePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
if (-not (Test-Path $homePath)) {
    New-Item -Path $homePath -Force | Out-Null
}
Set-ItemProperty -Path $homePath -Name "(Default)" -Value "CLSID_MSGraphHomeFolder" -Type String
Set-ItemProperty -Path $homePath -Name "HiddenByDefault" -Value 1 -Type DWord

# Configure WinRAR to "extract here"
Write-Host "Setting WinRAR extract behavior..." -ForegroundColor Gray
if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
}
$winrarPath1 = "HKCR:\WinRAR\shell\open\command"
$winrarPath2 = "HKCR:\WinRAR.ZIP\shell\open\command"
$winrarValue = "`"C:\Program Files\WinRAR\WinRAR.exe`" x `"%1`""

if (-not (Test-Path $winrarPath1)) {
    New-Item -Path $winrarPath1 -Force | Out-Null
}
if (-not (Test-Path $winrarPath2)) {
    New-Item -Path $winrarPath2 -Force | Out-Null
}

Set-ItemProperty -Path $winrarPath1 -Name "(Default)" -Value $winrarValue
Set-ItemProperty -Path $winrarPath2 -Name "(Default)" -Value $winrarValue

# Configure ShareX path
Write-Host "Setting ShareX configuration path..." -ForegroundColor Gray
$sharexPath = "HKLM:\SOFTWARE\ShareX"
if (-not (Test-Path $sharexPath)) {
    New-Item -Path $sharexPath -Force | Out-Null
}
Set-ItemProperty -Path $sharexPath -Name "PersonalPath" -Value "%UserProfile%\.config\sharex"

# Modify "link" binary value in Explorer
Write-Host "Getting rid of "- Shortcut" text" -ForegroundColor Gray
$linkPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
if (Get-ItemProperty -Path $linkPath -Name "link" -ErrorAction SilentlyContinue) {
    $currentValue = (Get-ItemProperty -Path $linkPath -Name "link").link
    Write-Host "  Current value: $([BitConverter]::ToString($currentValue))" -ForegroundColor DarkGray
    Set-ItemProperty -Path $linkPath -Name "link" -Value ([byte[]](0x00)) -Type Binary
    Write-Host "  Changed to: no shortcut text, no arrow" -ForegroundColor DarkGray
} else {
    Set-ItemProperty -Path $linkPath -Name "link" -Value ([byte[]](0x00)) -Type Binary
    Write-Host "  Created new value: no shortcut text, no arrow" -ForegroundColor DarkGray
}

# Hide specific drive letters in Explorer
Write-Host "Hiding all drives..." -ForegroundColor Gray
$policiesPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $policiesPath)) {
    New-Item -Path $policiesPath -Force | Out-Null
    Write-Host "  Created Explorer policies key" -ForegroundColor DarkGray
}

# NoDrives value explanation:
# This is a bitmask where each bit represents a drive letter (1 = hidden, 0 = visible)
# A=1, B=2, C=4, D=8, E=16, F=32, G=64, H=128, etc. (powers of 2)
# Add the values together to hide multiple drives
# Example: 17 (1+16) hides drives A and E

Set-ItemProperty -Path $policiesPath -Name "NoDrives" -Value 32 -Type DWord
Write-Host "...sike" -ForegroundColor DarkGray
Write-Host "  Set NoDrives value to 32 (hiding F drive)" -ForegroundColor DarkGray

Write-Host "Registry tweaks applied successfully!" -ForegroundColor Green



