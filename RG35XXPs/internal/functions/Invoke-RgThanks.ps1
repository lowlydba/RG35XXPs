function Invoke-RgThanks {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$Action
    )
    Write-Host "🧄  Batocera successfully $Action!" -ForegroundColor DarkYellow
    Write-Host "☕  Buy the author a coffee if you enjoy this project - https://www.buymeacoffee.com/johnmcc"-ForegroundColor Cyan
}
