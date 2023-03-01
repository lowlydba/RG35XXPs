function Install-GpGarlic {
<#
.SYNOPSIS
    Install GarlicOS!

.DESCRIPTION
    Automate installation of GarlicOS.

.PARAMETER LocalFile
    The full path of a copy of RG35XX-MicroSDCardImage.7z locally available. If not supplied, it is downloaded.

.PARAMETER TempPath
    Optional. Where files will be downloaded and decompressed to during the installation.

.PARAMETER TargetDrive
    The target drive for the SD card. Must be the name returned from diskpart, i.e. '\\.\PhysicalDrive2'

.PARAMETER ClearTempPath
    Optional. Whether to recursively empty the TempPath before using it. Recommended.

.PARAMETER BIOSPath
    Optional. Path to personal BIOS files that will be copied after installation.

.PARAMETER ROMPath
    Optional. Path to personal ROM files that will be copied after installation.

.EXAMPLE
    TBD
#>
	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $false)]
		[string]$LocalFile,
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[Parameter (Mandatory = $true)]
		[string]$TargetDrive,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $false,
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
		$garlicUpdateZip = "RG35XX-MicroSDCardImage.7z"
		$garlicUpdateUri = "https://www.patreon.com/file?h=76561333&i=13249827" # This changes with each update, should take in as param or scrape 

        # Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

        ## Step 1 - Download & extract GarlicOS
        # Download latest version
		try {
			if ($LocalFile -eq "") {
				$garlicZipPath = Invoke-GpDownload -TempPath $TempPath -GarlicZip $garlicZip -GarlicUri $garlicUri
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
        Invoke-Expression -Command 'balena local flash "$garlicImg" -y --drive $TargetDrive' 

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