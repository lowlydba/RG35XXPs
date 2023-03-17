<#
.SYNOPSIS
    Install Batocera Linux.

.DESCRIPTION
    Automate the installation of Batocera on an SD card for the RG35XX.

.PARAMETER LocalFile
    The full path of a copy of Batocera locally available. If not supplied, it is downloaded from Github.

.PARAMETER Version
    The version tag to download and install. See https://github.com/rg35xx-cfw/rg35xx-cfw.github.io/tags for valid version tags.

.PARAMETER TempPath
    Where files will be downloaded and decompressed to during the installation.

.PARAMETER TargetDeviceNumber
    The index of the target boot SD card device. Can be found using diskpart.exe or equivalent.

.PARAMETER ClearTempPath
    Whether to recursively empty the TempPath before using it. Recommended.

.EXAMPLE
    Install-RgBatocera -Version "rg35xx_batocera_lite_alpha_v0.2" -TargetDeviceNumber 2 -ClearTempPath $true

	Fetches Batocera based on a specific version installs it on an SD card identified as Disk #2.
	Clears any files that may exist in the temp path.


.EXAMPLE
	Install-RgBatocera -LocalFile "C:\Users\lowlydba\Downloads\batocera_lite_rg35xx_20230316.img.zip" -TargetDeviceNumber 3 -ClearTempPath $true -TempPath "C:\temp"

	Uses a local Batocera file and installs it on an SD card identified as Disk #3.
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
		[bool]$ClearTempPath = $true
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

		# Maybe future code to format remaining space on SD card + copy ROMs over
		# but this is tricky with Windows volume format limitations
		# https://wiki.batocera.org/batocera.linux_architecture#using_an_alternative_filesystem_for_userdata
		# With multi-SD card setups common, that is a one-time setup out of scope for this
		# and you can just use this to flash the OS as many times as desired

		# Tada!
		Invoke-RgThanks -Action "installed"
	}
}
