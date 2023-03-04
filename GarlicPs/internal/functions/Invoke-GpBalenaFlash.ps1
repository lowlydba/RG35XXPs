function Invoke-GpBalenaFlash {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$TargetDrive,
        [string]$ImgPath
    )
    try {
        Write-Verbose -Message "Flashing GarlicOS image to disk '$targetBalenaDrive' (this may take a while)"
        $flashCmd = "balena local flash '$ImgPath' --drive '$targetBalenaDrive' -y"
        Invoke-Expression -Command $flashCmd
    }
    catch {
        Write-Error -Message "Error flashing GarlicOS image to disk using command "$flashCmd": $($_.Exception.Message)"
    }

}
