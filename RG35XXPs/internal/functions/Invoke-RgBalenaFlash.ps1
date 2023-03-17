function Invoke-RgBalenaFlash {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$TargetDrive,
        [string]$ImgPath
    )
    try {
        Write-Verbose -Message "Flashing Batocera image to drive '$targetBalenaDrive' (this may take a while)"
        $flashCmd = "balena local flash '$ImgPath' --drive '$targetBalenaDrive' -y"
        Invoke-Expression -Command $flashCmd -ErrorAction 'Stop'
    }
    catch {
        Write-Error -Message "Error flashing Batocera image to disk using command "$flashCmd": $($_.Exception.Message)"
    }
}
