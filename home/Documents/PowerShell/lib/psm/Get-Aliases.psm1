function Get-Aliases {
	<#
    .SYNOPSIS
        Show information of user's defined aliases. Alias: aliases
    #>
	[CmdletBinding()]
	param()

	#requires -Module PSScriptTools
	Get-MyAlias |
	Sort-Object Source, Name |
	Format-Table -Property Name, Definition, Version, Source -AutoSize
}

Export-ModuleMember -Function Get-Aliases -Alias aliae
