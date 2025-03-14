param(
	[Parameter(Mandatory = $true)]
	[string]$FilePath
)

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Read from stdin and attempt to decrypt
		$input | sops -d
	} catch {
		# If decryption fails, return the content as-is
		$input
	}
} else {
	# If no key is present, return the content as-is
	$input
}
