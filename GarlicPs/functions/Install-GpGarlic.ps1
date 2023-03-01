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

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER TargetDevice
    The target device of the SD card.
	Must be the DeviceID returned from 'GET-WMIOBJECT -Query "SELECT * FROM Win32_DiskDrive"'

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Path to personal BIOS files that will be copied after installation.

.PARAMETER ROMPath
    Path to personal ROM files that will be copied after installation.

.EXAMPLE
    Install-GpGarlic -GarlicUrl "https://www.patreon.com/file?h=76561333&i=13249827" -TargetDevice "\\.\PhysicalDevice2" -ClearTempPath $true
#>
function Install-GpGarlic {

	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $true, ParameterSetName = "local")]
		[string]$LocalFile,
		[Parameter (Mandatory = $true, ParameterSetName = "remote")]
		[string]$GarlicURL,
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[Parameter (Mandatory = $true)]
		[string]$TargetDevice,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $true,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath
	)
	process {
		# Hacky check for balena cli
		try {
			Invoke-Expression "balena" | Out-Null
		}
		catch {
			Write-Error -Message "balena cli not installed and/or not in PATH environment."
		}

		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOS"
		$garlicInstallZip = "RG35XX-MicroSDCardImage.7z"

		# Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		## Step 1 - Download & extract GarlicOS
		# Download latest version
		try {
			if ($LocalFile -eq "") {
				$garlicInstallUri = $GarlicURL
				$garlicZipPath = Invoke-GpDownload -TempPath $TempPath -GarlicZip $garlicInstallZip -GarlicUri $garlicInstallUri
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
		Invoke-Expression -Command 'balena local flash "$garlicImg" -y --drive $TargetDevice'

		## Step 3 - Eject and re-insert SD
		Write-Output "Safely eject the SD card, then re-insert it."
		Read-Host "Press enter when done."

		## Step 4 - Expand ROM partition
		#TODO

		## Step 5 - Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination #$TargetPath

		## Tada!
		Invoke-GpThanks
	}
}
