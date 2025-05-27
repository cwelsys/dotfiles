if (!(Get-Process -Name komorebi -ErrorAction SilentlyContinue)) {
	komorebic enable-autostart --whkd
}

if (!(Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
	yasbc.exe enable-autostart --task
}
