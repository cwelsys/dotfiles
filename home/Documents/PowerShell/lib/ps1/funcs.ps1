function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
function export($name, $value) {
    Set-Item -Path "env:$name" -Value $value
}

function lock { Invoke-Command { rundll32.exe user32.dll, LockWorkStation } }
function hibernate { shutdown.exe /h }
function shutdown { Stop-Computer }
function reboot { Restart-Computer }
function HKLM { Set-Location HKLM: }
function HKCU { Set-Location HKCU: }
function lsenv { Get-ChildItem Env: }
function lspath { $env:PATH -Split ';' }
function e { Invoke-Item . }
function Get-PubIp {
  (Invoke-WebRequest http://ifconfig.me/ip ).Content
}
function sysinfo { if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c all } else { Get-ComputerInfo } }
function fortune {
    [System.IO.File]::ReadAllText("$Env:PWSH\fortune.txt") -replace "`r`n", "`n" -split "`n%`n" | Get-Random
}
function profiles { Get-PSProfile { $_.exists -eq "True" } | Format-List }

function Get-PSProfile {
    $PROFILE.PSExtended.PSObject.Properties |
    Select-Object Name, Value, @{Name = 'IsExist'; Expression = { Test-Path -Path $_.Value -PathType Leaf } }
}

function Get-Weather {
    <#
    .SYNOP
        Display the current weather and forecast.
    .DESCRIPTION
        Fetches the weather information from https://wttr.in for terminal
        display.
    .PARAMETER Request
        The full URL to the wttr request.
    .PARAMETER Timeout
        The number of seconds to wait for a response.
    .EXAMPLE
        Get-Weather nF 10
    .INPUTS
        System.String
    .OUTPUTS
        System.String
    .LINK
        https://github.com/chubin/wttr.in
    .LINK
        https://wttr.in
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [string]$Request,

        [Parameter(Mandatory = $false)]
        [PSDefaultValue(Help = '10')]
        [int]$Timeout = 10
    )

    begin {
        if ($Request) {
            $Request = '?' + $Request
        }
        $Request = 'https://wttr.in' + $Request
    }

    process {
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Encoding", 'deflate, gzip')
        (Invoke-WebRequest -Uri "$Request" -UserAgent "curl" -Headers $headers -UseBasicParsing -TimeoutSec "$Timeout").content
    }
}

function Get-WeatherForecast {
    <#
    .SYNOPSIS
        Displays detailed weather and forecast.
    .DESCRIPTION
        Fetches the weather information from wttr.in for terminal display.
    .INPUTS
        None
    .OUTPUTS
        System.String
    .LINK
        https://wttr.in
    #>
    [CmdletBinding()]
    param()

    Get-Weather 'F'
}

function Get-WeatherCurrent {
    <#
    .SYNOPSIS
        Displays current weather.
    .DESCRIPTION
        Fetches the weather information from wttr.in for terminal display.
    .INPUTS
        None
    .OUTPUTS
        System.String
    .LINK
        https://wttr.in
    #>
    [CmdletBinding()]
    param()

    Get-Weather 'format=%l:+(%C)+%c++%t+[%h,+%w]'
}

function deltmp {
    Write-ColorText "{Gray}Deleting temp data..."

    $path1 = "C" + ":\Windows\Temp"
    Get-ChildItem $path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    $path2 = "C" + ":\Windows\Prefetch"
    Get-ChildItem $path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    $path3 = "C" + ":\Users\*\AppData\Local\Temp"
    Get-ChildItem $path3 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    Write-ColorText "{Green}Temp data deleted successfully."
}
