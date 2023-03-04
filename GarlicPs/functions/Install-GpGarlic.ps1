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

.PARAMETER ROMDriveLetter
	If the ROM partition does not get assigned a drive letter on re-insert, assign it this one
	to make it accessible.

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
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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
		[string]$ExpandPartitionThresholdMb = "64MB",
		[Parameter (Mandatory = $false)]
		[string]$ROMDriveLetter = "R"
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
		if ($PSCmdlet.ShouldContinue($targetBalenaDrive, " Flash device with GarlicOS image? This will format and erase any existing data on the device.")) {
			Invoke-GpBalenaFlash -ImgPath $garlicImgPath -TargetDrive $targetBalenaDrive
		}

		## Step 3 - Eject and re-insert SD
		Write-Output ""
		Write-Output "Safely eject the SD card, then re-insert it."
		Read-Host "Press enter to continue"

		## Step 4 - Configure FAT32 partition if needed, doesn't always auto-assign drive
		if ($isWindows) {
			$targetDisk = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE Index = $TargetDeviceNumber"
			$targetDiskPartitions = Get-WmiObject -Query "SELECT * FROM Win32_DiskPartition WHERE DiskIndex = $($targetDisk.Index)"
			$ROMPartition = $targetDiskPartitions[-1] # Feels hacky, maybe a better way to identify other than its index as last partition?
			$ROMPartitionNumber = $ROMPartition.Index + 1 # Most partition use is 1-based, but the above returns 0-based indexing
			$ROMDrive = (Get-Partition -DiskNumber $targetDisk.Index -PartitionNumber $ROMPartitionNumber).DriveLetter
			if ($null -eq $ROMDrive) {
				# Assign drive letter to ROM partition
				Write-Verbose -Message "Setting #$($targetDisk.Index), partition #$ROMPartitionNumber to drive letter '$ROMDriveLetter'."
				Set-Partition -DiskNumber $targetDisk.Index -PartitionNumber $ROMPartitionNumber -NewDriveLetter $ROMDriveLetter
			}
			else {
				Write-Verbose -Message "Found ROM partition as drive '$ROMDrive'"
			}
		}

		## Step 5 - Expand ROM partition - Windows only currently
		# WIP - Need to copy files out of ROM Partition, drop partition, create new partition up to 32GB
		# and then re-copy the files back over. Not sure if this is worth it since builtin Windows options
		# can't create FAT32 > 32GB. Might make more sense to leave this as a manual step if desired.
		if ($IsWindows -and (1 -eq 0)) {
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
					$diskPartScriptPath = Join-Path -Path $TempPath -ChildPath "GpdiskPart.txt"
					$newPartitionSizeBytes = $targetDiskFreeSpaceBytes + $ROMPartition.Size
					$newPartitionSizeMb = ($newPartitionSizeBytes / 1MB)
					# These are sloppy conversions, leave 10MB wiggle room to avoid issues
					$newPartitionSizeMb -= 10
					$newPartitionSizeMb = ([Math]::Round($newPartitionSizeMb, 0))
					$diskpartScript = `
						"TBD"
					Set-Content -Value $diskpartScript -Path $diskPartScriptPath -Force
					Invoke-Expression -Command "diskpart /s $diskPartScriptPath" -ErrorAction 'Stop'
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
			Write-Warning -Message "ROM partition expansion is not supported currently."
		}

		## Step 6 - Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination ($ROMDrive + ":\")

		## Tada!
		Invoke-GpThanks
	}
}
