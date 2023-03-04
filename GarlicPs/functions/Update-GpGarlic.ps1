<#
.SYNOPSIS
    🧄 Update GarlicOS!

.DESCRIPTION
    Automate updates of GarlicOS. Downloads, extracts, and copies updated files to the Misc and ROM partitions
	of the primary SD card.

.PARAMETER LocalFile
    The full path of a copy of RG35XX-CopyPasteOnTopOfStock.7z locally available. If not supplied, it is downloaded.

.PARAMETER GarlicURL
    The URL of the GarlicOS update file, ex: https://www.patreon.com/file?h=76561333&i=13249827
	Note: With each new version of GarlicOS, old URLs become invalid. Ensure a valid one is being passed.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER GarlicRootDrive
    The drive that contains the GarlicOS system files on the primary SD card. Ex: 'E:\'

.PARAMETER GarlicROMDrive
	The drive on the primary SD card that contains ROMs from the primary SD card. Ex. 'G:\'

.PARAMETER 2ndGarlicROMDrive
	The drive on a second SD card that is used for an additional ROM partition. Ex 'L:\'
	If not supplied, the GarlicROMDrive is the destination for personal ROM files.

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after upgrade process.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after upgrade process.

.EXAMPLE
    Update-GpGarlic -GarlicURL "https://www.patreon.com/file?h=76561333&i=13249827" -GarlicRootDrive "E:\" -GarlicROMDrive "R:\"

	Update GarlicOS from a downloaded file when the primary "Misc" partition is on the E:\ drive and the ROM partition is the "R:\" drive.
	Both partitions should exist on the primary SD card.


.EXAMPLE
	Update-GpGarlic -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-CopyPasteOnTopOfStock.7z" -GarlicRootDrive "E:\" -GarlicROMDrive "R:\" -ROMPath "C:\Users\lowlydba\MyRomCollection"

	Update GarlicOS from local files when the primary "Misc" partition is on the E:\ drive and the ROM partition is the "R:\" drive.
	Both partitions should exist on the primary SD card. Also copies personal ROMs to the primary SD card's ROM partition.


.EXAMPLE
	Update-GpGarlic -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-CopyPasteOnTopOfStock.7z" -GarlicRootDrive "E:\" -GarlicROMDrive "R:\" -ROMPath "C:\Users\lowlydba\MyRomCollection" -2ndGarlicROMDrive

	Update GarlicOS from local files when the primary "Misc" partition is on the E:\ drive and the ROM partition is the "R:\" drive.
	Both partitions should exist on the primary SD card. Also copies personal ROMs to a secondary SD card's ROM partition.


#>
function Update-GpGarlic {

	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $true, ParameterSetName = "local")]
		[string]$LocalFile,
		[Parameter (Mandatory = $true, ParameterSetName = "remote")]
		[string]$GarlicURL,
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[ValidateScript({ Test-Path -Path $_ })]
		[Parameter (Mandatory = $true)]
		[string]$GarlicRootDrive,
		[Parameter (Mandatory = $false)]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$GarlicROMDrive,
		[Parameter (Mandatory = $false)]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$2ndGarlicROMDrive,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $false,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath
	)
	process {
		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOSUpdate"
		$GarlicUpdateZipName = "RG35XX-CopyPasteOnTopOfStock.7z"

		## Step 1 - Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		## Step 2 - Download latest version
		try {
			if ($LocalFile -eq "") {
				$garlicUpdateUri = $GarlicURL
				$garlicZipPath = Invoke-GpDownload -TempPath $TempPath -GarlicZip $GarlicUpdateZipName -GarlicUri $garlicUpdateUri
			}
			else {
				$garlicZipPath = $LocalFile
			}
		}
		catch {
			Write-Error -Message "Error downloading GarlicOS: $($_.Exception.Message)"
		}

		## Step 3 - Extract the archive
		Expand-Gp7Zip -ArchivePath $garlicZipPath -TargetPath $garlicPath

		## Step 4 - Update GarlicOS
		# Only files on the primary SD card need to be modified, the misc partition and rom partition
		try {
			# Misc / system files
			$miscDir = Join-Path -Path $garlicPath -ChildPath "misc"
			$miscDir = Join-Path -Path $miscDir -ChildPath "*"
			Write-Verbose -Message "Copying misc files from '$miscDir' to '$GarlicRootDrive'"
			Copy-Item -Path $miscDir -Destination $GarlicRootDrive -Recurse -Force -Confirm:$false

			# ROMS - Copy the top level Roms dir that contains BIOS, CFW, and Roms data to the ROM Partition
			$romDir = Join-Path -Path $garlicPath -ChildPath "roms"
			$romDir = Join-Path -Path $romDir -ChildPath "*"
			Write-Verbose -Message "Copying ROM, CFW, and BIOS files from '$romDir' to '$GarlicROMDrive'"
			Copy-Item -Path $romDir -Destination $GarlicROMDrive -Recurse -Force -Confirm:$false
		}
		catch {
			Write-Error -Message "Error updating GarlicOS: $($_.Exception.Message)"
		}

		## Step 5 - Copy personal files
		if ($2ndGarlicROMDrive -eq "") {
			# If no 2nd SD card, use the first card's ROM drive
			$2ndGarlicROMDrive = $GarlicROMDrive
		}
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination $2ndGarlicROMDrive

		# Tada!
		Invoke-GpThanks
	}
}
