Register-ArgumentCompleter -Native -CommandName "speedtest" -ScriptBlock {
	param ($wordToComplete, $commandAst, $cursorPosition)

	$prev = Get-PrevAst $commandAst $cursorPosition

	$options = "-h", "-V", "-L", "-s", "-I", "-i", "-o", "-a", "-A", "-b", "-B", "-v", "--help", "--version", "--servers", "--server-id", "--interface", "--ip", "--host", "--progress-update-interval", "--selection-details", "--output-header"

	switch -CaseSensitive ($prev) {
		("-f", "--format" | Select-String "$prev" -CaseSensitive -SimpleMatch) { "human-readable", "csv", "tsv", "json", "jsonl", "json-pretty" | Where-Object { $_ -like "$wordToComplete*" } }
		("-u", "--unit" | Select-String "$prev" -CaseSensitive -SimpleMatch) { "auto-decimal-bits", "auto-decimal-bytes", "auto-binary-bits", "auto-binary-bytes" | Where-Object { $_ -like "$wordToComplete*" } }
		("-p", "--progress" | Select-String "$prev" -CaseSensitive -SimpleMatch) { "yes", "no" | Where-Object { $_ -like "$wordToComplete*" } }
		( "-P", "--precision" | Select-String "$prev" -CaseSensitive -SimpleMatch) { 0..8 | Where-Object { $_ -like "$wordToComplete*" } }
		Default {}
	}

	if ($wordToComplete -like "-*" -or $prev -like "speedtest*") {
		$addons = "-f", "--format", "-u", "--unit", "-p", "--progress", "-P", "--precision"
		$options + $addons | Sort-Object -CaseSensitive | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { $_ }
	}
}
