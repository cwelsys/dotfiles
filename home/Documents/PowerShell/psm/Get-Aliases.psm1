function Get-Aliases {
	[CmdletBinding()]
	[Alias('aliae')]
	param()
	Get-MyAlias |
	Sort-Object Source, Name |
	Format-Table -Property Name, Definition, Version, Source -AutoSize
}
