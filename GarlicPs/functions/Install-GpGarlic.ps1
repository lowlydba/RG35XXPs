<#
.SYNOPSIS
    Install GarlicOS!

.DESCRIPTION
    Automate installation of GarlicOS.

.PARAMETER LocalFile
    The full path of a copy of RG35XX-MicroSDCardImage.7z locally available. If not supplied, it is downloaded.

.PARAMETER GarlicURL
    The URL of the GarlicOS update file (RG35XX-MicroSDCardImage.7z), ex: https://www.patreon.com/file?h=76561333&i=13249827
	Note: With each new version of GarlicOS, old URLs become invalid. Ensure a valid one is being passed.

.PARAMETER GarlicInstallZipName
	When using GarlicURL, the name to save the downloaded file as in the TempPath.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER TargetDiskNumber
    The index of the target SD card disk. Can be found using diskpart.exe

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after installation.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after installation.

.PARAMETER ExpandPartitionThreshold
	The threshold (in MB) of unallocated space on the target disk.
	If exceeded, the ROM partition will be expanded to utilize the space.

.EXAMPLE
    Install-GpGarlic -GarlicUrl "https://www.patreon.com/file?h=76561333&i=13249827" -TargetDiskNumber 2 -ClearTempPath $true
#>
function Install-GpGarlic {

	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $true, ParameterSetName = "local")]
		[string]$LocalFile,
		[Parameter (Mandatory = $true, ParameterSetName = "remote")]
		[string]$GarlicURL,
		[Parameter (Mandatory = $false, ParameterSetName = "remote")]
		[string]$GarlicInstallZipName = "RG35XX-MicroSDCardImage.7z",
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[Parameter (Mandatory = $true)]
		[int]$TargetDiskNumber,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $true,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath,
		[Parameter (Mandatory = $false)]
		[string]$ExpandPartitionThreshold = "64MB"
	)
	process {
		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOS"

		# Get disk info
		Write-Verbose -Message "Gathering info on disk #$TargetDiskNumber"
		$targetDisk = GET-WMIOBJECT -Query "SELECT * FROM Win32_DiskDrive"

		# Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		## Step 1 - Download & extract GarlicOS
		# Download latest version
		try {
			if ($LocalFile -eq "") {
				$garlicInstallUri = $GarlicURL
				$garlicZipPath = Invoke-GpDownload -TempPath $TempPath -GarlicZip $GarlicInstallZipName -GarlicUri $garlicInstallUri
			}
			else {
				$garlicZipPath = $LocalFile
			}
		}
		catch {
			Write-Error -Message "Error downloading GarlicOS: $($_.Exception.Message)"
		}

		# Decompress the archive
		try {
			Expand-7Zip -ArchiveFileName $garlicZipPath -TargetPath $garlicPath
		}
		catch {
			Write-Error -Message "Error extracting GarlicOS: $($_.Exception.Message)"
		}

		## Step 2 - Flash garlic.img to SD
		$garlicImg = Join-Path -Path $garlicPath -ChildPath "garlic.img"
		Invoke-Expression -Command "balena local flash '$garlicImg' -y --drive $($targetDisk.Name)"

		## Step 3 - Eject and re-insert SD
		Write-Output "Safely eject the SD card, then re-insert it."
		Read-Host "Press enter when done."

		## Step 4 - Expand ROM partition
		# Calculate unallocated space
		[int]$targetDiskSize = $targetDisk.Size
		$targetDiskPartitions = GET-WMIOBJECT -Query "SELECT * FROM Win32_DiskPartition WHERE DiskIndex = $($targetDisk.Index)"
		[int]$targetDiskUsedSpace = 0
		foreach ($partition in $targetDiskPartitions) {
			$targetDiskUsedSpace += $partition.Size
		}
		[int]$targetDiskFreeSpace = $targetDiskSize - $targetDiskUsedSpace
		# If we have > $ExpandPartitionThreshold unallocated space, expand to use it
		if ($targetDiskFreeSpace -gt $ExpandPartitionThreshold) {
			$ROMPartition = $targetDiskPartitions | Where-Object { $_.Name -eq "ROM" } #TODO: Make this work
			Write-Verbose -Message "Expanding ROM partition to max available size"
			$diskPartScriptPath = Join-Path -Path $TempPath -ChildPath "GpdiskPart.txt"
			#TODO: actually expand the partition
			$diskpartScript = "
			diskpart
			list disk
			select disk $($targetDisk.Index)
			select partition $($ROMPartition.Index)
			expand $targetDiskFreeSpace"
			Set-Content -Value $diskpartScript -Path $diskPartScriptPath -Force
			Invoke-Expression -Command "diskpart /s $diskPartScriptPath"
		}

		## Step 5 - Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination #$TargetPath

		## Tada!
		Invoke-GpThanks
	}
}
