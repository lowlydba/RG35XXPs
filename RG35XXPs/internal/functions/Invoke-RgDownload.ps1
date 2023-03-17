function Invoke-RgDownload {

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$BatoceraUri,
        [Parameter (Mandatory = $true)]
        [string]$BatoceraZip,
        [Parameter (Mandatory = $true)]
        [string]$TempPath
    )
    process {
        try {
            $BatoceraZipPath = Join-Path -Path $TempPath -ChildPath $BatoceraZip

            Write-Verbose -Message "Downloading from '$BatoceraUri'"
            Invoke-WebRequest -Uri $BatoceraUri -OutFile $BatoceraZipPath -ContentType "application/x-7z-compressed" -Verbose:$false
            Write-Verbose -Message "Batocera saved to $BatoceraZipPath"

            return $BatoceraZipPath
        }
        catch {
            Write-Error -Message "Error downloading Batocera: $($_.Exception.Message)"
        }
    }
}
