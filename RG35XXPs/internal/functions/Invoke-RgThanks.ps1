function Invoke-RgThanks {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false)]
        [string]$Action
    )
    if ($PSBoundParameters.ContainsKey('Action')) {
        Write-Host "🎮  Batocera successfully $Action!" -ForegroundColor DarkYellow
    }
    else {
        Write-Host "☕  Buy lowlydba a coffee if you enjoy this PowerShell project - https://buymeacoffee.com/johnmcc"-ForegroundColor Cyan
    }

}
