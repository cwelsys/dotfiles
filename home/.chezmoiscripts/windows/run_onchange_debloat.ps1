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

Get-AppxPackage -AllUsers Clipchamp.Clipchamp | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.BingNews | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.BingWeather | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.GamingApp | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.GetHelp | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.Getstarted | Remove-AppPackage
Get-AppxPackage -AllUsers Microsoft.Microsoft3DViewer | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.MicrosoftStickyNotes | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.MixedReality.Portal | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.OutlookForWindows | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.People | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.SkypeApp | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.StorePurchaseApp | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.Windows.Photos | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.WindowsAlarms | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.WindowsCommunicationsApps | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.WindowsFeedbackHub | Remove-AppPackage
Get-AppxPackage -AllUsers Microsoft.WindowsMaps | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.WindowsSoundRecorder | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.YourPhone | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.ZuneMusic | Remove-AppxPackage
Get-AppxPackage -AllUsers Microsoft.ZuneVideo | Remove-AppxPackage

# https://learn.microsoft.com/en-us/answers/questions/1421927/uninstall-unpin-spotify-whatsapp-etc-using-script

$Junk = 'phone|disney|skype|spotify|groove|solitaire|zune|mixedreality|tiktok|adobe|prime|soundrecorder|bingweather!3dviewer'
'Removing apps for this user only.'
$packages = Get-AppxPackage | Where-Object { $_.Name -match $Junk } | Where-Object -Property NonRemovable -eq $false
foreach ($appx in $packages) {
  'Removing {0}' -f $appx.name
  Remove-AppxPackage $appx
}
''
'Removing apps for all users.'
$packages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -match $Junk } | Where-Object -Property NonRemovable -eq $false
foreach ($appx in $packages) {
  'Removing {0}' -f $appx.name
  Remove-AppxPackage $appx -AllUsers
}
''
'Removing provisioned apps.'
$packages = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match $Junk }
foreach ($appx in $packages) {
  'Removing {0}' -f $appx.displayname
  Remove-AppxProvisionedPackage -online -allusers -PackageName $appx.PackageName
}
