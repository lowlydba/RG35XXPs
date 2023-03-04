<#
.SYNOPSIS
    🧄 Install GarlicOS!

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

.PARAMETER TargetDeviceNumber
    The index of the target SD card device. Can be found using diskpart.exe or equivalent.

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after installation.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after installation.

.PARAMETER ExpandPartitionThresholdMb
	The threshold in MB of unallocated space on the target disk.
	If exceeded, the ROM partition will be expanded to utilize the space.

.EXAMPLE
    Install-GpGarlic -GarlicUrl "https://www.patreon.com/file?h=76561333&i=13249827" -TargetDeviceNumber 2 -ClearTempPath $true

	Fetches GarlicOS from a Patreon attachment URL and installs it on an SD card identified as Disk #2.
	Clears any files that may exist in the temp path.

.EXAMPLE
	Install-GpGarlic -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-MicroSDCardImage.7z" -TargetDeviceNumber 1 -ClearTempPath $true -TempPath "C:\temp"

	Uses a local GarlicOS file and installs it on an SD card identified as Disk #1.
	Stores temp files in C:\temp.
	Clears any files that may already exist in C:\temp.
#>
#Requires -RunAsAdministrator
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
		[ValidateRange(1, 99)]
		[int]$TargetDeviceNumber,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $true,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath,
		[Parameter (Mandatory = $false)]
		[string]$ExpandPartitionThresholdMb = "64MB"
	)
	process {
		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOS"

		## Get disk info
		# Balena is case sensitive, so get the deviceId from its util to avoid issues
		$targetBalenaDrive = Get-GpBalenaDrive -TargetDeviceNumber $TargetDeviceNumber

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
		Expand-Gp7Zip -ArchivePath $garlicZipPath -TargetPath $garlicPath

		## Step 2 - Flash garlic.img to SD
		$garlicImgPath = Join-Path -Path $garlicPath -ChildPath "garlic.img"
		Invoke-GpBalenaFlash -ImgPath $garlicImgPath -TargetDrive $targetBalenaDrive

		## Step 3 - Eject and re-insert SD
		Write-Output ""
		Write-Output "Safely eject the SD card, then re-insert it."
		Read-Host "Press enter to continue"

		## Step 4 - Expand ROM partition - Windows only currently
		if ($IsWindows) {
			$targetDisk = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE Index = $TargetDeviceNumber"
			$targetDiskPartitions = Get-WmiObject -Query "SELECT * FROM Win32_DiskPartition WHERE DiskIndex = $($targetDisk.Index)"
			# Calculate unallocated space
			[long]$targetDiskSizeBytes = $targetDisk.Size
			[long]$targetDiskUsedSpaceBytes = 0
			foreach ($partition in $targetDiskPartitions) {
				$targetDiskUsedSpaceBytes += $partition.Size
			}
			[long]$targetDiskFreeSpaceBytes = $targetDiskSizeBytes - $targetDiskUsedSpaceBytes
			# If we have > $ExpandPartitionThresholdMb unallocated space, expand to use it
			if ($targetDiskFreeSpaceBytes -gt $ExpandPartitionThresholdMb) {
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
				Write-Verbose -Message "Less than $ExpandPartitionThresholdMb space left on the disk, skipping ROM partition expansion."
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
