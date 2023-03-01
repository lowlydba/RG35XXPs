function Copy-GpPersonalFiles {

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false)]
        [string]$BIOSPath,
        [Parameter (Mandatory = $false)]
        [string]$ROMPath,
        [Parameter (Mandatory = $true)]
        [string]$TargetPath
    )
    process {
		try {
            if ($BIOSPath -ne "") {
                Copy-Item -Path $BIOSPath -Destination $TargetPath -Recurse -Force -Confirm:$false
            }
            if ($ROMPath -ne "") {
                Copy-Item -Path $ROMPath -Destination $TargetPath -Recurse -Force -Confirm:$false
            }
		}
		catch {
			Write-Error -Message "Error copying personal game files: $($_.Exception.Message)"
		}
    }
}
