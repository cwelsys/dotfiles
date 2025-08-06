clink installscripts "$HOME\.config\clink\scripts"

if (!(Get-Process -Name komorebi -ErrorAction SilentlyContinue)) {
	komorebic enable-autostart --whkd
}

if (!(Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
	yasbc.exe enable-autostart --task
}

if (Get-Command cargo -ErrorAction SilentlyContinue) {
	cargo install cargo-update
	cargo install cargo-cache
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
	Write-Verbose "Building bat theme"
	bat cache --clear
	bat cache --build
}

