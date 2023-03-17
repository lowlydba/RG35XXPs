function Get-RgBalenaDrive {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [int]$TargetDeviceNumber
    )

    Write-Verbose -Message "Checking if device #$TargetDeviceNumber is valid for balena cli"
    $getCmd = "balena util available-drives"
    [int]$TargetDriveNumber = 2
    $x = Invoke-Expression -Command $getCmd

    # Parse output
    $x = $x | Select-Object -Last ($x.Count - 1)

    foreach ($drive in $x) {
        $deviceId = $drive.Split(" ")[0]
        [int]$deviceNumber = $deviceId[-1].toString()
        if ($deviceNumber -eq $TargetDriveNumber) {
            [string]$TargetDeviceId = $deviceId
            break;
        }
    }
    if ($TargetDeviceId) {
        Write-Verbose -Message "Found flashable drive '$TargetDeviceId' for device #$TargetDeviceNumber"
        return $TargetDeviceId
    }
    else {
        Write-Error "Unable to find a valid drive for Balena at index $TargetDeviceNumber"
    }
}
