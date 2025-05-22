$completionUtils = Join-Path "$PSScriptRoot" -ChildPath "utils.ps1"

if (Test-Path "$completionUtils" -PathType Leaf) {
	. "$completionUtils"
}

$PoshCompletionsDir = Join-Path "$PSScriptRoot" -ChildPath "src"

foreach ($completionFile in $((Get-ChildItem -Path "$PoshCompletionsDir" -Recurse -Include *.ps1).BaseName)) {
	if (Get-Command -Name "$completionFile" -ErrorAction SilentlyContinue) {
		$fileName = Join-Path "$PoshCompletionsDir" -ChildPath "$completionFile.ps1"
		. "$fileName"
	}
}
Remove-Variable PoshCompletionsDir, completionFile, fileName, completionUtils
