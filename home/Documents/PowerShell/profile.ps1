# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 🌐 Env
$env:DOTS = & chezmoi source-path
$env:DOTFILES = $env:DOTS
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:LIBS = Join-Path -Path $Env:PWSH -ChildPath 'lib'
$Env:PYTHONIOENCODING = 'utf-8'
$env:CARAPACE_BRIDGES = 'powershell,inshellisense'
$env:CARAPACE_NOSPACE = '*'

#(wt nightly overrides SSH_AUTH_SOCK)
$env:SSH_AUTH_SOCK = '\\.\pipe\openssh-ssh-agent'

# 📝 Editor
if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = 'code' }
else {
	if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = 'nvim' }
	else { $Env:EDITOR = 'notepad' }
}

foreach ($module in $((Get-ChildItem -Path "$env:LIBS\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}
foreach ($file in $((Get-ChildItem -Path "$env:LIBS\*" -Include *.ps1).FullName)) {
	. "$file"
}

# 🐚 Prompt
# if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
# 	oh-my-posh init pwsh --config "$HOME\.config\posh.toml" | Invoke-Expression
# }
# if (Get-Command starship -ErrorAction SilentlyContinue) {
# 	Invoke-Expression (&starship init powershell)
# }

$prompt = ''
function Invoke-Starship-PreCommand {
	$current_location = $executionContext.SessionState.Path.CurrentLocation
	if ($current_location.Provider.Name -eq 'FileSystem') {
		$ansi_escape = [char]27
		$provider_path = $current_location.ProviderPath -replace '\\', '/'
		$prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
	}
	$host.ui.Write($prompt)
}

function Invoke-Starship-TransientFunction {
	&starship module character
}

Invoke-Expression (&starship init powershell)

Enable-TransientPrompt


# 💤 zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	$Env:_ZO_DATA_DIR = "$Env:PWSH"
	Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

carapace _carapace | Out-String | Invoke-Expression

# 🐶 FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
	if ([Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
		Return
	}
	fastfetch
}
