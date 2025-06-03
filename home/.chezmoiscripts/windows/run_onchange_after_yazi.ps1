$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

function Install-YaziPlugin {
    param(
        [Parameter(Mandatory = $true)][string]$PluginPath,
        [Parameter(Mandatory = $false)][string]$Description
    )

    Write-Host "Installing $PluginPath..." -ForegroundColor Cyan
    if ($Description) {
        Write-Host "  Description: $Description" -ForegroundColor Gray
    }

    try {
        ya pack -a $PluginPath
        Write-Host "  Success!" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to install $PluginPath" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

Write-Host "=== Installing Yazi Plugins ===" -ForegroundColor Magenta

# Core functionality plugins
Write-Host "`nCore Functionality Plugins:" -ForegroundColor Yellow
Install-YaziPlugin "AnirudhG07/custom-shell" "Custom shell execution"
Install-YaziPlugin "lpnh/fr" "Enhanced file renaming"
Install-YaziPlugin "dawsers/toggle-view" "Toggle between different view modes"
Install-YaziPlugin "yazi-rs/plugins:hide-preview" "Hide preview panel"
Install-YaziPlugin "yazi-rs/plugins:max-preview" "Maximize preview panel"
Install-YaziPlugin "yazi-rs/plugins:smart-filter" "Smart filtering capabilities"

# File preview plugins
Write-Host "`nPreview Plugins:" -ForegroundColor Yellow
Install-YaziPlugin "AnirudhG07/rich-preview" "Enhanced preview capabilities"
Install-YaziPlugin "Reledia/glow" "Markdown preview with Glow"
Install-YaziPlugin "yazi-rs/plugins:diff" "Show file differences"

# Git-related plugins
Write-Host "`nGit Plugins:" -ForegroundColor Yellow
Install-YaziPlugin "yazi-rs/plugins:git" "Git integration"
Install-YaziPlugin "imsi32/yatline-githead" "Git HEAD integration"

# UI enhancements
Write-Host "`nUI Enhancement Plugins:" -ForegroundColor Yellow
Install-YaziPlugin "yazi-rs/plugins:full-border" "Full border UI"
Install-YaziPlugin "Rolv-Apneseth/starship" "Starship prompt integration"
Install-YaziPlugin "imsi32/yatline" "Custom status line"
Install-YaziPlugin "yazi-rs/plugins:chmod" "File permission management"

# Themes
Write-Host "`nThemes:" -ForegroundColor Yellow
Install-YaziPlugin "yazi-rs/flavors:catppuccin-mocha" "Catppuccin Mocha theme"

Write-Host "`n=== Yazi Plugin Installation Complete ===" -ForegroundColor Magenta
