if (!(Get-Command wsl -CommandType Application -ErrorAction Ignore)) {
	Start-Process -FilePath "PowerShell" -ArgumentList "wsl", "--install" -Verb RunAs -Wait -WindowStyle Hidden
}


if (!(Get-Process -Name komorebi -ErrorAction SilentlyContinue)) {
	if ($config.misc.komorebi.enable_autostart) {
		Start-Process "powershell.exe" -ArgumentList "komorebic.exe", "enable-autostart", "--whkd" -WindowStyle Hidden -Wait
	}
	Start-Process "powershell.exe" -ArgumentList "komorebic.exe", "start", "--whkd" -WindowStyle Hidden
}


if (!(Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
	Start-Process "powershell.exe" -ArgumentList "yasbc.exe", "enable-autostart", "--task" -WindowStyle Hidden -Wait
	Start-Process "powershell.exe" -ArgumentList "yasbc.exe", "start" -WindowStyle Hidden
}
