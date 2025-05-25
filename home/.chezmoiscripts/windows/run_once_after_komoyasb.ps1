if (!(Get-Process -Name komorebi -ErrorAction SilentlyContinue)) {
	Start-Process "powershell.exe" -ArgumentList "komorebic.exe", "enable-autostart", "--whkd" -WindowStyle Hidden -Wait
}

if (!(Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
	Start-Process "powershell.exe" -ArgumentList "yasbc.exe", "enable-autostart", "--task" -WindowStyle Hidden -Wait
}
