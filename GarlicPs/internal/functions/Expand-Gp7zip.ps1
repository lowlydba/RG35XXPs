function Expand-Gp7zip {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$ArchivePath,
        [Parameter (Mandatory = $true)]
        [string]$TargetPath
    )
    try {
        Invoke-Expression -Command "7z e $7ZipPath -o'$TargetPath'"
    }
    catch {
        Write-Error -Message "Error extracting GarlicOS: $($_.Exception.Message)"
    }
}
