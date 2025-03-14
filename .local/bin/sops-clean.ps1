param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
    $env:SOPS_AGE_KEY_FILE = $keyPath
    sops -e $FilePath
} else {
    Get-Content $FilePath -Raw
}
