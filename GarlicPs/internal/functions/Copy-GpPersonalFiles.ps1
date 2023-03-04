function Copy-GpPersonalFiles {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false)]
        [string]$BIOSPath,
        [Parameter (Mandatory = $false)]
        [string]$ROMPath,
        [Parameter (Mandatory = $true)]
        [string]$Destination
    )
    process {
        try {
            if ($BIOSPath -ne "") {
                $BIOSDestinationPath = Join-Path -Path $Destination -ChildPath "BIOS"
                Write-Verbose -Message "Copying BIOS files from '$BIOSPath' to '$BIOSDestinationPath'"
                Copy-Item -Path $BIOSPath -Destination $BIOSDestinationPath -Recurse -Force -Confirm:$false
            }
            if ($ROMPath -ne "") {
                $ROMDestinationPath = Join-Path -Path $Destination -ChildPath "Roms"
                Write-Verbose -Message "Copying ROM files from '$ROMPath' to '$ROMDestinationPath'"
                Copy-Item -Path $ROMPath -Destination $ROMDestinationPath -Recurse -Force -Confirm:$false
            }
        }
        catch {
            Write-Error -Message "Error copying personal game files: $($_.Exception.Message)"
        }
    }
}
