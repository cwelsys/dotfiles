# $ezaParams = @(
# 	'--icons'
# 	'--header'
# 	'--hyperlink'
# 	'--group'
# 	'--git'
# 	'-I=*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv'
# 	'--group-directories-first'
# )

$ezaParams = @(
	'--git'
	'--group'
	'--hyperlink'
	'--group-directories-first'
	'--time-style=long-iso'
	'--color-scale=all'
	'--icons'
	'-I=*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv'
)

function Invoke-Eza {
	[alias('ls')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams @Path
}

function Invoke-EzaGitIgnore {
	[alias('l')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams --git-ignore @Path
}

# function Invoke-EzaDir {
# 	[alias('ld')]
# 	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
# 	eza.exe $ezaParams -lDa --show-symlinks --time-style=relative @Path
# }

# function Invoke-EzaFile {
# 	[alias('lf')]
# 	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
# 	eza.exe $ezaParams -lfa --show-symlinks --time-style=relative @Path
# }

function Invoke-EzaList {
	[alias('ll')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	# eza.exe $ezaParams -la --time-style=relative --sort=modified @Path
	eza.exe $ezaParams --all --header --long @Path
}

function Invoke-EzaAll {
	[alias('la')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	# eza.exe $ezaParams -la @Path
	eza.exe $ezaParams -lbhHigUmuSa @Path
}

function Invoke-EzaOneline {
	[alias('lo')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams --oneline @Path
}

function Invoke-EzaExtended {
	[alias('lx')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	# eza.exe $ezaParams -la --extended @Path
	eza.exe $ezaParams -lbhHigUmuSa@ @Path
}

function Invoke-EzaTree {
	[alias('lt', 'tree')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams --tree @Path
}
