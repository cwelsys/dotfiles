if (Get-Command cargo -ErrorAction SilentlyContinue) {
	cargo install cargo-update
	cargo install cargo-cache
}
