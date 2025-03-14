# Get content from stdin
$input | Out-String | Set-Content -Path $args[0] -NoNewline

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Encrypt and output to stdout
		sops -e $args[0]
	} catch {
		# If encryption fails, output original content
		Get-Content $args[0] -Raw
	}
} else {
	# If no key present, output original content
	Get-Content $args[0] -Raw
}
