param(
	[Parameter(Mandatory = $true)]
	[string]$FilePath
)

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Attempt to encrypt
		$encrypted = sops -e $FilePath
		$encrypted
	} catch {
		# If encryption fails, return content as-is
		Get-Content $FilePath -Raw
	}
} else {
	# If no key is present, return content as-is
	Get-Content $FilePath -Raw
}
