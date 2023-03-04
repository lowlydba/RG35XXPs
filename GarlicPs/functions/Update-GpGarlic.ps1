<#
.SYNOPSIS
    🧄 Update GarlicOS!

.DESCRIPTION
    Automate updates of GarlicOS.

.PARAMETER LocalFile
    The full path of a copy of RG35XX-CopyPasteOnTopOfStock.7z locally available. If not supplied, it is downloaded.

.PARAMETER GarlicURL
    The URL of the GarlicOS update file, ex: https://www.patreon.com/file?h=76561333&i=13249827
	Note: With each new version of GarlicOS, old URLs become invalid. Ensure a valid one is being passed.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER GarlicRootDrive
    The root drive that contains the GarlicOS system files, nothing else. Ex: 'E:\'

.PARAMETER GarlicROMDrive
	The drive that contains ROMs. Ex. 'G:\'

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after upgrade process.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after upgrade process.

.EXAMPLE
    TBD

.EXAMPLE
	TBD
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
		[bool]$ClearTempPath = $false,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath
	)
	process {
		# Path to extract Garlic to
		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOSUpdate"
		$GarlicUpdateZipName = "RG35XX-CopyPasteOnTopOfStock.7z"

		# Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		# Download latest version
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

		# Extract the archive
		Expand-Gp7Zip -ArchivePath $garlicZipPath -TargetPath $garlicPath

		## Update GarlicOS
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

		## Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination $GarlicRootDrive

		# Tada!
		Invoke-GpThanks
	}
}
