function Expand-Gp7zip {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$ArchivePath,
        [Parameter (Mandatory = $true)]
        [string]$TargetPath
    )
    try {
        Write-Verbose -Message "Expanding $ArchivePath to $TargetPath"
        Invoke-Expression -Command "7z e $ArchivePath -o'$TargetPath'"
    }
    catch {
        Write-Error -Message "Error extracting GarlicOS: $($_.Exception.Message)"
    }
}
