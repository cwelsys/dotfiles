# ============================================================================
# PATH Management
# ============================================================================

function Add-ToPath {
    param([string]$Directory)

    if (Test-Path $Directory) {
        $pathParts = $env:PATH -split ';'
        if ($pathParts -notcontains $Directory) {
            $env:PATH = "$Directory;$env:PATH"
        }
    }
}

# Add user bin directories
Add-ToPath "$env:XDG_BIN_HOME"
Add-ToPath "$HOME\bin"

# Development tools
Add-ToPath "$env:CARGO_HOME\bin"
Add-ToPath "$env:GOBIN"
Add-ToPath "$env:NPM_CONFIG_PREFIX\bin"
Add-ToPath "$env:PNPM_HOME"
Add-ToPath "$env:PIPX_HOME\bin"

# Scoop shims (if using scoop)
if (Test-Path "$HOME\scoop\shims") {
    Add-ToPath "$HOME\scoop\shims"
}
