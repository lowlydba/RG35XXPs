<#
.SYNOPSIS
    🧄 Update Batocera!

.DESCRIPTION
    Automate updates of Batocera. Downloads, extracts, and copies updated files to the Misc and ROM partitions
	of the primary SD card.

.PARAMETER LocalFile
    The full path of a copy of RG35XX-CopyPasteOnTopOfStock.7z locally available. If not supplied, it is downloaded.

.PARAMETER BatoceraURL
    The URL of the Batocera update file, ex: https://www.patreon.com/file?h=76561333&i=13249827
	Note: With each new version of Batocera, old URLs become invalid. Ensure a valid one is being passed.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER BatoceraRootDrive
    The drive that contains the Batocera system files on the primary SD card. Ex: 'E:\'

.PARAMETER BatoceraROMDrive
	The drive on the primary SD card that contains ROMs from the primary SD card. Ex. 'G:\'

.PARAMETER 2ndBatoceraROMDrive
	The drive on a second SD card that is used for an additional ROM partition. Ex 'L:\'
	If not supplied, the BatoceraROMDrive is the destination for personal ROM files.

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after upgrade process.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after upgrade process.

.EXAMPLE
    Update-RgBatocera -BatoceraURL "https://www.patreon.com/file?h=76561333&i=13249827" -BatoceraRootDrive "E:\" -BatoceraROMDrive "R:\"

	Update Batocera from a downloaded file when the primary "Misc" partition is on the E:\ drive and the ROM partition is the "R:\" drive.
	Both partitions should exist on the primary SD card.


.EXAMPLE
	Update-RgBatocera -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-CopyPasteOnTopOfStock.7z" -BatoceraRootDrive "E:\" -BatoceraROMDrive "R:\" -ROMPath "C:\Users\lowlydba\MyRomCollection"

	Update Batocera from local files when the primary "Misc" partition is on the E:\ drive and the ROM partition is the "R:\" drive.
	Both partitions should exist on the primary SD card. Also copies personal ROMs to the primary SD card's ROM partition.


.EXAMPLE
	Update-RgBatocera -LocalFile "C:\Users\lowlydba\Downloads\RG35XX-CopyPasteOnTopOfStock.7z" -BatoceraRootDrive "E:\" -BatoceraROMDrive "R:\" -ROMPath "C:\Users\lowlydba\MyRomCollection" -2ndBatoceraROMDrive

	Update Batocera from local files when the primary "Misc" partition is on the E:\ drive and the ROM partition is the "R:\" drive.
	Both partitions should exist on the primary SD card. Also copies personal ROMs to a secondary SD card's ROM partition.


#>
function Update-RgBatocera {

	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $true, ParameterSetName = "local")]
		[string]$LocalFile,
		[Parameter (Mandatory = $true, ParameterSetName = "remote")]
		[string]$BatoceraURL,
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\RG35XXPs"),
		[ValidateScript({ Test-Path -Path $_ })]
		[Parameter (Mandatory = $true)]
		[string]$BatoceraRootDrive,
		[Parameter (Mandatory = $false)]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$BatoceraROMDrive,
		[Parameter (Mandatory = $false)]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$2ndBatoceraROMDrive,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $true,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath
	)
	process {
		$BatoceraPath = Join-Path -Path $TempPath -ChildPath "\BatoceraUpdate"
		$BatoceraUpdateZipName = "RG35XX-CopyPasteOnTopOfStock.7z"

		## Step 1 - Cleanup/Create temp path for Batocera extraction
		New-RgTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -BatoceraPath $BatoceraPath

		## Step 2 - Download latest version
		try {
			if ($LocalFile -eq "") {
				$BatoceraUpdateUri = $BatoceraURL
				$BatoceraZipPath = Invoke-RgDownload -TempPath $TempPath -BatoceraZip $BatoceraUpdateZipName -BatoceraUri $BatoceraUpdateUri
			}
			else {
				$BatoceraZipPath = $LocalFile
			}
		}
		catch {
			Write-Error -Message "Error downloading Batocera: $($_.Exception.Message)"
		}

		## Step 3 - Extract the archive
		Expand-Archive -Path $BatoceraZipPath -DestinationPath $BatoceraPath

		## Step 4 - Update Batocera
		# Only files on the primary SD card need to be modified, the misc partition and rom partition
		try {
			# Misc / system files
			$miscDir = Join-Path -Path $BatoceraPath -ChildPath "misc"
			$miscDir = Join-Path -Path $miscDir -ChildPath "*"
			Write-Verbose -Message "Copying misc files from '$miscDir' to '$BatoceraRootDrive'"
			Copy-Item -Path $miscDir -Destination $BatoceraRootDrive -Recurse -Force -Confirm:$false

			# ROMS - Copy the top level Roms dir that contains BIOS, CFW, and Roms data to the ROM Partition
			$romDir = Join-Path -Path $BatoceraPath -ChildPath "roms"
			$romDir = Join-Path -Path $romDir -ChildPath "*"
			Write-Verbose -Message "Copying ROM, CFW, and BIOS files from '$romDir' to '$BatoceraROMDrive'"
			Copy-Item -Path $romDir -Destination $BatoceraROMDrive -Recurse -Force -Confirm:$false
		}
		catch {
			Write-Error -Message "Error updating Batocera: $($_.Exception.Message)"
		}

		## Step 5 - Copy personal files
		if ($2ndBatoceraROMDrive -eq "") {
			# If no 2nd SD card, use the first card's ROM drive
			$2ndBatoceraROMDrive = $BatoceraROMDrive
		}
		Copy-RgPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination $2ndBatoceraROMDrive

		# Tada!
		Invoke-RgThanks -Action "updated"
	}
}
