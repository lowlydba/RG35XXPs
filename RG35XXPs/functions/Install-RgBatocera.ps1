<#
.SYNOPSIS
    Install Batocera!

.DESCRIPTION
    Automate installation of Batocera.

.PARAMETER LocalFile
    The full path of a copy of Batocera locally available. If not supplied, it is downloaded.

.PARAMETER Version
    The version tag to download and install.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER TargetDeviceNumber
    The index of the target boot SD card device. Can be found using diskpart.exe or equivalent.

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after installation.

.PARAMETER ExpandPartitionThresholdMb
	The threshold in MB of unallocated space on the target disk.
	If exceeded, the ROM partition will be expanded to utilize the space.

.PARAMETER ROMDriveLetter
	If the ROM partition does not get assigned a drive letter on re-insert, assign it this one
	to make it accessible. If drive letter is already assigned, this value is ignored.

.PARAMETER 2ndSDDrive
	If using two SD cards, the drive letter of the FAT32 formatted drive for ROMs and BIOS files.
	Must be in a valid path format, i.e. 'X:\'

.EXAMPLE
    Install-RgBatocera -BatoceraUrl "https://www.patreon.com/file?h=76561333&i=13249827" -TargetDeviceNumber 2 -ClearTempPath $true

	Fetches Batocera from a Patreon attachment URL and installs it on an SD card identified as Disk #2.
	Clears any files that may exist in the temp path.


.EXAMPLE
	Install-RgBatocera -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-MicroSDCardImage.7z" -TargetDeviceNumber 1 -ClearTempPath $true -TempPath "C:\temp"

	Uses a local Batocera file and installs it on an SD card identified as Disk #1.
	Stores temp files in C:\temp.
	Clears any files that may already exist in C:\temp.

#>
#Requires -RunAsAdministrator
function Install-RgBatocera {
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
	param (
		[Parameter (Mandatory = $true, ParameterSetName = "local")]
		[string]$LocalFile,
		[Parameter (Mandatory = $false, ParameterSetName = "remote")]
		[string]$Version = "latest",
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\RG35XXPs"),
		[Parameter (Mandatory = $true)]
		[ValidateRange(1, 99)]
		[int]$TargetDeviceNumber,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $true,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMDriveLetter = "R",
		[Parameter (Mandatory = $false)]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$2ndSDDrive
	)
	process {
		$BatoceraPath = Join-Path -Path $TempPath -ChildPath "\Batocera"
		$BatoceraInstallZipName = "RG35XX-Batocera.zip"

		## Get disk info
		# Balena is case sensitive, so get the deviceId from its util to avoid issues
		$targetBalenaDrive = Get-RgBalenaDrive -TargetDeviceNumber $TargetDeviceNumber

		# Cleanup/Create temp path for Batocera extraction
		New-RgTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -BatoceraPath $BatoceraPath

		## Step 1 - Download & extract Batocera
		if ($LocalFile -eq "") {
			$assetFilter = "*.img.zip"
			if ($Version -eq "latest") {
				$apiUrl = "https://api.github.com/repos/rg35xx-cfw/rg35xx-cfw.github.io/releases/latest"
				$assetUrl = ((Invoke-WebRequest $apiUrl | ConvertFrom-Json).assets | Where-Object name -like $assetFilter).browser_download_url
			}
			else {
				$apiUrl = "https://api.github.com/repos/rg35xx-cfw/rg35xx-cfw.github.io/releases"
				$assetUrl = ((Invoke-WebRequest $apiUrl | ConvertFrom-Json | Where-Object tag_name -eq $Version).assets | Where-Object name -like $assetFilter).browser_download_url
			}
			$BatoceraZipPath = Invoke-RgDownload -TempPath $TempPath -BatoceraZip $BatoceraInstallZipName -BatoceraUri $assetUrl
		}
		else {
			$BatoceraZipPath = $LocalFile
		}

		# Extract the archive
		Write-Verbose -Message "Expanding $BatoceraZipPath to $BatoceraPath"
		Expand-Archive -Path $BatoceraZipPath -DestinationPath $BatoceraPath

		## Step 2 - Flash Batocera.img to SD
		$BatoceraImgPath = (Get-ChildItem -Path $BatoceraPath -Filter "*.img").FullName
		if ($PSCmdlet.ShouldContinue($targetBalenaDrive, "Flash device with Batocera image? This will format and erase any existing data on the device:")) {
			Invoke-RgBalenaFlash -ImgPath $BatoceraImgPath -TargetDrive $targetBalenaDrive
		}

		# ## Step 3 - Eject and re-insert SD
		# Write-Output ""
		# Write-Output "Safely eject the SD card, then re-insert it."
		# Read-Host "Press enter to continue"

		# ## Step 4 - Configure FAT32 partition if needed, doesn't always auto-assign drive
		# try {
		# 	$ROMVolumeFriendlyName = "BatoceraROM"
		# 	$targetDiskPartitions = Get-Partition -DiskNumber $TargetDeviceNumber
		# 	$ROMPartition = $targetDiskPartitions[-1] # Feels hacky, maybe a better way to identify other than its index as last partition?
		# 	if (!(Get-Partition -DiskNumber $TargetDeviceNumber -PartitionNumber $ROMPartition.PartitionNumber).DriveLetter) {
		# 		# Assign drive letter to ROM partition
		# 		Write-Verbose -Message "Setting drive #$TargetDeviceNumber, partition #$($ROMPartition.PartitionNumber) to drive letter '$ROMDriveLetter' with friendly name '$ROMVolumeFriendlyName'."
		# 		Set-Partition -DiskNumber $TargetDeviceNumber -PartitionNumber $ROMPartition.PartitionNumber -NewDriveLetter $ROMDriveLetter
		# 	}
		# 	else {
		# 		Write-Verbose -Message "Found default ROM partition as volume '$ROMDriveLetter'"

		# 	}
		# 	if (!((Get-Volume -DriveLetter $ROMDriveLetter).FileSystemLabel)) {
		# 		Write-Verbose -Message "Adding friendly name '$ROMVolumeFriendlyName' to '$ROMDriveLetter' drive"
		# 		Set-Volume -DriveLetter $ROMDriveLetter -NewFileSystemLabel $ROMVolumeFriendlyName
		# 	}
		# 	$ROMDrivePath = (Get-PSDrive -Name $ROMDriveLetter).Root
		# }
		# catch {
		# 	Write-Error -Message "Error auto-assigning drive letter to default ROM partition: $($_.Exception.Message)"
		# }

		# ## Step 6 - Copy personal files
		# Copy-RgPersonalFiles -ROMPath $ROMPath -Destination $ROMDrivePath
		Invoke-RgThanks -Action "installed"
	}
}
