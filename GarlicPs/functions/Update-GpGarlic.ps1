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

.PARAMETER GarlicUpdateZipName
	When using GarlicURL, the name to save the downloaded file as in the TempPath.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER RootDrive
    The root drive that contains the system files, nothing else. Ex: 'E:\'

.PARAMETER ROMDrive
	The drive that contains ROMs. Ex. 'G:\'

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after installation.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after installation.

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
		[Parameter (Mandatory = $false, ParameterSetName = "remote")]
		[string]$GarlicUpdateZipName = "RG35XX-CopyPasteOnTopOfStock.7z",
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[Parameter (Mandatory = $true)]
		[string]$GarlicRootDrive,
		[Parameter (Mandatory = $true)]
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
			$miscDir = "misc\*"
			Copy-Item -Path (Join-Path -Path $GarlicRootDrive -ChildPath $miscDir) -Destination $GarlicRootDrive -Recurse -Force -Confirm:$false

			# CFW
			$cfwDir = "roms\CFW\*"
			Copy-Item -Path (Join-Path -Path $garlicPath -ChildPath $cfwDir) -Destination $GarlicROMDrive -Recurse -Force -Confirm:$false

			# ROMS
			$romDir = "roms\Roms\*"
			Copy-Item -Path (Join-Path -Path $garlicPath -ChildPath $romDir) -Destination $GarlicROMDrive -Recurse -Force -Confirm:$false
		}
		catch {
			Write-Error -Message "Error installing GarlicOS: $($_.Exception.Message)"
		}

		## Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination $GarlicRootDrive

		# Tada!
		Invoke-GpThanks
	}
}
