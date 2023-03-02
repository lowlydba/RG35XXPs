function Invoke-GpDownload {

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$GarlicUri,
        [Parameter (Mandatory = $true)]
        [string]$GarlicZip,
        [Parameter (Mandatory = $true)]
        [string]$TempPath
    )
    process {
        try {
            $garlicZipPath = Join-Path -Path $TempPath -ChildPath $garlicZip

            Write-Verbose -Message "Getting latest version from $garlicUri"
            Invoke-WebRequest -Uri $garlicUri -OutFile $garlicZipPath -ContentType "application/x-7z-compressed"
            Write-Verbose -Message "GarlicOS saved to $garlicZipPath"

            return $garlicZipPath
        }
        catch {
            Write-Error -Message "Error downloading GarlicOS: $($_.Exception.Message)"
        }
    }
}
