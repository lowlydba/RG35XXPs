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

	Fetches GarlicOS from a Patreon attachment URL and installs it on an SD card identified as Disk #2.
	Clears any files that may exist in the temp path.

.EXAMPLE
	Install-GpGarlic -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-MicroSDCardImage.7z" -TargetDiskNumber 1 -ClearTempPath $true -TempPath "C:\temp"

	Uses a local GarlicOS file and installs it on an SD card identified as Disk #1.
	Stores temp files in C:\temp.
	Clears any files that may already exist in C:\temp.
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
		$targetDisk = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive"

		# Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		## Step 1 - Download & extract GarlicOS
		if ($LocalFile -eq "") {
			$garlicInstallUri = $GarlicURL
			$garlicZipPath = Invoke-GpDownload -TempPath $TempPath -GarlicZip $GarlicInstallZipName -GarlicUri $garlicInstallUri
		}
		else {
			$garlicZipPath = $LocalFile
		}

		# Extract the archive
		try {
			Expand-7Zip -ArchiveFileName $garlicZipPath -TargetPath $garlicPath
		}
		catch {
			Write-Error -Message "Error extracting GarlicOS: $($_.Exception.Message)"
		}

		## Step 2 - Flash garlic.img to SD
		try {
			Write-Verbose -Message "Flashing Garlic image to disk #$TargetDiskNumber"
			$garlicImg = Join-Path -Path $garlicPath -ChildPath "garlic.img"
			Invoke-Expression -Command "balena local flash '$garlicImg' -y --drive $($targetDisk.Name)"
		}
		catch {
			Write-Error -Message "Error flashing Garlic image to disk: $($_.Exception.Message)"
		}

		## Step 3 - Eject and re-insert SD
		Write-Output "Safely eject the SD card, then re-insert it."
		Read-Host "Press enter when done."

		## Step 4 - Expand ROM partition - Windows only currently
		if ($IsWindows) {
			# Calculate unallocated space
			[int]$targetDiskSizeBytes = $targetDisk.Size
			$targetDiskPartitions = GET-WMIOBJECT -Query "SELECT * FROM Win32_DiskPartition WHERE DiskIndex = $($targetDisk.Index)"
			[int]$targetDiskUsedSpaceBytes = 0
			foreach ($partition in $targetDiskPartitions) {
				$targetDiskUsedSpaceBytes += $partition.Size
			}
			[int]$targetDiskFreeSpaceBytes = $targetDiskSizeBytes - $targetDiskUsedSpaceBytes
			# If we have > $ExpandPartitionThreshold unallocated space, expand to use it
			if ($targetDiskFreeSpaceBytes -gt $ExpandPartitionThreshold) {
				try {
					Write-Verbose -Message "Expanding ROM partition to max available size"
					$ROMPartition = $targetDiskPartitions | Where-Object { $_.Name -eq "ROM" } #TODO: Make this work
					$diskPartScriptPath = Join-Path -Path $TempPath -ChildPath "GpdiskPart.txt"
					$newPartitionSizeBytes = $targetDiskFreeSpaceBytes + $ROMPartition.Size
					$newPartitionSizeMb = ($newPartitionSizeBytes / 1MB)
					# These are sloppy conversions, leave 10MB wiggle room to avoid issues
					$newPartitionSizeMb -= 10
					$diskpartScript = `
						"diskpart
						select disk $($targetDisk.Index)
						select partition $($ROMPartition.Index)
						extend size=$newPartitionSizeMb"
					Set-Content -Value $diskpartScript -Path $diskPartScriptPath -Force
					Invoke-Expression -Command "diskpart /s $diskPartScriptPath"
				}
				catch {
					Write-Warning -Message "Error expanding ROM partition to utilize remaining disk space. Try manually. Error: $($_.Exception.Message)"
				}
			}
			else {
				Write-Verbose -Message "Less than $ExpandPartitionThreshold space left on the disk, skipping ROM partition expansion."
			}
		}
		else {
			Write-Warning -Message "ROM partition expansion is only supported on Windows currently."
		}

		## Step 5 - Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination #$TargetPath

		## Tada!
		Invoke-GpThanks
	}
}
