function Copy-GpGarlicFiles {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false)]
        [string]$ROMPath,
        [Parameter (Mandatory = $false)]
        [string]$BIOSPath,
        [Parameter (Mandatory = $true)]
        [string]$Destination
    )
    try {
        # BIOS
        if ($BIOSPath -ne '') {
            Write-Verbose -Message "Copying GarlicOS BIOS files from '$ROMPath' to '$ROMDestinationPath'"
            Copy-Item -Path $BIOSPath -Destination $Destination -Recurse -Force -Confirm:$false
        }

        # ROM
        if ($ROMPath -ne '') {
            Write-Verbose -Message "Copying GarlicOS ROM files from '$ROMPath' to '$ROMDestinationPath'"
            Copy-Item -Path $ROMPath -Destination $Destination -Recurse -Force -Confirm:$false
        }
    }
    catch {
        Write-Error -Message "Error copying GarlicOS files: $($_.Exception.Message)"
    }
}
