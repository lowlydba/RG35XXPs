function Invoke-GpDownload {

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false)]
        [string]$GarlicUri = "https://www.patreon.com/file?h=76561333&i=13218537",
        [Parameter (Mandatory = $false)]
        [string]$GarlicZip = "RG35XX-MicroSDCardImage.7z",
        [Parameter (Mandatory = $true)]
        [string]$TempPath
    )
    process {
        $garlicZipPath = Join-Path -Path $TempPath -ChildPath $garlicZip

        Write-Verbose -Message "Getting latest version from $garlicUri"
        Invoke-WebRequest -Uri $garlicUri -OutFile $garlicZipPath -ContentType "application/x-7z-compressed"
        Write-Verbose -Message "GarlicOS saved to $garlicZipPath"

        return $garlicZipPath
    }
}
