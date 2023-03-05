function Invoke-GpThanks {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$Action
    )
    Write-Host "🧄  GarlicOS successfully $Action!" -ForegroundColor DarkYellow
    Write-Host "🙏  Thanks to Black Seraph for GarlicOS - https://www.patreon.com/bePatron?u=8770518" -ForegroundColor Magenta
    Write-Host "☕  Buy the author a coffee if you enjoy this project - https://www.buymeacoffee.com/johnmcc"-ForegroundColor Cyan
}
