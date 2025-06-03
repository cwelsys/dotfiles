clink installscripts "$HOME/.config/clink/prompt"
clink installscripts "$HOME/.config/clink/clink-gizmos"
clink installscripts "$HOME/.config/clink/more-clink-completions"
clink set prompt.transient always

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


Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1" | Invoke-Expression

