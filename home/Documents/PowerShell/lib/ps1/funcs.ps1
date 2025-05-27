function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
function HKLM { Set-Location HKLM: }
function HKCU { Set-Location HKCU: }
function lsenv { Get-ChildItem Env: }
function lspath { $env:PATH -Split ';' }
function e { Invoke-Item . }
function sysinfo { if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c all } else { Get-ComputerInfo } }

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
