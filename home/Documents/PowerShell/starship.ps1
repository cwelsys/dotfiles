function Invoke-Starship-PreCommand {
	Set-ShellIntegration -TerminalProgram $term_app
	function Normalize-Path($path) {
		return $path -replace '/', '\'
	}
	function Set-WindowTitle {
		$currentPath = Normalize-Path (Get-Location).Path
		$windowTitle = $currentPath
		$pathMappings = @(
			@{ Path = Normalize-Path (& chezmoi source-path).Trim(); Display = '' }
			@{ Path = Normalize-Path $HOME; Display = '~' }
		)
		foreach ($mapping in $pathMappings) {
			if ($currentPath.StartsWith($mapping.Path)) {
				$relativePath = $currentPath.Substring($mapping.Path.Length).TrimStart('\') -replace '\\', '/'
				$windowTitle = if ($relativePath) { "$($mapping.Display)/$relativePath" } else { $mapping.Display }
				break
			}
		}
		$host.UI.RawUI.WindowTitle = $windowTitle
	}
	Set-WindowTitle
}

Invoke-Expression (&starship init powershell)

Enable-TransientPrompt
